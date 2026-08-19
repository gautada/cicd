# [TEST} Shared container CI/CD Actions

This repository provides reusable GitHub Actions workflows for linting,
security scanning, building, testing, and publishing multi-architecture Podman
images. It also provides an ephemeral pre-commit configuration and a consumer
workflow installer.

The repository is also its own smallest consumer. `Containerfile` implements
the built-in test and version commands, while `.github/workflows/container.yaml`
calls `cicd-container.yaml` at `@dev`. The installer copies that same canonical
caller into consumer repositories and rewrites it to `@main`. Pull requests
exercise secret-free lint, scan, and multi-architecture builds; pushes exercise
the protected publish, test, and release path. Keep this container-only harness
minimal. Future Go and Python combinations should use separate orchestrators or
documented inputs instead of adding language tooling to the baseline image.

The design keeps registry credentials away from pull-request code, validates
changes before publishing, and requires a human-reviewed `dev` to `main`
promotion before release tags move.

## Delivery lifecycle

```text
PR to dev/main
  └─ lint ─ deep scan ─ local amd64/arm64 builds (no registry secrets)

push to dev
  └─ lint ─ deep scan ─ build/push commit images ─ publish :dev
       └─ container test ─ create or reuse dev→main PR

merge/push to main
  └─ lint ─ deep scan ─ rebuild/push commit images ─ publish :candidate
       └─ container test ─ publish :<container-version> and :latest
```

The workflows never merge the promotion PR. A human reviews and merges it.
Version tags come from `/usr/bin/container-version` inside the built image and
must be valid OCI/Docker tag strings.

## Workflow inventory

| Workflow | Trigger | Purpose | Important inputs | Credentials |
| --- | --- | --- | --- | --- |
| `cicd-container.yaml` | `workflow_call` | Orchestrate the complete container lifecycle | architectures, `cicd_ref`, registry, promotion | Docker registry secrets |
| `ci-linter.yaml` | `workflow_call` | Pull ephemeral lint rules and run Super Linter | `cicd_ref` | None |
| `ci-deep-scan.yaml` | `workflow_call` | Semgrep SAST, SPDX SBOM, and Grype scan | `image_ref`, `fail_on_severity` | None for source/public images |
| `ci-podman-build.yaml` | `workflow_call` | Build one architecture; optionally push a commit tag | architecture, paths, `publish` | Registry secrets only when publishing |
| `ci-podman-publish.yaml` | `workflow_call` | Assemble commit images into `dev` or `candidate` manifest | architectures and tags | Registry secrets |
| `ci-container-test.yaml` | `workflow_call` | Pull an image and retry its built-in test until timeout | `image_tag`, `startup_timeout` | Registry secrets |
| `cd-tag-latest.yaml` | `workflow_call` | Read the image version and publish version/`latest` manifests | architectures and build tag | Registry secrets |
| `ci-registry-clean.yaml` | `workflow_call` | Retain recent commit tags; dry-run by default | retention count, `dry_run` | Docker Hub secrets |

All registry workflows accept `registry_name` and `environment_name`.
`ci-registry-clean.yaml` is Docker Hub-specific; the other registry workflows
use Podman and can work with compatible registries.

## Consumer setup

### 1. Add the workflow

From the root of a consumer repository, the standard installer creates
`.github/workflows/container.yaml` when it is missing and targets `cicd@main`:

```bash
curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit |
  bash -s -- --workflow container
```

It preserves an existing workflow. To explicitly replace the workflow and
`.gitignore`, use:

```bash
curl -sSfL \
  https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit \
  -o /tmp/gautada-cicd-pre-commit
bash /tmp/gautada-cicd-pre-commit \
  --pull-only --workflow container --sync-project
rm /tmp/gautada-cicd-pre-commit
```

Review workflow updates before committing them. Existing consumers should not
run `--sync-project` blindly because it intentionally replaces the consumer
workflow and `.gitignore`.

The `--ref REF` option selects both the downloaded configuration revision and
the literal orchestrator reference written into the consumer workflow. For
example, `--ref dev` writes `@dev`; the default writes `@main`.

Workflow installation is explicit. `--workflow container` selects the
canonical container caller; omitting `--workflow` installs only lint
configuration and hooks. This leaves room for future `go` and `python`
workflow selections without making every repository install container CI.

GitHub displays the **Run workflow** button only after the workflow containing
`workflow_dispatch` exists on the repository's default branch. Until the
initial promotion reaches `main`, rerun an existing `dev` workflow from its run
page instead.

To test an unreleased orchestrator from a consumer, change its single `@main`
reference to the test branch and pass the same revision for lint configuration.
GitHub requires the workflow reference to be literal; it cannot come from an
environment variable or expression:

```yaml
container:
  uses: gautada/cicd/.github/workflows/cicd-container.yaml@ai
  with:
    cicd_ref: ai
  secrets:
    DOCKERIO_REGISTRY: ${{ secrets.DOCKERIO_REGISTRY }}
    DOCKERIO_TOKEN: ${{ secrets.DOCKERIO_TOKEN }}
```

Pinning consumers to a reviewed commit SHA gives the strongest protection
against upstream workflow changes.

### 2. Configure registry credentials

The standard caller inherits these repository or organization Actions secrets:

| Secret | Required | Meaning |
| --- | --- | --- |
| `DOCKERIO_REGISTRY` | Yes | Registry namespace/login, currently the Docker Hub username |
| `DOCKERIO_TOKEN` | Yes | Least-privilege registry access token; never use an account password |

The orchestrator maps them to the generic `REGISTRY_USERNAME` and
`REGISTRY_TOKEN` interface used by registry jobs. Alternatively, an Environment
named `container-registry` may define those generic names; GitHub Environment
secrets take precedence in the nested jobs. Missing values fail in the first
inexpensive step and their values are never printed.

Recommended Environment policy:

- allow only `dev` and `main` deployment branches;
- require review for production if the approval frequency is acceptable;
- do not make the Environment available to pull-request jobs;
- rotate the registry token and grant only pull/push/delete permissions needed
  by the workflows you actually call.

If approval is required on `container-registry`, GitHub may request approval
for each reusable job that enters it. For a smoother release, use separate
`container-development` and `container-production` environments and pass the
appropriate name from a customized consumer workflow.

### 3. Configure GitHub permissions

In **Settings → Actions → General → Workflow permissions**:

- permit GitHub Actions to create pull requests;
- keep the default token read-only except for explicitly declared job
  permissions;
- ensure code scanning is available if SARIF uploads are desired.

The promotion job receives only `contents: read` and `pull-requests: write`.
It searches for an existing open `dev` to `main` PR before creating one. A PR
created by `GITHUB_TOKEN` creates an approval-required workflow run. A
maintainer must approve that run before its `main`-targeted checks start. The
already-tested `dev` commit remains the initial promotion evidence, and the
merge-to-`main` push runs the release pipeline.

### 4. Protect branches

Recommended rulesets:

- `dev`: require pull requests for contributors, require lint, deep-scan, and
  both local build checks, and block force pushes;
- `main`: require the `dev` promotion PR, at least one human approval, resolved
  conversations, current required checks, and block direct/force pushes;
- restrict workflow-file changes to trusted reviewers with `CODEOWNERS` if
  multiple contributors have write access.

Check names should be selected from a successful run because GitHub displays
the fully qualified names of reusable jobs.

## Build and tag model

For repository `owner/example` at commit `abcdef1`, the build jobs publish:

```text
docker.io/<namespace>/example:build-amd64-abcdef1
docker.io/<namespace>/example:build-arm64-abcdef1
```

On `dev`, those images become the multi-architecture `example:dev` manifest.
On `main`, they first become `example:candidate`, which is tested. Only a
successful test allows `example:<version>` and `example:latest` to update.

Commit-specific build tags make re-runs deterministic. The registry cleanup
workflow keeps the newest ten per architecture by default and cannot delete
anything unless `dry_run: false` is explicitly supplied.

## Tool discovery and failures

Workflows install Podman when necessary and resolve it with `command -v`.
The release workflow selects the executable owned by the installed package so
it remains compatible with the installed OCI runtime even when the runner has
another Podman earlier on `PATH`. Workflows store the discovered executable in
`PODMAN`, print its version, and never assume `/usr/bin/podman` or
`/usr/local/bin/podman`.

Registry workflows validate secrets before installing packages, pulling, or
building. Common errors are:

- **Missing Environment secrets:** confirm the environment name, secret names,
  and deployment-branch policy.
- **Podman not found:** inspect the install step and runner image. The resolved
  path and version appear in logs.
- **Architecture build missing:** find the corresponding
  `build-<arch>-<sha>` job; publish will not fall back to a stale image.
- **Container test timeout:** inspect the automatically captured container log
  and run `/usr/bin/container-test` locally.
- **Invalid release version:** make `/usr/bin/container-version` emit exactly
  one non-empty tag-safe value.
- **Promotion PR not created:** enable the GitHub setting allowing Actions to
  create PRs and inspect the promotion job's permissions.

GitHub jobs can be safely re-run. Build tags are commit-addressed, manifest
creation removes only its local names before rebuilding, and promotion reuses
an open PR. Do not re-run registry cleanup with deletion enabled until its
dry-run list has been reviewed.

## Deep scan

`ci-deep-scan.yaml` has two parallel jobs:

1. Semgrep Community Edition downloads the `p/ci` ruleset and performs source
   SAST. Findings fail the job and produce SARIF.
2. Syft produces an SPDX JSON SBOM artifact. Grype scans the repository
   filesystem by default and fails at `high` severity or above.

When `image_ref` is supplied, Grype scans that image instead of the filesystem.
The image must be public or already accessible without adding registry secrets
to this workflow. The standard container pipeline scans source before images exist;
scanning a private built image should be a separate protected post-build job.

SARIF is uploaded to GitHub code scanning when token permissions permit it.
Uploads are skipped for fork PRs because GitHub downgrades their token, but the
scans still run and gate the PR. Typical runtime is several minutes and varies
with repository size, rule downloads, vulnerability database downloads, and
runner cache state.

The old `security-and-lint.yml` duplicated lint, Semgrep, Syft, and Grype with
different action versions and was removed. `ci-deep-scan.yaml` is now the
single documented deep-scan implementation.

## Local pre-commit checks

The convenient command remains:

```bash
curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit | bash
```

For inspection before execution, prefer:

```bash
script="$(mktemp)"
curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit -o "${script}"
less "${script}"
bash "${script}"
rm "${script}"
```

The script:

- requires the root of a Git checkout;
- downloads lint configuration transactionally into a temporary directory;
- retries transient downloads;
- never replaces a tracked project-owned lint configuration;
- installs generated rules as gitignored working-tree files;
- installs the pre-commit hook and runs all checks;
- cleans its temporary download directory on exit;
- is safe to run repeatedly.

Install pre-commit first with `pipx install pre-commit`. Hook environments
install most linters themselves; system-language hooks such as Hadolint and
ShellCheck still require those executables on `PATH`.

Options:

| Option | Effect |
| --- | --- |
| `--workflow container` | Install the container workflow when missing |
| `--sync-project` | Replace the selected workflow and canonical `.gitignore` |
| `--ref REF` | Use a reviewed branch, tag, or commit instead of `main` |
| `--pull-only` | Download configuration without installing or running hooks |

`--sync-project` requires `--workflow` so an overwrite is always tied to an
explicitly selected project workflow.

Generated lint files remain untracked because the canonical `.gitignore`
lists them. Always inspect `git status` before committing.

## Migration checklist

- Install or refresh the canonical consumer `container.yaml`.
- Create repository or organization Actions secrets named
  `DOCKERIO_REGISTRY` and `DOCKERIO_TOKEN`, or configure equivalent generic
  secrets in the `container-registry` Environment.
- Enable Actions to create pull requests.
- Confirm `/usr/bin/container-test` and `/usr/bin/container-version` exist in
  the image and return meaningful exit status/output.
- Confirm both native GitHub-hosted runner labels are available to the account.
- Test with reusable workflow references pinned to the change branch.
- Review a successful dry-run cleanup before enabling deletion.
- Add required checks and environment restrictions only after observing their
  exact names in a successful run.
- Pin reusable workflows to a stable tag or commit after rollout.

## Known limitations

- Docker Hub cleanup uses Docker Hub's API and is not registry-neutral.
- GitHub-hosted runner images and the unpinned Semgrep container image can
  change upstream. Consumers with strict supply-chain requirements should pin
  all action SHAs and a reviewed Semgrep image digest.
- Local validation cannot reproduce Environment approvals, fork token
  downgrades, native ARM runner availability, registry manifests, or GitHub's
  PR-creation policy. Test the `ai` reference in a disposable consumer before
  promoting it to `main`.
- Version tags are treated as immutable by process; registries may still allow
  overwriting unless their policy forbids it.

See [AI.md](AI.md) for agent-specific operating rules and
[docs/AUDIT.md](docs/AUDIT.md) for the original-state audit.

For downstream container repositories, copy
[`CONTAINER-Agents.md`](CONTAINER-Agents.md) to the consumer repository as
`AGENTS.md`. Agents do not automatically read instructions from a remote
reusable-workflow repository; keeping this small file in the consumer makes
the pre-commit, branch, CI-waiting, PR, and approval rules discoverable.
