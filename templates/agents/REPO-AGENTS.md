# Agent instructions

This repository builds a container image with the shared **gautada/cicd**
pipeline. This file is installed and refreshed by `gautada/cicd`; treat it as
managed. Put repository-specific guidance in `REPO-AGENTS.local.md` (see the
end of this file), which is never overwritten.

## Confirm the CICD wiring

Before making changes, confirm this repository is wired to the pipeline:

1. `.github/workflows/container.yaml` exists and calls
   `gautada/cicd/.github/workflows/cicd-container.yaml` at a pinned ref.
2. Record that pinned CI/CD ref; do not silently move it to a moving branch.

## Before committing

1. Work on a feature branch targeting `dev`; never work directly on `main`.
2. Inspect `git status` and preserve all unrelated changes.
3. From the repository root, run:

   ```bash
   curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit | bash
   ```

   Prefer downloading and reviewing the script first for high-trust work.
4. Resolve every lint, build, scan, and container-test failure. Never bypass,
   disable, or weaken a failed check merely to obtain a green run.
5. Never commit downloaded lint configuration, credentials, `.env`, SARIF,
   SBOM, or container archives.
6. Never expose registry secrets to pull-request code.

## Fix in this repo vs. file a ticket in gautada/cicd

- **Fix here** anything specific to *this* repository: the `Dockerfile`,
  application/build content, `/usr/bin/container-test`,
  `/usr/bin/container-version`, and this repo's own configuration.
- **File a ticket in [`gautada/cicd`](https://github.com/gautada/cicd/issues)**
  for anything owned by the shared pipeline: the reusable workflows,
  `bin/pre-commit`, lint configuration templates, or this instructions file.
  Do not patch managed files locally to work around a pipeline defect — report
  it so the fix propagates to every consumer.

## Delivering changes

When explicitly authorized to deliver:

1. Commit and push the feature branch.
2. Open a PR targeting `dev`.
3. Wait for GitHub Actions to complete and address failures.
4. Report the successful PR to the user.
5. Do not merge the PR unless explicitly authorized.

After a merge into `dev`, the pipeline publishes and tests `:dev`, then creates
or updates the `dev`→`main` promotion PR. Never merge that promotion PR without
explicit human authorization.

## Repository-specific extension

If `REPO-AGENTS.local.md` exists in this repository, read it and follow it. It
holds guidance specific to this repo that extends (and takes precedence over)
the general rules above. It is owned by this repository and is never overwritten
by the pipeline.
