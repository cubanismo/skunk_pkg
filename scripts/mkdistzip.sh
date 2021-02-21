#!/bin/sh
#
# This script will gather up all the files needed to generate the content for
# the Skunkboard source code and installer release directory structure, as
# present on the Rev.5 collector's edition USB stick. However, it makes
# various assumptions:
#
# 1) You have already built appropriate installers for JCP, as described in
#    release_checklist.txt in the JCP source tree, and copied them to the
#    the computer where you'll be running this script
#
# 2) You have the "zip" utility installed on the computer where you're running
#    this script.
#
# 3) You want to release the very latest version of all the other Skunkboard
#    code and related source assets present in their github repositories.
#
# If all this is true, simply run the script as follows:
#
#   $ ./mkdistzip.sh \
#       <JCP version (must be formatted as NN.NN.NN)> \
#       <path to JCP Windows installer> \
#       <path to JCP macOS installer> \
#       <full path and filename of target zip file>
#
# And it should download all the relevant data and package it up.
#
usage() {
	echo ""
	echo "usage: mkdistzip.sh <JCP version> \\"
	echo "           <path to JCP Windows installer> \\"
	echo "           <path to JCP macOS installer \\"
	echo "           <output file>"
	echo ""
	echo "example:"
	echo ""
	echo "  mkdistzip.sh 02.06.00 jcp_installer.exe JCPInstaller.pkg skunkdist.zip"
	echo ""
	echo "See the comment at the top of this script for more details."
	echo ""

	exit 1
}

getfullpath() {
	DIR="`dirname "$1" 2>/dev/null`"
	RET="`cd "$DIR"; pwd`"

	echo "$RET/`basename "$1" 2>/dev/null`"
}

JCPVERS="$1"
JCPWIN="`getfullpath "$2"`"
JCPMAC="`getfullpath "$3"`"
OUTFILE="`getfullpath "$4"`"

if [ -z "$JCPVERS" ]; then
	echo "Invalid JCP version"
	usage
else
	MAJOR=`echo "$JCPVERS"|cut -d . -f 1`
	MINOR=`echo "$JCPVERS"|cut -d . -f 2`
	PATCH=`echo "$JCPVERS"|cut -d . -f 3`

	if [ `expr "x$MAJOR" : "x[0-9][0-9]"` -le 0 ]; then
		echo "Invalid JCP major version"
		usage
	fi

	if [ `expr "x$MINOR" : "x[0-9][0-9]"` -le 0 ]; then
		echo "Invalid JCP minor version"
		usage
	fi

	if [ `expr "x$PATCH" : "x[0-9][0-9]"` -le 0 ]; then
		echo "Invalid JCP patch version"
		usage
	fi
fi

if [ ! -r "$JCPWIN" -o ! -f "$JCPWIN" ]; then
	echo "Windows JCP installer not found"
	usage
else
	echo "Using Windows JCP installer: '$JCPWIN'"
fi

if [ ! -r "$JCPMAC" -o ! -f "$JCPMAC" ]; then
	echo "macOS JCP installer not found"
	usage
else
	echo "Using macOS JCP installer: '$JCPMAC'"
fi

if [ -f "$OUTFILE" ]; then
	echo "Refusing to overwrite output file"
	usage
else
	echo "Writing to output file: '$OUTFILE'"
fi

WORKDIR="`mktemp -d`"
cd "$WORKDIR"
mkdir Source
cd Source
git clone https://github.com/cubanismo/skunk_pcb.git pcb
rm -rf pcb/.git
git clone https://github.com/tursilion/skunk_butcher.git cpld
rm -rf cpld/.git
git clone https://github.com/cubanismo/skunk_bios.git bios
rm -rf bios/.git
git clone https://github.com/cubanismo/bjlSkunkFlash.git bjlSkunkFlash
rm -rf bjlSkunkFlash/.git
git clone https://github.com/cubanismo/skunk_jcp.git jcp
rm -rf jcp/.git
git clone https://github.com/cubanismo/skunk_pkg.git packaging
rm -rf packaging/.git
mkdir libusb
cd libusb
curl -J -O -L 'https://sourceforge.net/projects/libusb-win32/files/libusb-win32-releases/1.2.6.0/libusb-win32-bin-1.2.6.0.zip/download#'
curl -J -O -L 'https://sourceforge.net/projects/libusb-win32/files/libusb-win32-releases/1.2.6.0/libusb-win32-src-1.2.6.0.zip/download#'
curl -J -O -L 'https://sourceforge.net/projects/libusb/files/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz/download#'
cd ..
git clone https://github.com/cubanismo/libwdi.git
rm -rf libwdi/.git
cd ..
mkdir Windows
cp "$JCPWIN" "Windows/jcp_installer-$JCPVERS.exe"
mkdir macOS
cp "$JCPMAC" "macOS/JCPInstaller-$JCPVERS.pkg"

zip -r "$OUTFILE" .
cd
rm -rf "$WORKDIR"
