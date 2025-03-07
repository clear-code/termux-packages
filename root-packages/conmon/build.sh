TERMUX_PKG_HOMEPAGE=https://github.com/containers/conmon
TERMUX_PKG_DESCRIPTION="An OCI container runtime monitor"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=2.1.13
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=(https://github.com/containers/conmon/archive/v${TERMUX_PKG_VERSION}.tar.gz)
TERMUX_PKG_DEPENDS="libseccomp, glib"
TERMUX_PKG_SHA256=(350992cb2fe4a69c0caddcade67be20462b21b4078dae00750e8da1774926d60)
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_SKIP_SRC_EXTRACT=true
# Android 14 or later (API level 34 or later)
# See https://developer.android.com/tools/releases/platforms?hl=en
TERMUX_PKG_API_LEVEL=34

termux_step_get_source() {
	local PKG_SRCURL=(${TERMUX_PKG_SRCURL[@]})
	local PKG_SHA256=(${TERMUX_PKG_SHA256[@]})

	if [ ${#PKG_SRCURL[@]} != ${#PKG_SHA256[@]} ]; then
		termux_error_exit "Error: length of TERMUX_PKG_SRCURL isn't equal to length of TERMUX_PKG_SHA256."
	fi

	# download and extract packages into its own folder inside $TERMUX_PKG_SRCDIR
	mkdir -p "$TERMUX_PKG_CACHEDIR"
	mkdir -p "$TERMUX_PKG_SRCDIR"
	for i in $(seq 0 $(( ${#PKG_SRCURL[@]} - 1 ))); do
		local file="${TERMUX_PKG_CACHEDIR}/$(echo ${PKG_SRCURL[$i]}|cut -d"/" -f 5)-$(basename ${PKG_SRCURL[$i]})"
		termux_download "${PKG_SRCURL[$i]}" "$file" "${PKG_SHA256[$i]}"
		tar xf "$file" -C "$TERMUX_PKG_SRCDIR"
	done

	# delete trailing -$TERMUX_PKG_VERSION from folder name
	# so patches become portable across different versions
	cd "$TERMUX_PKG_SRCDIR"
	for folder in $(ls); do
		if [ ! $folder == ${folder%%-*} ]; then
			mv $folder ${folder%%-*}
		fi
	done
}

termux_step_pre_configure() {
	# setup go build environment
	termux_setup_golang
	export GO111MODULE=auto
}

termux_step_make() {
	echo -n "Building conmon ..."
	# See scripts/build/termux_step_patch_package.sh
        echo "TERMUX_APP_PACKAGE: $TERMUX_APP_PACKAGE"
	echo "TERMUX_BASE_DIR: $TERMUX_BASE_DIR"
	echo "TERMUX_CACHE_DIR: $TERMUX_CACHE_DIR"
	echo "TERMUX_HOME: $TERMUX_ANDROID_HOME"
	echo "TERMUX_PREFIX: $TERMUX_PREFIX"
	echo "TERMUX_PREFIX_CLASSICAL: $TERMUX_PREFIX_CLASSICAL"
	(
	set -e
	cd conmon

	# Build conmon with verbose logging
	BUILDFLAGS="-x -work" GOARCH=arm64 make
	)
	echo " Done!"
}

termux_step_make_install() {
	install -Dm 700 conmon/bin/conmon ${TERMUX_PREFIX}/bin/conmon
	echo " Done!"
}
