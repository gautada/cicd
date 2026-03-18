#!/usr/bin/env bash
# =============================================================================
# bin/pre-commit
# Syncs pre-commit config from gautada/cicd and runs pre-commit --all-files.
#
# Usage:
#   curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit | bash
#   curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit | bash -s -- --pull-only
#
# Options:
#   --pull-only    Pull config files from gautada/cicd only; skip install and run.
#
# Requirements:
#   - Run from the root of a git checkout
#   - pre-commit must be installed (pipx install --global pre-commit)
#   - curl must be available
# =============================================================================
set -euo pipefail

CICD_RAW="https://raw.githubusercontent.com/gautada/cicd/main/templates/pre-commit"
PULL_ONLY=false

# ---- Parse arguments --------------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    --pull-only) PULL_ONLY=true ;;
    *) echo "ERROR: Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# Config files to pull from gautada/cicd:/templates/pre-commit/
CONFIG_FILES=(
  ".flake8"
  ".hadolint.yaml"
  ".htmlhintrc"
  ".jscpd.json"
  ".markdownlint.yaml"
  ".pre-commit-config.yaml"
  ".shellcheckrc"
  ".sqlfluff"
  ".yamllint.yaml"
)

# ---- Preflight checks -------------------------------------------------------

# Verify git repo
if ! git rev-parse --show-toplevel &>/dev/null; then
  echo "ERROR: Not inside a git repository." >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
if [[ "$PWD" != "$REPO_ROOT" ]]; then
  echo "ERROR: Run from the root of the git checkout." >&2
  echo "       Expected: $REPO_ROOT" >&2
  exit 1
fi

# Verify curl is available
if ! command -v curl &>/dev/null; then
  echo "ERROR: curl is required but not found." >&2
  exit 1
fi

# ---- Enforce canonical .gitignore -------------------------------------------

echo "==> Syncing canonical .gitignore template..."
curl -sSfL \
https://raw.githubusercontent.com/gautada/cicd/refs/heads/main/templates/gitignore/.gitignore \
-o .gitignore
echo ""

# ---- Sync config files from gautada/cicd ------------------------------------

echo "==> Syncing pre-commit config from gautada/cicd/templates/pre-commit..."
for f in "${CONFIG_FILES[@]}"; do
  echo "    ↓ $f"
  if ! curl -sSfL "$CICD_RAW/$f" -o "$f"; then
    echo "ERROR: Failed to download $f from $CICD_RAW" >&2
    exit 1
  fi
done
echo ""

# ---- Exit early if --pull-only ----------------------------------------------

if [[ "$PULL_ONLY" == true ]]; then
  echo "==> Pull complete. Skipping install and run (--pull-only)."
  exit 0
fi

# ---- Install/update hooks ---------------------------------------------------

# Verify pre-commit is installed
if ! command -v pre-commit &>/dev/null; then
  echo "ERROR: pre-commit is not installed." >&2
  echo "       Install via: pipx install --global pre-commit" >&2
  exit 1
fi

echo "==> Installing pre-commit hooks..."
pre-commit install
echo ""

# ---- Run linters ------------------------------------------------------------

echo "==> Running pre-commit on all files..."
pre-commit run --all-files
