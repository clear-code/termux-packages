TERMUX_PKG_HOMEPAGE=https://github.com/shadow-maint/shadow
TERMUX_PKG_DESCRIPTION="Upstream shadow tree"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=4.17.3
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=(https://github.com/shadow-maint/shadow/archive/${TERMUX_PKG_VERSION}.tar.gz)
TERMUX_PKG_SHA256=(03c9875be9157c8c977edd7316dc3567748072547c293b8f9abb475dfd30b6bf)
TERMUX_PKG_DEPENDS="libcrypt, libbsd, libacl"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-man
--enable-subordinate-ids
--with-acl
--with-attr
--with-yescrypt
--with-bcrypt
--without-libpam
--without-nscd
--without-selinux
--without-sssd
--without-su
"

# pam: no libbpam
# nscd: no posix_spawn
# sssd: no posix_spawn
# selinux: no libsemanage-dev
# su: termux-tools provides su

termux_step_pre_configure() {
	# Do not use bundled autogen.sh
	autoreconf --verbose --force --install
}
