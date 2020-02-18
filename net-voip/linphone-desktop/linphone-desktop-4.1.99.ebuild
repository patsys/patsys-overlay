# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PLOCALES="ar cs de es fi fr he hu it ja lt nb_NO nl pl pt_BR ru sr sv tr zh_CN zh_TW"

PYTHON_COMPAT=( python3_6 pypy3 )
PYTHON_REQ_USE="threads(+)"

EGIT_REPO_URI="https://gitlab.linphone.org/BC/public/linphone-desktop"
EGIT_COMMIT=10439a5692412f15b1d7f097244282434bbb15e3

CMAKE_MAKEFILE_GENERATOR="emake"

inherit l10n multilib pax-utils cmake-utils git-r3 toolchain-funcs python-single-r1

DESCRIPTION="Video softphone based on the SIP protocol"
HOMEPAGE="http://www.linphone.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc dbus ipv6 gsm libnotify nls +sqlite tools upnp vcard video zlib debug pcap +ssl ilbc ffmpeg bindist codec2 amr silk x264 ilbc bv16 vpx aec g726 alsa speex tools python ldap matroska2 X g729 test theora"

REQUIRED_USE=""

RDEPEND="
	dev-python/javasphinx[${PYTHON_USEDEP}]
	dev-python/pystache[${PYTHON_USEDEP}]
	dev-cpp/xsd
	virtual/udev
	net-libs/libsrtp
	net-libs/mbedtls
	media-libs/spandsp
	theora? ( media-libs/libtheora )
	ffmpeg? ( virtual/ffmpeg )
	ldap? ( net-nds/openldap )
	ilbc? ( dev-libs/ilbc-rfc3951 )
	pcap? ( net-libs/libpcap )
	dbus? ( sys-apps/dbus )
	sqlite? ( dev-db/sqlite:3 )
	tools? ( dev-libs/libxml2 )
	upnp? ( net-libs/libupnp:0 )
	aec? ( sci-libs/libaec )
	zlib? ( sys-libs/zlib )
"
DEPEND="${RDEPEND}
	python? ( dev-python/wheel[${PYTHON_USEDEP}] )
	dev-java/antlr:3
	dev-libs/antlr-c
	virtual/pkgconfig
	doc? ( app-text/sgmltools-lite )
	nls? ( dev-util/intltool )
"

PATCHES=( "${FILESDIR}/linphone-4.1.1-belle-sip.patch" )

BUILD_DIR=${S}/WORK/desktop

src_prepare() {
	./prepare.py --clean
	local i
	for i in $(find linphone-sdk -type f -name CMakeLists.txt -print); do
		[ -s "$i" ] || continue
		sed -i \
			-e '/option(ENABLE_STRICT /s/\(YES\|ON\)/NO/' \
		    -e 's/-Werror=/-Wno-error=/g' \
			-e 's/-Werror//g' \
			-e "s,DESTINATION lib\(/\|$\),DESTINATION $(get_libdir)\1,g" \
			$i || die
	done
	sed -i 's/ BCTBX_INLINE / /' \
		linphone-sdk/bctoolbox/include/bctoolbox/*.h  || die
	sed -i 's/ ORTP_INLINE / /' \
		linphone-sdk/ortp/include/ortp/*.h  || die

	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DENABLE_ARCH_SUFFIX=ON
		-DENABLE_AMRNB=$(usex amr YES NO)
		-DENABLE_AMRWB=$(usex amr YES NO)
		-DENABLE_BV16=$(usex bv16 YES NO)
		-DENABLE_CODEC2=$(usex codec2 YES NO)
		-DENABLE_CSHARP_WRAPPER=NO
		-DENABLE_CXX_WRAPPER=YES
		-DENABLE_DBUS=$(usex dbus YES NO)
		-DENABLE_DOC=$(usex doc YES NO)
		-DENABLE_FFMPEG=$(usex ffmpeg YES NO)
		-DENABLE_G726=$(usex g726 YES NO)
		-DENABLE_G729=$(usex g729 YES NO)
		-DENABLE_G729B_CNG=$(usex g729 YES NO)
		-DENABLE_GPL_THIRD_PARTIES=YES
		-DENABLE_GSM=$(usex gsm YES NO)
		-DENABLE_GTK_UI=NO
		-DENABLE_H263=NO
		-DENABLE_H263P=NO
		-DENABLE_ILBC=$(usex ilbc YES NO)
		-DENABLE_ISAC=NO
		-DENABLE_JPEG=YES
		-DENABLE_LIME=YES
		-DENABLE_MBEDTLS=$(usex ssl YES NO)
		-DENABLE_MKV=YES
		-DENABLE_NLS=$(usex nls YES NO)
		-DENABLE_NON_FREE_CODECS=$(usex bindist NO YES)
		-DENABLE_MPEG4=$(usex bindist NO YES)
		-DENABLE_OPUS=YES
		-DENABLE_PACKAGING=NO
		-DENABLE_PCAP=$(usex pcap YES NO)
		-DENABLE_POLARSSL=NO
		-DENABLE_SILK=$(usex silk YES NO)
		-DENABLE_SOURCE_PACKAGING=NO
		-DENABLE_SPEEX=$(usex speex YES NO)
		-DENABLE_SRTP=YES
		-DENABLE_STATIC_ONLY=NO
		-DENABLE_TOOLS=$(usex tools YES NO)
		-DENABLE_UNMAINTAINED=NO
		-DENABLE_UPDATE_CHECK=YES
		-DENABLE_V4L=$(usex video YES NO)
		-DENABLE_VCARD=$(usex vcard YES NO)
		-DENABLE_VIDEO=$(usex video YES NO)
		-DENABLE_VPX=YES
		-DENABLE_THEORA=$(usex theora YES NO)
		-DENABLE_WEBRTC_AEC=NO
		-DENABLE_WEBRTC_AECM=NO
		-DENABLE_ZRTP=YES
		-DENABLE_STRICT=NO
		-DCMAKE_INSTALL_RPATH='\\$ORIGIN/../'$(get_libdir)
		-DENABLE_UNIT_TESTS=$(usex test)
		-DENABLE_GTK_UI=NO
		-DENABLE_DEBUG_LOGS=YES
		-DCMAKE_BUILD_TYPE=$(usex debug Debug Release)
		-DENABLE_RELATIVE_PREFIX=YES
	)

	local target='desktop'

	use python && target="desktop python"

	./prepare.py --use-system-dependencies ${mycmakeargs[@]} ${target}
}

src_compile() {
	local target='desktop'

	use python && target="desktop python"

	cd ${S}
	make ${target}
}

src_install() {
	dodir /usr
	cp -a ${S}/OUTPUT/desktop/* ${D}/usr

	#mv ${D}/usr/lib/* ${D}/usr/$(get_libdir) &&
	#rmdir ${D}/usr/lib

	for i in ebml matroska opencore-amrnb vo-amrwbenc; do
		test -d /usr/include/$i || continue
		rm -r ${D}/usr/include/$i
	done

	rm ${D}/CMakeCache.txt
	rm -r ${D}/CMakefiles
	rm -r ${D}/usr/cmake
	rm -r ${D}/usr/$(get_libdir)/cmake/minizip
	rm ${D}/usr/$(get_libdir)/pkgconfig/minizip.pc
	rm ${D}/usr/$(get_libdir)/libminizip.so


	dodoc CHANGELOG.md README.md
	pax-mark m "${ED%/}/usr/bin/linphone"
}
