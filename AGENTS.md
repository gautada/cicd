# AI agent instructions

`README.md` is the canonical description of this CI/CD system. Follow these
rules in this repository and in consumers that reference
`gautada/cicd/.github/workflows/`.

## Before changing a consumer

1. Read `.github/workflows/container.yaml` and record the pinned CI/CD ref.
2. Work on a feature branch targeting `dev`; do not work directly on `main`.
3. Inspect `git status` and preserve all unrelated changes.
4. Install and run checks from the repository root:

   ```bash
   curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit | bash
   ```

   Prefer downloading and reviewing the script first for high-trust work.
5. Run relevant container tests locally when Podman is available.

The lint configuration files are generated and gitignored. Do not commit them.
Do not run `--sync-project` unless the task explicitly authorizes replacing
the consumer workflow and `.gitignore`.

## Required lifecycle

- PRs to `dev` or `main` must lint, scan, and build without registry secrets.
- A push to `dev` publishes and tests `:dev`, then opens or updates the
  promotion PR.
- A human reviews and merges `dev` into `main`.
- The `main` workflow tests `:candidate` before publishing the immutable
  version tag and `:latest`.

Never bypass, disable, or weaken a failed check merely to obtain a green run.
Diagnose the failure and make the smallest justified correction.

## Secret and approval boundaries

Never print, read back, copy, invent, commit, or place secrets in command-line
arguments. Required Environment secret names are `REGISTRY_USERNAME` and
`REGISTRY_TOKEN`. Treat fork PR code as untrusted and never expose registry or
production Environment secrets to it.

Stop and request explicit human approval before:

- pushing or force-pushing;
- merging or approving a PR;
- publishing, deleting, or retagging registry images outside an authorized
  workflow run;
- changing GitHub secrets, Environments, permissions, rulesets, or branch
  protections;
- enabling non-dry-run registry cleanup;
- changing a consumer from a pinned workflow revision to a moving branch.

## Failure diagnosis

- Read the earliest failed preflight step first.
- For Podman failures, use the logged discovered path and version; never add a
  hard-coded `/usr/bin/podman` path.
- For missing images, compare the commit SHA and architecture in the build and
  publish tag names.
- For container-test failures, inspect captured logs and run
  `/usr/bin/container-test` in the same image locally.
- For Semgrep or Grype, inspect job output and uploaded SARIF. Fork PR SARIF
  upload may be intentionally skipped even though scanning still runs.
- For release failures, validate the exact output of
  `/usr/bin/container-version`.

Before committing, confirm that only intentional source, workflow, and
documentation files are staged and that no lint downloads, `.env`, credentials,
SBOM output, SARIF, or container archives are present.
