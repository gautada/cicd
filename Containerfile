FROM docker.io/library/alpine:3.22

ARG GIT_COMMIT=unknown

RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -eu' \
      'test -s /usr/share/cicd-harness/git-commit' \
      'test -f /etc/alpine-release' \
      > /usr/bin/container-test \
    && printf '%s\n' \
      '#!/bin/sh' \
      'set -eu' \
      'printf "0.0.0-%s\\n" "$(cat /usr/share/cicd-harness/git-commit)"' \
      > /usr/bin/container-version \
    && mkdir -p /usr/share/cicd-harness \
    && printf '%s\n' "${GIT_COMMIT}" > /usr/share/cicd-harness/git-commit \
    && chmod 0555 /usr/bin/container-test /usr/bin/container-version

CMD ["tail", "-f", "/dev/null"]
