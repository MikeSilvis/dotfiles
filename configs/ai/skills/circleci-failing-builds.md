---
name: circleci-failing-builds
description: Diagnose and fix failing CircleCI builds using the `cci-logs` shell helper. Use when the user asks to investigate CI failures, fix a broken build, or debug CircleCI pipeline issues.
---

# CircleCI Failing Build Resolution

## Quick Start

When helping with a failing CircleCI build, follow this workflow:

1. **Fetch failure logs with `cci-logs`**
   - Run the helper with no arguments: `cci-logs`
   - The script auto-detects the org, repo, and VCS type from the git remote, and defaults to the current git branch. You can optionally pass a branch name (`cci-logs [branch]`) but it is not required.
   - The script requires:
     - A CircleCI token — either `CIRCLE_TOKEN` env var or configured via `circleci setup` (stored in `~/.circleci/cli.yml`).
     - `jq` installed (`brew install jq`).
   - The script fetches the latest pipeline, finds failed jobs, and displays step-level logs for failed steps only.
   - **Note**: The script is interactive (prompts to select a failed job). When running non-interactively, pipe input or use it to understand which jobs failed, then fetch logs via the CircleCI API directly.

2. **Analyze the failure**
   - Read the failed step logs carefully. Common failure categories:
     - **Test failures**: Look for assertion errors, stack traces, and the specific test file/line.
     - **Lint / typecheck errors**: Look for file paths and error codes.
     - **Dependency issues**: Missing packages, version conflicts, lockfile mismatches.
     - **Build errors**: Compilation failures, missing environment variables, Docker issues.
     - **Timeout / infrastructure failures**: Resource limits, flaky network calls.
   - Identify the **root cause** — not just the symptom. A test failure might be caused by a missing migration, a dependency change, or a race condition.

3. **Fix the issue locally**
   - Locate the relevant file(s) in the local workspace.
   - Apply the minimal fix that addresses the root cause.
   - Follow existing project conventions and patterns.
   - If the fix requires configuration changes (e.g., `.circleci/config.yml`), be careful to preserve existing job structure and only change what's necessary.

4. **Validate locally before pushing**
   - Run the same command that failed in CI locally if possible (e.g., `bundle exec rspec`, `npm test`, `make lint`).
   - If the CI step uses a custom script or Docker image, try to approximate the check locally.
   - Only push once the local validation passes.

## Failure Classification

- **Test failure**: Read the test, understand what it expects, fix the code or update the test if the behavior change is intentional.
- **Lint / format**: Run the linter locally, apply auto-fixes where available, manually fix what remains.
- **Dependency**: Check lockfiles, ensure versions are pinned correctly, run `bundle install` / `npm install` / equivalent.
- **Config error**: Validate `.circleci/config.yml` syntax with `circleci config validate` if the CLI is installed.
- **Timeout / flaky**: Identify if the failure is non-deterministic. If flaky, note it to the user rather than making speculative fixes.

## CircleCI API Direct Access

When the interactive `cci-logs` script isn't suitable (e.g., running non-interactively), you can use the CircleCI API directly:

```bash
# List recent pipelines for a project
curl -sf -H "Circle-Token: $CIRCLE_TOKEN" \
  "https://circleci.com/api/v2/project/gh/ORG/REPO/pipeline?branch=BRANCH"

# Get workflows for a pipeline
curl -sf -H "Circle-Token: $CIRCLE_TOKEN" \
  "https://circleci.com/api/v2/pipeline/PIPELINE_ID/workflow"

# Get jobs for a workflow
curl -sf -H "Circle-Token: $CIRCLE_TOKEN" \
  "https://circleci.com/api/v2/workflow/WORKFLOW_ID/job"

# Get step-level detail (v1.1 API)
curl -sf -H "Circle-Token: $CIRCLE_TOKEN" \
  "https://circleci.com/api/v1.1/project/gh/ORG/REPO/JOB_NUMBER"
```

Use `jq` to parse responses and extract failed steps and their output URLs.

## Safety

- Never modify `.circleci/config.yml` in ways that skip tests, disable checks, or weaken the pipeline.
- If a fix involves changing CI configuration, explain what changed and why.
- If the failure looks like a flaky test or infrastructure issue (not a code problem), tell the user rather than making unnecessary code changes.
