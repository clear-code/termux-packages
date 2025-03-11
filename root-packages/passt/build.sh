TERMUX_PKG_HOMEPAGE=https://passt.top/
TERMUX_PKG_DESCRIPTION="Plug A Simple Socket Transport"
TERMUX_PKG_LICENSE="BSD 3-Clause, GPL-2.0"
TERMUX_PKG_LICENSE_FILE="LICENSES/BSD-3-Clause.txt, LICENSES/GPL-2.0-or-later.txt"
TERMUX_PKG_MAINTAINER="@termux"
_COMMIT=09478d55fe1a21f8c55902399df84d13867e71be
_COMMIT_DATE=2024_12_11
TERMUX_PKG_VERSION=0.0~git${_COMMIT_DATE//_/}.$(echo ${_COMMIT} | head -c 7)
TERMUX_PKG_REVISION=1
TERMUX_PKG_SHA256=dc84b1102788dbec16686af00646c9fae70ba74186a1c72bafeb910ee670a59b
TERMUX_PKG_SRCURL=git+https://github.com/AkihiroSuda/passt-mirror.git
TERMUX_PKG_GIT_BRANCH=master
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_get_source() {
        git fetch --unshallow
        git checkout ${_COMMIT}

        local version=0.0~git"$(git log -1 --format='%D' --decorate-refs=tags | sed -e 's/.*tag: //' -e 's/_//g')"
        if [[ "$TERMUX_PKG_VERSION" != "${version}" ]]; then
                echo -n "ERROR: The version string \"$TERMUX_PKG_VERSION\" is"
                echo -n " different from what is expected to be "
                echo "\"${version}\"."
                return 1
        fi

        local s=$(find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort | sha256sum)
        if [[ "${s}" != "${TERMUX_PKG_SHA256}  "* ]]; then
                termux_error_exit "Checksum mismatch for source files."
        fi
}
