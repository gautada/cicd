#!/usr/bin/env bash
# shellcheck shell=bash
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
actionlint .github/workflows/container.yaml
shellcheck --rcfile templates/pre-commit/.shellcheckrc \
  bin/pre-commit tests/fixtures/curl tests/fixtures/pre-commit \
  tests/test-pre-commit.sh tests/test-static.sh
yamllint -c templates/pre-commit/.yamllint.yaml \
  .github/workflows templates/pre-commit/.yamllint.yaml

if rg -n '/usr/(local/)?bin/podman' .github/workflows; then
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

if rg -n 'actions/checkout@v[1-5]|anchore/scan-action@v[1-6]' .github/workflows; then
  echo 'ERROR: obsolete GitHub Action major found' >&2
  exit 1
fi

rg -q 'actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803  # v6' \
  .github/workflows/ci-linter.yaml
rg -q 'anchore/scan-action@e1165082ffb1fe366ebaf02d8526e7c4989ea9d2  # v7' \
  .github/workflows/ci-deep-scan.yaml

for command in container-test container-version; do
  rg -q "/usr/bin/${command}" Containerfile
done
rg -Fq 'uses: gautada/cicd/.github/workflows/cicd-container.yaml@dev' \
  .github/workflows/container.yaml
rg -Fq 'cicd_ref: dev' \
  .github/workflows/container.yaml
rg -Fq 'uses: ./.github/workflows/ci-podman-build.yaml' \
  .github/workflows/cicd-container.yaml
[[ ! -e templates/cicd/container.yaml ]]

echo 'static workflow tests: PASS'
