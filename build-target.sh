#!/bin/bash

#
# This is the beginnings of a script to make the remote target environment
#
set -uex

mkdir -p /tmp/build
cd /tmp/build

D=~/build-centos-7.2-3.9.0-x86_64

mkdir -p $D


if [ ! -f cmake.sh ]
then
    curl -o cmake.sh wget https://cmake.org/files/v3.6/cmake-3.6.2-Linux-x86_64.sh
fi

if [ ! -f $D/bin/cmake ]
then
    echo "y" | sh ./cmake.sh --prefix=$D --exclude-subdir
fi

mkdir -p llvm-build

cd llvm-build
$D/bin/cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$D ../llvm-3.9.0
make -j64 install





