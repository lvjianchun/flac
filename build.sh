#!/bin/bash -x

set -x
#set -e -o pipefail

BUILD_DIR=$PWD/out
export EM_PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig
export PATH=$PATH:$BUILD_DIR/bin

mkdir -p third_party

install_tools() {
	apt-get update
	apt-get install -y autoconf
	apt-get install -y libtool
	apt-get install -y pkg-config
	apt-get install -y gettext
}

download_and_decompress() {
	URL=$1
	FILENAME=$(echo $URL | awk -F'/' '{print $NF}')
	if [ ! -f $FILENAME ]
	then
		wget $URL
	fi
	tar xzf $FILENAME
}

build_libtool() {
	LAST_PWD=$(pwd)
	cd third_party
	download_and_decompress "http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz"
	cd libtool-2.4.6
	emconfigure ./configure \
		--disable-asm \
		--disable-thread \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	cd $LAST_PWD
}

build_libogg() {
	LAST_PWD=$(pwd)
	cd third_party
	download_and_decompress "http://downloads.xiph.org/releases/ogg/libogg-1.3.4.tar.gz"
	cd libogg-1.3.4
	emconfigure ./configure \
		--disable-asm \
		--disable-thread \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	cd $LAST_PWD
}

build_file() {
  touch config.rpath
  autoreconf -fiv
  emconfigure ./configure \
    --disable-asm \
	--disable-asm-optimizations \
	--disable-examples \
    --disable-thread \
	--disable-cpplibs \
	--disable-xmms-plugin \
	--disable-rpath \
	--disable-thorough-tests \
	--disable-vsx \
	--disable-avx \
    --prefix=$BUILD_DIR
  emmake make -j6
  emmake make install
}


function link_js_file() {
  LAST_PWD=$(pwd)
  cd src/metaflac
  emmake make
  em++ -I$BUILD_DIR/include -L${BUILD_DIR}/lib \
	-Oz \
	main.o operations.o operations_shorthand_cuesheet.o operations_shorthand_picture.o operations_shorthand_seektable.o operations_shorthand_streaminfo.o operations_shorthand_vorbiscomment.o options.o usage.o utils.o \
	-logg -lFLAC \
	../../src/share/grabbag/.libs/libgrabbag.a ../../src/share/replaygain_analysis/.libs/libreplaygain_analysis.a ../../out/lib/libogg.a ../../src/share/utf8/.libs/libutf8.a ../../src/share/getopt/.libs/libgetopt.a \
	--closure 1 \
	-o metaflac.js \
	-s USE_SDL=2 \
	-s MODULARIZE=1 \
	-s SINGLE_FILE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s RESERVED_FUNCTION_POINTERS=1 \
	-s EXPORTED_FUNCTIONS="['_metaflac']" \
	-s EXTRA_EXPORTED_RUNTIME_METHODS="[cwrap, FS, getValue, setValue]" \

  cd $LAST_PWD
}

#install_tools
#build_libogg
#build_libtool
build_file
link_js_file

