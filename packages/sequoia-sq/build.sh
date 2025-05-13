TERMUX_PKG_HOMEPAGE=https://sequoia-pgp.org/
TERMUX_PKG_DESCRIPTION="A command line application exposing a useful set of OpenPGP functionality for common tasks"
TERMUX_PKG_LICENSE="LGPL-2.0-or-later"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.3.1"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=git+https://gitlab.com/sequoia-pgp/sequoia-sq
TERMUX_PKG_SHA256=""
TERMUX_PKG_GIT_BRANCH=v1.3.1
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="openssl, libnettle, capnproto"
TERMUX_PKG_BUILD_DEPENDS="openssl, pkg-config, nettle, capnproto"
# Android 14 or later (API level 34 or later)
# See https://developer.android.com/tools/releases/platforms?hl=en
TERMUX_PKG_API_LEVEL=34

termux_step_pre_configure() {
	# Debug environment variables
	DEBUG_ENV=1
	if [ $DEBUG_ENV -eq 1 ]; then
		env | sort
		for d in $(echo $TERMUX_PKG_CONFIG_LIBDIR | sed -e 's/:/ /'); do
			echo "TERMUX_PKG_CONFIG_LIBDIR: $d"
				for pc in $(find $d -name '*nettle*.pc'); do
				echo "$pc:"
				cat $pc
			done
		done
	fi
}

termux_step_make() {
	termux_setup_rust
	termux_setup_cargo_c

	echo "CARGO_TARGET_NAME: $CARGO_TARGET_NAME"

	command -v rustup
	echo "rustup target list:"
	rustup target list | grep installed

	echo "rustc --print target-list:"
	rustc --print target-list

	# See packages/rust/build.sh
	export OPENSSL_DIR=$TERMUX_PREFIX
	# Explicitly set PKG_CONFIG_PATH for building nettle-sys
	export PKG_CONFIG_PATH=$TERMUX_PREFIX/lib/pkgconfig:$TERMUX_PREFIX/share/pkgconfig
	export CARGO_BUILD_TARGET=$CARGO_TARGET_NAME

	env | sort | grep -E "CARGO|DIR|FLAGS|PATH"

	echo "rustc:"
	whereis rustc
	echo "rustup:"
	whereis rustup
	echo "cargo:"
	whereis cargo

	echo "~/.cargo/config.toml:"
	cat ~/.cargo/config.toml

	echo "TERMUX_PKG_BUILDDIR: $TERMUX_PKG_BUILDDIR"
	cargo build --verbose --jobs $TERMUX_PKG_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release || \
		find $TERMUX_PKG_BUILDDIR -type f \
		     -not -path '*/.git/*' \
		     -not -path '*/.fingerprint/*' \
		     -not -name 'output' \
		     -not -name 'root-output' \
		     -not -name 'stderr' \
		     -not -name '*.d' \
		     -not -name '*.eml' \
		     -not -name '*.gpg' \
		     -not -name '*.json' \
		     -not -name '*.md' \
		     -not -name '*.pgp' \
		     -not -name '*.rlib' \
		     -not -name '*.rmeta' \
		     -not -name '*.rs' \
		     -not -name '*.sample' \
		     -not -name '*.sign' \
		     -not -name '*.timestamp' \
		     -not -name '*.txt' \
			| xargs file
	#| xargs file | grep -v "ASCII text" | grep -v "POSIX shell scriot" | grep -v "PGP"
}

termux_step_make_install() {
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/sequoia-sq
}
