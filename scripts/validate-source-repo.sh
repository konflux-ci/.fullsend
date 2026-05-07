#!/usr/bin/env bash
# Validate that the source repository is enrolled in fullsend.
#
# This script performs three checks:
# 1. Format check — must be owner/repo with safe characters only
# 2. Owner check — must match the current GitHub organization
# 3. Allowlist check — repo must be enabled in config.yaml
#
# Required environment variables:
#   SOURCE_REPO           — repository in owner/repo format
#   GITHUB_REPOSITORY_OWNER — GitHub org/owner from workflow context
#
# Exit codes:
#   0 — validation passed
#   1 — validation failed
set -euo pipefail

: "${SOURCE_REPO:?SOURCE_REPO is required}"
: "${GITHUB_REPOSITORY_OWNER:?GITHUB_REPOSITORY_OWNER is required}"

# Format check — must be owner/repo, safe characters only
if [[ ! "$SOURCE_REPO" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
  echo "::error::Invalid source_repo format: must be owner/repo"
  exit 1
fi

# Owner check — must match this org
REPO_OWNER="${SOURCE_REPO%%/*}"
if [[ "$REPO_OWNER" != "$GITHUB_REPOSITORY_OWNER" ]]; then
  echo "::error::source_repo owner does not match org"
  exit 1
fi

# Allowlist check — repo must be enabled in config.yaml
REPO_NAME="${SOURCE_REPO#*/}"

# Check if config.yaml exists and yq is available
if [[ ! -f config.yaml ]]; then
  echo "::error::config.yaml not found"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "::error::yq command not found"
  exit 1
fi

ENABLED=$(yq ".repos.\"$REPO_NAME\".enabled" config.yaml)
if [[ "$ENABLED" != "true" ]]; then
  echo "::error::repo is not enabled in config.yaml"
  exit 1
fi

echo "Validation passed for ${SOURCE_REPO}"
