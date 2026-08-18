# Setup Admin

Admin notes for repos

## Auto-delete merged branches (per repo)

`Settings → General → Pull Requests → check "Automatically delete head branches"`

```sh
gh api -X PATCH repos/gautada/<repo> -f delete_branch_on_merge=true
```

## Branch protection

`Settings → Branches → Add branch protection rule → Branch name pattern: dev`

Run onve then add more checks

```sh
gh api -X PUT repos/gautada/cicd/branches/dev/protection \
  -f required_status_checks[strict]=true \
  -f 'required_status_checks[contexts][]=base / lint / Super Linter' \
  -f 'required_status_checks[contexts][]=base / deep-scan / Semgrep SAST' \
  -f 'required_status_checks[contexts][]=base / deep-scan / SBOM and Grype vulnerability scan' \
  -f required_pull_request_reviews[required_approving_review_count]=1 \
  -f enforce_admins=false \
  -f restrictions=null
```

## Restricting approval to you specifically (optional, addresses 2b precisely)

Plain "require 1 approval" lets anyone with write access approve — not just you. If you want it locked to you:

Create CODEOWNERS in each repo's .github/ folder:* @gautada

"Require review from Code Owners"​.
