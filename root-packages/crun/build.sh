TERMUX_PKG_HOMEPAGE=https://github.com/containers/crun
TERMUX_PKG_DESCRIPTION="A fast and lightweight fully featured OCI runtime and C library for running containers"
TERMUX_PKG_LICENSE="GPL-2.0, LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="COPYING, COPYING.libcrun"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.20
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=git+https://github.com/containers/crun.git
TERMUX_PKG_GIT_BRANCH=main
TERMUX_PKG_SHA256=943e80be25ad09f7a36cb159249dd69169c1fd58378bd40eade9ba1c3410d0ba
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="yajl, libcap, argp"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-systemd"
TERMUX_PKG_EXTRA_MAKE_ARGS=" -k"

termux_step_post_get_source() {
        git fetch --unshallow
        git checkout ${TERMUX_PKG_VERSION}

        local version="$(git log -1 --format='%D' --decorate-refs=tags | sed -e 's/.*tag: //' -e 's/_//g')"
        if [[ "$TERMUX_PKG_VERSION" != "${version}" ]]; then
                echo -n "ERROR: The version string \"$TERMUX_PKG_VERSION\" is"
                echo -n " different from what is expected to be "
                echo "\"${version}\"."
                return 1
        fi

        local s=$(find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort | sha256sum)
        local s2=$(find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort)
        if [[ "${s}" != "${TERMUX_PKG_SHA256}  "* ]]; then
                termux_error_exit "Checksum mismatch for source files."
        fi
}

termux_step_pre_configure() {
        ./autogen.sh
}
