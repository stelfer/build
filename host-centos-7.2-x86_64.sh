# Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt

set -ue

# This creates the file host-centos-7.2-x86_64.tar.xz, which pairs with
# target-centos-7.2-x86_64.tar.xz, which contains the binaries necessary on the target side in roder
# to build

ID="host-centos-7.2-x86_64"

CORE_URL="http://mirror.centos.org/centos/7/updates/x86_64/Packages/"
GLIBC_DEVEL=$CORE_URL"glibc-devel-2.17-106.el7_2.8.x86_64.rpm"
GLIBC_HEADERS=$CORE_URL"glibc-headers-2.17-106.el7_2.8.x86_64.rpm"
KERNEL_HEADERS=$CORE_URL"kernel-headers-3.10.0-327.36.3.el7.x86_64.rpm"

LIBNL="libnl-3.2.25.tar.gz"
LIBNL_URL="http://www.infradead.org/~tgr/libnl/files/$LIBNL"

RPMS="$GLIBC_DEVEL $GLIBC_HEADERS $KERNEL_HEADERS"

mkdir -p /tmp/$ID

cd /tmp/$ID

rm -rf usr

for r in $RPMS; do
    wget -nc $r
done

for r in *.rpm; do
    rpm2cpio $r | cpio -dium
done

wget -nc $LIBNL_URL

tar zxf $LIBNL

mkdir usr/include/libnl3
cp -a libnl-3.2.25/include/netlink usr/include/libnl3

rm -rf $ID
mkdir -p $ID

cp -a usr/include/* $ID
tar -Jcf $ID.tar.xz $ID

