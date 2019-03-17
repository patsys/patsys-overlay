# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit unpacker

DESCRIPTION="A browser plugin for viewing premium video content, works with Vivaldi browser"
HOMEPAGE="http://www.google.com/chrome"
SRC_URI="https://dl.google.com/widevine-cdm/${PV}-linux-x64.zip"

LICENSE="google-chrome"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""

RESTRICT="bindist mirror strip"

DEPEND="app-arch/unzip >=www-client/vivaldi-1.13"
RDEPEND="
	${DEPEND}
	media-video/ffmpeg[chromium]
"

S="${WORKDIR}"
QA_PREBUILT="*"
src_install() {
	insinto /opt/vivaldi/
	doins libwidevinecdm.so
}

