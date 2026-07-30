#!/usr/bin/env bash
# shellcheck shell=bash
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
  "${source_root}/bin/pre-commit" --pull-only
)
[[ ! -e "${repo}/.github/workflows/container.yaml" ]]

(
  cd "${repo}"
  "${source_root}/bin/pre-commit" --workflow container
  "${source_root}/bin/pre-commit" --workflow container
)

[[ "$(cat "${repo}/.flake8")" == project-owned ]]
rg -Fq 'cicd-container.yaml@main' "${repo}/.github/workflows/container.yaml"
rg -Fq 'cicd_ref: main' "${repo}/.github/workflows/container.yaml"
if rg -Fq '@dev' "${repo}/.github/workflows/container.yaml"; then
  echo 'ERROR: consumer workflow retained the development reference' >&2
  exit 1
fi
[[ ! -e "${repo}/.gitignore" ]]
[[ -e "${repo}/.pre-commit-config.yaml" ]]
[[ "$(git -C "${repo}" status --short --untracked-files=all)" == \
  '?? .github/workflows/container.yaml' ]]
[[ "$(wc -l < "${PRE_COMMIT_TEST_LOG}" | tr -d ' ')" == 4 ]]

(
  cd "${repo}"
  "${source_root}/bin/pre-commit" --pull-only --workflow container \
    --sync-project --ref review-test
)
rg -Fq 'cicd-container.yaml@review-test' "${repo}/.github/workflows/container.yaml"
rg -Fq 'cicd_ref: review-test' "${repo}/.github/workflows/container.yaml"
[[ -e "${repo}/.gitignore" ]]

echo 'pre-commit installer test: PASS'
