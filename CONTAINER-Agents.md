# Development instructions

This repository uses the shared gautada/cicd container pipeline.

Before committing:

1. Work on a feature branch targeting `dev`.
2. From the repository root, run:
   `curl -sSfL https://raw.githubusercontent.com/gautada/cicd/main/bin/pre-commit | bash`
3. Resolve every lint, build, scan, and container-test failure.
4. Never commit downloaded lint configuration, credentials, `.env`, SARIF,
   SBOM, or container archives.
5. Never expose registry secrets to pull-request code.

When explicitly authorized to deliver changes:

1. Commit and push the feature branch.
2. Open a PR targeting `dev`.
3. Wait for GitHub Actions to complete and address failures.
4. Report the successful PR to the user.
5. Do not merge the PR unless explicitly authorized.

After a merge into `dev`, the pipeline publishes and tests `:dev`, then creates
or updates the `dev` to `main` promotion PR. Never merge that promotion PR
without explicit human authorization.

Canonical documentation:
[AI agent instructions](https://github.com/gautada/cicd/blob/main/AI.md)
