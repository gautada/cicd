# Original-state audit

This audit describes the `ai` branch at commit `88cea50` before hardening.

## Observed lifecycle

The consumer template ran on pushes to `dev` and pull requests to `main`.
Both event types reached registry-authenticated build, publish, cleanup, test,
and release jobs. It did not validate PRs targeting `dev`, distinguish PR
builds from trusted pushes, or create the documented `dev` to `main` promotion
PR. The release job therefore ran on a PR rather than after its merge.

`gautada/debian` used an identical copy of that template on both `main` and
`dev`. It mapped `DOCKERIO_REGISTRY` and `DOCKERIO_TOKEN` into every registry
workflow and referenced the moving `@main` CI/CD branch.

## Principal findings

- Podman was hard-coded as `/usr/bin/podman` in build, test, and release jobs,
  while publish used `podman` from `PATH`. A runner path change broke the
  pipeline.
- Registry secrets were declared required but no actionable preflight named
  missing Environment values before package installation/build work.
- The build job modified the tracked `.args` file in place.
- The publish job unexpectedly created a version tag from a repository file,
  script, Git tag, or commit fallback before the release gate.
- Release assumed exactly amd64 and arm64 and depended on mutable build aliases.
- Container testing slept for a fixed 15 seconds rather than checking bounded
  readiness; it created `.env` in the checkout.
- Cleanup selected every commit build tag for deletion despite describing them
  as unlinked, and it ignored deletion failures. It was called automatically.
- `ci-deep-scan.yaml` accepted but ignored `image_ref`, did not fail on Grype
  findings, used a retired Semgrep action wrapper, and contained a debug step.
- `security-and-lint.yml` duplicated the linter and deep scan with different
  action major versions.
- The linter piped a moving remote script directly to Bash.
- `bin/pre-commit` replaced consumer `.gitignore` and workflow files on every
  ordinary invocation, downloaded `pyproject.toml` twice, and was not
  transactional.
- Root `.yamllint` duplicated the canonical template. The `archive` directory
  was unreferenced.
- The README did not explain workflows, secrets, tags, promotion, scanning,
  recovery, or downstream adoption.

## Decisions

- Pull requests now build locally without registry credentials.
- Trusted branch pushes use an explicitly named GitHub Environment.
- Development and release flows use different conditions and candidate tags.
- Only `main`, after container tests, can update version and `latest` tags.
- Promotion PR creation is idempotent and never merges automatically.
- Deep scanning is consolidated into one reusable workflow.
- Registry cleanup remains reusable but is disconnected from the default
  pipeline, retention-based, and dry-run by default.
- `archive/`, root `.yamllint`, and the duplicate standalone security workflow
  were removed after confirming no required references.
