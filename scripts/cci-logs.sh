#!/usr/bin/env bash
# cci-logs.sh — View logs for failing CircleCI builds
# Usage: cci-logs.sh <vcs-type> <org> <repo> [branch]
# Example: cci-logs.sh gh myorg myrepo main
#
# Requires:
#   - CIRCLE_TOKEN env var (https://app.circleci.com/settings/user/tokens)
#   - jq (brew install jq / apt install jq)

set -euo pipefail

# ── Helpers ─────────────────────────────────────────────────────────────────

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

die()  { echo -e "${RED}ERROR: $*${RESET}" >&2; exit 1; }
info() { echo -e "${CYAN}▶ $*${RESET}"; }
sep()  { echo -e "${BOLD}────────────────────────────────────────────${RESET}"; }

# ── Validate inputs ──────────────────────────────────────────────────────────

# Try to read token from CircleCI CLI config if not set in environment
if [[ -z "${CIRCLE_TOKEN:-}" ]]; then
  CLI_CONFIG="${HOME}/.circleci/cli.yml"
  if [[ -f "$CLI_CONFIG" ]]; then
    CIRCLE_TOKEN=$(awk '/^token:/ {print $2}' "$CLI_CONFIG")
    [[ -n "$CIRCLE_TOKEN" ]] && info "Using token from ~/.circleci/cli.yml"
  fi
fi

[[ -z "${CIRCLE_TOKEN:-}" ]] && die "No CircleCI token found.\nRun 'circleci setup' or set CIRCLE_TOKEN in your environment.\nGet a token at: https://app.circleci.com/settings/user/tokens"
command -v jq &>/dev/null || die "jq is required (brew install jq)"

VCS="${1:-}"
ORG="${2:-}"
REPO="${3:-}"
BRANCH="${4:-}"

if [[ -z "$VCS" || -z "$ORG" || -z "$REPO" ]]; then
  echo "Usage: $0 <vcs-type> <org> <repo> [branch]"
  echo "  vcs-type: gh (GitHub) or bb (Bitbucket)"
  echo "  branch:   optional, defaults to current git branch"
  exit 1
fi

# Auto-detect current git branch if not specified
if [[ -z "$BRANCH" ]]; then
  if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || true)
    [[ -n "$BRANCH" ]] && info "Auto-detected branch: ${BOLD}${BRANCH}${RESET}"
  fi
fi

[[ -z "$BRANCH" ]] && info "No branch detected (detached HEAD or not in a git repo), fetching all branches."

PROJECT_SLUG="${VCS}/${ORG}/${REPO}"
BASE_V2="https://circleci.com/api/v2"
BASE_V1="https://circleci.com/api/v1.1"
AUTH_HEADER="Circle-Token: ${CIRCLE_TOKEN}"

api_v2() { curl -sf -H "$AUTH_HEADER" "$BASE_V2/$1"; }
api_v1() { curl -sf -H "$AUTH_HEADER" "$BASE_V1/$1"; }

# ── Step 1: Get recent pipelines ─────────────────────────────────────────────

info "Fetching recent pipelines for ${PROJECT_SLUG}..."

PIPELINE_URL="project/${PROJECT_SLUG}/pipeline"
[[ -n "$BRANCH" ]] && PIPELINE_URL+="?branch=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$BRANCH")"

PIPELINES=$(api_v2 "$PIPELINE_URL") || die "Failed to fetch pipelines. Check your token and project slug."

PIPELINE_IDS=$(echo "$PIPELINES" | jq -r '.items[:10] | .[].id')
[[ -z "$PIPELINE_IDS" ]] && die "No pipelines found."

# ── Step 2: Find failed workflows ────────────────────────────────────────────

info "Scanning workflows for failures..."

FAILED_JOBS=()

while IFS= read -r PIPELINE_ID; do
  WORKFLOWS=$(api_v2 "pipeline/${PIPELINE_ID}/workflow") || continue

  while IFS= read -r WORKFLOW_ID; do
    JOBS=$(api_v2 "workflow/${WORKFLOW_ID}/job") || continue

    while IFS=\t' read -r JOB_NAME JOB_NUM JOB_STATUS; do
      [[ "$JOB_STATUS" == "failed" ]] && FAILED_JOBS+=("${JOB_NUM}|${JOB_NAME}|${WORKFLOW_ID}")
    done < <(echo "$JOBS" | jq -r '.items[] | [.name, (.job_number // "null"), .status] | @tsv')

  done < <(echo "$WORKFLOWS" | jq -r '.items[].id')
done <<< "$PIPELINE_IDS"

if [[ ${#FAILED_JOBS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No failed jobs found in the last 10 pipelines.${RESET}"
  exit 0
fi

# ── Step 3: Display failed jobs and pick one ─────────────────────────────────

sep
echo -e "${RED}${BOLD}Failed Jobs:${RESET}"
sep

declare -A JOB_MAP
for i in "${!FAILED_JOBS[@]}"; do
  IFS='|' read -r JOB_NUM JOB_NAME _ <<< "${FAILED_JOBS[$i]}"
  echo -e "  ${BOLD}[$((i+1))]${RESET} ${JOB_NAME} (job #${JOB_NUM})"
  JOB_MAP[$((i+1))]="$JOB_NUM|$JOB_NAME"
done

sep
echo -n "Select a job to view logs (1-${#FAILED_JOBS[@]}), or 'a' for all: "
read -r CHOICE

# ── Step 4: Fetch and display logs ───────────────────────────────────────────

fetch_logs() {
  local JOB_NUM="$1"
  local JOB_NAME="$2"

  sep
  echo -e "${BOLD}${YELLOW}Logs for: ${JOB_NAME} (job #${JOB_NUM})${RESET}"
  sep

  # v1.1 gives us step-level output_urls
  JOB_DETAIL=$(api_v1 "project/${VCS}/${ORG}/${REPO}/${JOB_NUM}") \
    || { echo -e "${RED}Could not fetch job detail for #${JOB_NUM}${RESET}"; return; }

  STEPS=$(echo "$JOB_DETAIL" | jq -r '.steps[]')
  STEP_COUNT=$(echo "$JOB_DETAIL" | jq '.steps | length')

  for ((s=0; s<STEP_COUNT; s++)); do
    STEP_NAME=$(echo "$JOB_DETAIL" | jq -r ".steps[$s].name")
    ACTION_STATUS=$(echo "$JOB_DETAIL" | jq -r ".steps[$s].actions[0].status")
    OUTPUT_URL=$(echo "$JOB_DETAIL" | jq -r ".steps[$s].actions[0].output_url // empty")

    # Only show failed or errored steps (skip passing ones to reduce noise)
    if [[ "$ACTION_STATUS" == "failed" || "$ACTION_STATUS" == "timedout" || "$ACTION_STATUS" == "infrastructure_fail" ]]; then
      echo ""
      echo -e "${RED}${BOLD}▼ STEP: ${STEP_NAME} [${ACTION_STATUS}]${RESET}"
      echo ""

      if [[ -n "$OUTPUT_URL" ]]; then
        # output_url returns gzipped JSON array of log lines
        curl -sf "$OUTPUT_URL" \
          | gunzip 2>/dev/null \
          | jq -r '.[].message' 2>/dev/null \
          || curl -sf "$OUTPUT_URL" | jq -r '.[].message' 2>/dev/null \
          || echo "(Could not decode log output)"
      else
        echo "(No output URL available for this step)"
      fi
    fi
  done

  sep
  echo -e "${CYAN}Full job in browser: https://app.circleci.com/pipelines/${VCS}/${ORG}/${REPO}?branch=${BRANCH}${RESET}"
}

if [[ "$CHOICE" == "a" ]]; then
  for i in "${!FAILED_JOBS[@]}"; do
    IFS='|' read -r JOB_NUM JOB_NAME _ <<< "${FAILED_JOBS[$i]}"
    fetch_logs "$JOB_NUM" "$JOB_NAME"
  done
elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && [[ -n "${JOB_MAP[$CHOICE]:-}" ]]; then
  IFS='|' read -r JOB_NUM JOB_NAME <<< "${JOB_MAP[$CHOICE]}"
  fetch_logs "$JOB_NUM" "$JOB_NAME"
else
  die "Invalid selection."
fi
