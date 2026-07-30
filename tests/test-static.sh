#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

for command in actionlint shellcheck yamllint; do
  command -v "${command}" >/dev/null || {
    echo "SKIP: ${command} is not installed" >&2
    exit 77
  }
done

actionlint
actionlint templates/cicd/container.yaml
shellcheck --rcfile templates/pre-commit/.shellcheckrc \
  bin/pre-commit tests/fixtures/curl tests/fixtures/pre-commit \
  tests/test-pre-commit.sh tests/test-static.sh
yamllint -c templates/pre-commit/.yamllint.yaml \
  .github/workflows templates/cicd templates/pre-commit/.yamllint.yaml

if rg -n '/usr/(local/)?bin/podman' .github/workflows templates/cicd; then
  echo 'ERROR: hard-coded Podman path found' >&2
  exit 1
fi

for workflow in ci-podman-build.yaml ci-podman-publish.yaml \
  ci-container-test.yaml cd-tag-latest.yaml; do
  rg -q 'command -v podman' ".github/workflows/${workflow}"
done

for workflow in ci-podman-build.yaml ci-podman-publish.yaml \
  ci-container-test.yaml ci-registry-clean.yaml cd-tag-latest.yaml; do
  rg -q 'Missing GitHub Environment secrets|REGISTRY_USERNAME and REGISTRY_TOKEN are required' \
    ".github/workflows/${workflow}"
done

for removed in .yamllint archive .github/workflows/security-and-lint.yml; do
  [[ ! -e "${removed}" ]] || { echo "ERROR: obsolete path remains: ${removed}" >&2; exit 1; }
done

echo 'static workflow tests: PASS'
