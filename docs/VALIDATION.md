# Validation record

This file records repeatable local validation. The commands below passed on
2026-07-30 on macOS with Actionlint 1.7.12.

## Commands

```bash
bash -n bin/pre-commit
shellcheck --rcfile templates/pre-commit/.shellcheckrc bin/pre-commit tests/**/*.sh
yamllint .github/workflows templates/cicd templates/pre-commit/.yamllint.yaml
ruby -e 'require "yaml"; Dir["**/*.{yml,yaml}", File::FNM_DOTMATCH].each { |f| YAML.load_file(f); puts f }'
tests/test-static.sh
tests/test-pre-commit.sh
```

The installer test runs twice in a temporary Git repository against a local
HTTP fixture. It verifies idempotency, preservation of a tracked lint file,
absence of implicit workflow/`.gitignore` replacement, hook invocation, and a
clean `git status`. Static tests verify schema-aware Action syntax, shell and
YAML lint, Podman PATH discovery, secret-preflight presence, and obsolete-file
removal.

The complete pinned pre-commit suite also passed after correcting a trailing
space in the shared hook configuration. MarkdownLint was run explicitly over
all newly added documentation because untracked files are not included by
`pre-commit run --all-files` until they enter Git's index.

## GitHub-only checks

Local tools cannot prove Environment approval behavior, fork-token SARIF
permissions, native ARM runner availability, Docker Hub authentication,
multi-architecture manifest publishing, or promotion PR permissions. Exercise
the consumer template with every `@main` reference temporarily changed to the
review branch, then restore or pin the reference after review.
