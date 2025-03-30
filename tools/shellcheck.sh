#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
BUILD_ROOT="${REPO_ROOT}/build"
BUILD_BIN="${BUILD_ROOT}/bin"

RELEASE=v0.9.0
OSX_RELEASE_MD5=05c5801f6e0c9d03822b1e80fd0bca57
LINUX_RELEASE_MD5=206ca97e055fccfe3546369d14a37760

ARCH=x86_64

SHELLCHECK="${BUILD_BIN}/shellcheck-${RELEASE}"

main() {
  cd "${REPO_ROOT}"

  ensure_shellcheck

  "${SHELLCHECK}" ./**/*.sh
}

ensure_shellcheck() {
  if [[ ! -f "${SHELLCHECK}" ]]; then
    echo "info: Downloading shellcheck-${RELEASE} to build environment"

    mkdir -p "${BUILD_BIN}"

    case "${OSTYPE}" in
      "darwin"*) os_type="darwin"; md5="${OSX_RELEASE_MD5}" ;;
      "linux"*) os_type="linux"; md5="${LINUX_RELEASE_MD5}" ;;
      *) echo "error: Unsupported OS '${OSTYPE}' for shellcheck install, please install manually" && exit 1 ;;
    esac

    shellcheck_zip="/tmp/shellcheck-${RELEASE}.tar.xz"
    curl -sSL -o "${shellcheck_zip}" \
      "https://github.com/koalaman/shellcheck/releases/download/${RELEASE}/shellcheck-${RELEASE}.${os_type}.${ARCH}.tar.xz"
    echo "${md5}" "${shellcheck_zip}" | md5sum --check --quiet -

    shellcheck_dir="/tmp/shellcheck-${RELEASE}"
    mkdir -p "${shellcheck_dir}"
    tar -xvf "${shellcheck_zip}" -C "/tmp"

    if [[ ! -f ${SHELLCHECK} ]]; then
      find "${BUILD_BIN}" -maxdepth 0 -regex '.*/shellcheck-[A-Za-z0-9\.]+$' -exec rm {} \;  # cleanup older versions
      mv "${shellcheck_dir}"/shellcheck "${BUILD_BIN}/shellcheck-${RELEASE}"
    fi

    # Cleanup stale resources.
    rm "${shellcheck_zip}"
    rm -rf "${shellcheck_dir}"
  fi
}

main "$@"