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
	mkdir bin
	mkdir init
	mv hashboot.sh bin/hashboot
	mv initscript.openrc init/hashboot
	mv LICENSE HUG-WARE
}


src_install() {
	dodoc README
	insinto /usr/portage/licenses
	doins HUG-WARE
	
	dobin bin/hashboot
	doinitd init/hashboot
}
