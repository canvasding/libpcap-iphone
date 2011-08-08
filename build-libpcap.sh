#!/bin/bash

#  Automatic build script for libpcap
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 30.01.11. <-- "Original Owner"
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  pcap build modifications
#  Created by Jarrod Ariyasu on 08/07/2011
#  Copyright 2011 Jarrod Ariyasu. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here
#
VERSION="1.1.1"
SDKVERSION="4.3"
FILE="libpcap-${VERSION}.tar.gz"
#
###########################################################################
#
# Don't change anything here
CURRENTPATH=`pwd`
ARCHS="i386 armv6 armv7"


##########
set -e
if [ ! -e ${FILE} ]; then
	echo "Downloading ${FILE}"
    curl -O http://www.tcpdump.org/release/${FILE}
else
	echo "Using ${FILE}"
fi

mkdir -p bin
mkdir -p lib
mkdir -p src

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi

	tar zxvf ${FILE} -C src
	cd src/libpcap-${VERSION}
	
	echo "Building libpcap for ${PLATFORM} ${SDKVERSION} ${ARCH}"

	echo "Please stand by..."

	export DEVROOT="/Developer/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
	export CC=${DEVROOT}/usr/bin/gcc
	export LD=${DEVROOT}/usr/bin/ld
	export CPP=${DEVROOT}/usr/bin/cpp
	export CXX=${DEVROOT}/usr/bin/g++
	export AR=${DEVROOT}/usr/bin/ar
	export AS=${DEVROOT}/usr/bin/as
	export NM=${DEVROOT}/usr/bin/nm
	export CXXCPP=$DEVROOT/usr/bin/cpp
	export RANLIB=$DEVROOT/usr/bin/ranlib
	export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -L${CURRENTPATH}/lib"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include"
	export CXXFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include"

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-libpcap-${VERSION}.log"

	./configure --host=${ARCH}-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --enable-shared=no --with-pcap=null --enable-ipv6 >> "${LOG}" 2>&1

	make >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	cd ${CURRENTPATH}
	rm -rf src/libpcap-${VERSION}
	
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libpcap.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/lib/libpcap.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libpcap.a -output ${CURRENTPATH}/lib/libpcap.a

lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libpcap.1.1.1.dylib ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/lib/libpcap.1.1.1.dylib ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libpcap.1.1.1.dylib -output ${CURRENTPATH}/lib/libpcap.1.1.1.dylib

echo "Copying Headers..."
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/pcap ${CURRENTPATH}/include/
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/pcap-bpf.h ${CURRENTPATH}/include/
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/pcap-namedb.h ${CURRENTPATH}/include/
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/pcap.h ${CURRENTPATH}/include/

echo "Building done."
