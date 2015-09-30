EAPI="4"

EGIT_REPO_URI="git://git.tastytea.de/repositories/hashboot.git"

inherit eutils git-2

DESCRIPTION="Check integrity of files in /boot"
HOMEPAGE="https://git.tastytea.de/?p=hashboot.git"
LICENSE="public-domain"
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
"
DEPEND="${RDEPEND}
"
PDEPEND="
"

src_unpack() {
	git-2_src_unpack
}

src_prepare() {
	mv initscript.openrc hashboot
}


src_install() {
	dodoc README
	dobin hashboot.sh
	doinitd hashboot
}
