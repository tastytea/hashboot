EAPI="4"

EGIT_REPO_URI="git://git.tastytea.de/repositories/hashboot.git"

inherit eutils git-2

DESCRIPTION="Check integrity of files in /boot"
HOMEPAGE="https://git.tastytea.de/?p=hashboot.git"
LICENSE="hug-ware"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="
	sys-apps/coreutils
	app-arch/tar
	sys-apps/findutils
	sys-apps/grep
	virtual/awk
	app-shells/bash
	sys-apps/util-linux
	app-arch/gzip
"
DEPEND="${RDEPEND}
"
PDEPEND="
"

src_unpack() {
	git-2_src_unpack
}

src_prepare() {
	if grep -q '^rc_parallel="YES"' /etc/rc.conf
	then
		ewarn "hashboot does not work properly with parallel boot enabled."
	fi
	
	mkdir init
	mv initscript.openrc init/hashboot
	mv LICENSE HUG-WARE
}


src_install() {
	dodoc README
	insinto /usr/portage/licenses
	doins HUG-WARE
	
	dobin hashboot
	doinitd init/hashboot
}
