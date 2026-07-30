#!/usr/bin/env bash
set -euo pipefail
unset GIT_CONFIG GIT_CREDENTIALS

source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/cicd-installer-test.XXXXXX")"
trap 'rm -rf "${test_root}"' EXIT

repo="${test_root}/consumer"
mkdir -p "${repo}"
git -C "${repo}" init --quiet
git -C "${repo}" config --local user.email test@example.invalid
git -C "${repo}" config --local user.name 'CI/CD test'
printf 'project-owned\n' > "${repo}/.flake8"
git -C "${repo}" add .flake8
git -C "${repo}" commit --quiet -m fixture

export CICD_SOURCE="${source_root}"
export PRE_COMMIT_TEST_LOG="${test_root}/pre-commit.log"
export PATH="${source_root}/tests/fixtures:${PATH}"

(
  cd "${repo}"
  "${source_root}/bin/pre-commit"
  "${source_root}/bin/pre-commit"
)

[[ "$(cat "${repo}/.flake8")" == project-owned ]]
[[ ! -e "${repo}/.github/workflows/container.yaml" ]]
[[ ! -e "${repo}/.gitignore" ]]
[[ -e "${repo}/.pre-commit-config.yaml" ]]
[[ -z "$(git -C "${repo}" status --short)" ]]
[[ "$(wc -l < "${PRE_COMMIT_TEST_LOG}" | tr -d ' ')" == 4 ]]

echo 'pre-commit installer test: PASS'
