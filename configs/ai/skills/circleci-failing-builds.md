---
name: circleci-failing-builds
description: Diagnose and fix failing CircleCI builds. Use when the user asks to investigate CI failures, fix a broken build, or debug CircleCI pipeline issues.
---

# CircleCI Failing Build Resolution

## Quick Start

When helping with a failing CircleCI build, follow this workflow:

1. **Gather context**
   - Determine the repository and org from `git remote get-url origin`.
   - If the user doesn't specify a branch, auto-detect with `git branch --show-current`.
   - **If the user provides a CircleCI URL**, parse it immediately to extract the job number and skip to step 2b.

2. **Fetch failure logs**

   **2a. If no URL provided — discover failed jobs:**
   - Use the v1.1 API to list recent builds and find failures (see API section below).

   **2b. If URL or job number is known — fetch logs directly:**
   - Extract the job number from the URL. CircleCI URLs follow this pattern:
     `https://app.circleci.com/pipelines/github/ORG/REPO/PIPELINE_NUM/workflows/WORKFLOW_ID/jobs/JOB_NUMBER`
   - The job number is the last path segment (e.g., `333` from the URL above).
   - Fetch step-level detail via the **v1.1 API** (see API section below).

3. **Analyze the failure**
   - Read the failed step logs carefully. Common failure categories:
     - **Test failures**: Look for assertion errors, stack traces, and the specific test file/line.
     - **Lint / typecheck errors**: Look for file paths and error codes.
     - **Dependency issues**: Missing packages, version conflicts, lockfile mismatches.
     - **Build errors**: Compilation failures, missing environment variables, Docker issues.
     - **Timeout / infrastructure failures**: Resource limits, flaky network calls.
   - Identify the **root cause** — not just the symptom. A test failure might be caused by a missing migration, a dependency change, or a race condition.

4. **Fix the issue locally**
   - Locate the relevant file(s) in the local workspace.
   - Apply the minimal fix that addresses the root cause.
   - Follow existing project conventions and patterns.
   - If the fix requires configuration changes (e.g., `.circleci/config.yml`), be careful to preserve existing job structure and only change what's necessary.

5. **Validate locally before pushing**
   - Run the same command that failed in CI locally if possible (e.g., `bundle exec rspec`, `npm test`, `make lint`).
   - If the CI step uses a custom script or Docker image, try to approximate the check locally.
   - Only push once the local validation passes.

## Failure Classification

- **Test failure**: Read the test, understand what it expects, fix the code or update the test if the behavior change is intentional.
- **Lint / format**: Run the linter locally, apply auto-fixes where available, manually fix what remains.
- **Dependency**: Check lockfiles, ensure versions are pinned correctly, run `bundle install` / `npm install` / equivalent.
- **Config error**: Validate `.circleci/config.yml` syntax with `circleci config validate` if the CLI is installed.
- **Timeout / flaky**: Identify if the failure is non-deterministic. If flaky, note it to the user rather than making speculative fixes.

## CircleCI API — Token & Authentication

**IMPORTANT:** Read the token from `~/.circleci/cli.yml` (the `token:` field). Do NOT rely on `$CIRCLE_TOKEN` env var — it is usually not set.

```bash
TOKEN=$(grep 'token:' ~/.circleci/cli.yml | awk '{print $2}')
```

## CircleCI API — Use v1.1 (NOT v2)

**IMPORTANT:** The v2 API often returns 404 "Project not found" with personal API tokens (`CCIPAT_...`). Always use the **v1.1 API** which works reliably. Note that v1.1 uses `github` (not `gh`) as the VCS prefix.

```bash
# Get step-level detail for a specific job (primary method)
curl -sf -H "Circle-Token: $TOKEN" \
  "https://circleci.com/api/v1.1/project/github/ORG/REPO/JOB_NUMBER"

# List recent builds for a branch
curl -sf -H "Circle-Token: $TOKEN" \
  "https://circleci.com/api/v1.1/project/github/ORG/REPO/tree/BRANCH?limit=10&filter=failed"
```

### Extracting failed steps and logs

```bash
# Get failed steps from a job
curl -sf -H "Circle-Token: $TOKEN" \
  "https://circleci.com/api/v1.1/project/github/ORG/REPO/JOB_NUMBER" \
  | jq '[.steps[] | select(.actions[0].status == "failed") | {name: .name, actions: [.actions[] | {name: .name, status: .status, output_url: .output_url}]}]'

# Fetch log output from a failed step's output_url
curl -s "OUTPUT_URL" | jq -r '.[].message'
```

## Safety

- Never modify `.circleci/config.yml` in ways that skip tests, disable checks, or weaken the pipeline.
- If a fix involves changing CI configuration, explain what changed and why.
- If the failure looks like a flaky test or infrastructure issue (not a code problem), tell the user rather than making unnecessary code changes.
