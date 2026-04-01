# CICD

This is a collection of templates that allows for common repeatable and yes
complex builds.

## Pre Commit

Included are are configurations for the tools to execute linting on commit.

### pre-commit

### sqlfluff

Install with pipx or Homebrew:

```sh
pipx install sqlfluff
# or
brew install sqlfluff
```

The repo ships a default `.sqlfluff` (Postgres dialect). Run the linter manually
with:

```sh
sqlfluff lint .
```

### jscpd

[jscpd](https://github.com/kucherenko/jscpd) requires Node.js. Install Node (for
example, `brew install node`) and then install the CLI:

```sh
npm install -g jscpd
```

Configuration lives in `.jscpd.json`. To scan locally:

```sh
jscpd --config .jscpd.json
```

Both tools are wired into `.pre-commit-config.yaml`, so `pre-commit run
--all-files` executes them automatically.

#### Install

To install on the system for MacOS

```zsh
brew install pre-commit
```

To install in the project. Copy the file `pre-commit.yaml`

```zsh
pre-commit install
```

#### Run

`pre-commit` will run on all projects where installed when git commit `gc` is
run. To run independently:

```zsh
pre-commit run --all-files
```
