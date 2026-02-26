#!/bin/bash
# Clean up iOS simulators, keeping only one iPhone and one iPad on the latest iOS version.

set -euo pipefail

# Get all iOS runtimes sorted descending, pick the latest
latest_runtime=$(xcrun simctl list runtimes --json \
  | jq -r '[.runtimes[] | select(.name | startswith("iOS")) | select(.isAvailable == true)] | sort_by(.version) | last | .identifier')

if [[ -z "$latest_runtime" || "$latest_runtime" == "null" ]]; then
  echo "No available iOS runtimes found." >&2
  exit 1
fi

echo "Latest iOS runtime: $latest_runtime"

# Find the first available iPhone and iPad for that runtime
keep_iphone=$(xcrun simctl list devices --json \
  | jq -r --arg rt "$latest_runtime" '
      .devices[$rt] // [] |
      map(select(.name | test("iPhone"; "i"))) |
      first | .udid // empty')

keep_ipad=$(xcrun simctl list devices --json \
  | jq -r --arg rt "$latest_runtime" '
      .devices[$rt] // [] |
      map(select(.name | test("iPad"; "i"))) |
      first | .udid // empty')

if [[ -z "$keep_iphone" ]]; then
  echo "Warning: No iPhone simulator found for $latest_runtime"
fi
if [[ -z "$keep_ipad" ]]; then
  echo "Warning: No iPad simulator found for $latest_runtime"
fi

echo "Keeping iPhone: ${keep_iphone:-(none)}"
echo "Keeping iPad:   ${keep_ipad:-(none)}"

# Build a set of UDIDs to keep
declare -A keep_set
[[ -n "$keep_iphone" ]] && keep_set["$keep_iphone"]=1
[[ -n "$keep_ipad" ]]   && keep_set["$keep_ipad"]=1

# Collect all simulator UDIDs
all_udids=$(xcrun simctl list devices --json \
  | jq -r '.devices | to_entries[] | .value[] | .udid')

deleted=0
skipped=0

while IFS= read -r udid; do
  if [[ -n "${keep_set[$udid]+_}" ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  echo "Deleting $udid..."
  xcrun simctl delete "$udid"
  deleted=$((deleted + 1))
done <<< "$all_udids"

echo ""
echo "Done. Deleted $deleted simulator(s), kept $skipped."
