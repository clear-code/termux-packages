TERMUX_PKG_HOMEPAGE=https://podman.io/
TERMUX_PKG_DESCRIPTION="The best free & open source container tools"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=5.4.0
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=(https://github.com/containers/podman/archive/v${TERMUX_PKG_VERSION}.tar.gz)
TERMUX_PKG_DEPENDS="libseccomp, gpgme"
TERMUX_PKG_SHA256=(e5efb825558624d0539dac94847c39aafec68e6d4dd712435ff4ec1b17044b69)
#TERMUX_PKG_CONFFILES="etc/docker/daemon.json"
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
	# BUILD DOCKERD DAEMON
	echo -n "Building podman ..."
	# See scripts/build/termux_step_patch_package.sh
        echo "TERMUX_APP_PACKAGE: $TERMUX_APP_PACKAGE"
	echo "TERMUX_BASE_DIR: $TERMUX_BASE_DIR"
	echo "TERMUX_CACHE_DIR: $TERMUX_CACHE_DIR"
	echo "TERMUX_HOME: $TERMUX_ANDROID_HOME"
	echo "TERMUX_PREFIX: $TERMUX_PREFIX"
	echo "TERMUX_PREFIX_CLASSICAL: $TERMUX_PREFIX_CLASSICAL"
	(
	set -e
	cd podman

	# Build podman with verbose logging
	# FIXME: need libsubid
	# BUILDTAGS="seccomp selinux libsubid cni exclude_graphdriver_devicemapper exclude_graphdriver_btrfs"
	BUILDTAGS="seccomp selinux cni exclude_graphdriver_devicemapper exclude_graphdriver_btrfs"
	BUILDFLAGS="-x -work" BUILDTAGS="$BUILDTAGS" GOARCH=arm64 make podman
	# Build podman-remote
	BUILDFLAGS="-x -work" make podman-remote-static-linux_arm64
	# Build podman-testing
	BUILDFLAGS="-x -work" BUILDTAGS="$BUILDTAGS" GOARCH=arm64 make podman-testing
	# Build utilities
	BUILDFLAGS="-x -work" BUILDTAGS="$BUILDTAGS" GOARCH=arm64 make rootlessport
	BUILDFLAGS="-x -work" BUILDTAGS="$BUILDTAGS" GOARCH=arm64 make quadlet
	)
	echo " Done!"
}

termux_step_make_install() {
	find podman -name '*rootlessport*'
	install -Dm 700 podman/bin/podman ${TERMUX_PREFIX}/bin/podman
	# podmansh is just alias of podman
	install -Dm 700 podman/bin/podman ${TERMUX_PREFIX}/bin/podmansh
	install -Dm 700 podman/bin/podman-remote-static-linux_arm64 ${TERMUX_PREFIX}/bin/podman-remote
	install -Dm 700 podman/bin/podman-testing ${TERMUX_PREFIX}/libexec/podman/podman-testing
	install -Dm 700 podman/bin/rootlessport ${TERMUX_PREFIX}/libexec/podman/rootlessport
	install -Dm 700 podman/bin/quadlet ${TERMUX_PREFIX}/libexec/podman/quadlet
	# Derived from vendor/github.com/containers/common/pkg/config/containers.conf
	install -Dm 644 ${TERMUX_PKG_BUILDER_DIR}/containers.conf ${TERMUX_PREFIX}/share/containers/containers.conf
	# Derived from vendor/github.com/containers/storage/storage.conf
	install -Dm 644 ${TERMUX_PKG_BUILDER_DIR}/storage.conf ${TERMUX_PREFIX}/etc/containers/storage.conf
	# Install simple registries.conf
	install -Dm 644 ${TERMUX_PKG_BUILDER_DIR}/registries.conf ${TERMUX_PREFIX}/etc/containers/registries.conf
	# Install policy.json
	install -Dm 644 ${TERMUX_PKG_BUILDER_DIR}/policy.json ${TERMUX_PREFIX}/etc/containers/policy.json
	echo " Done!"
}

termux_step_post_make_install() {
	echo " termux_step_post_make_install for podman"
	echo " Done!"
}

termux_step_create_debscripts() {
	cat <<- EOF > postinst
		#!${TERMUX_PREFIX}/bin/sh

		echo 'NOTE: Podman requires the kernel to support'
		echo 'device cgroups, namespace, VETH, among others.'
		echo
		echo 'To check a full list of features needed, run the script:'
		echo 'https://github.com/moby/moby/blob/master/contrib/check-config.sh'

		# Configure subuid and subgid
		# See https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md
		if [ ! -f ${TERMUX_PREFIX}/etc/subuid ]; then
			echo 'a0_a100:100000:65536' > ${TERMUX_PREFIX}/etc/subuid
		fi
		if [ ! -f ${TERMUX_PREFIX}/etc/subgid ]; then
			echo 'a0_a100:100000:65536' > ${TERMUX_PREFIX}/etc/subgid
		fi
	EOF
}
