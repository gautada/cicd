# CICD

This is a collection of templates that allows for common repeatable and yes
complex builds.

## Pre Commit

Included are are configurations for the tools to execute linting on commit.

### Linters

The pre-commit configuration includes several linters that may require local installation:

#### ShellCheck

Required for linting shell scripts.

```zsh
brew install shellcheck
```

#### Hadolint

Required for linting Dockerfiles/Containerfiles.

```zsh
brew install hadolint
```

#### SQLFluff

Required for linting SQL files.

```zsh
pip install sqlfluff
```

#### jscpd

Required for detecting duplicate code.

```zsh
# Ensure Node.js is installed
brew install node

# Install jscpd globally or in the project
npm install -g jscpd
```

## Template Syncing

To sync the latest configurations to your project, use the provided sync script:

```zsh
# Coming soon...
```
