# CICD

This is a collection of templates that allows for common repeatable and yes
complex builds.

## Pre Commit

Included are are configurations for the tools to execute linting on commit.

### pre-commit

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
