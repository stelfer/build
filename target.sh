#!/bin/bash
#
# Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt
#
#
set -uex

# The host selects the target dir, a sha1 of the target .ll file. This way we don't have collisions
# between different builds on the same machine
BUILD=$PWD/$(dirname $0)

ROOT=$BUILD/../..
LIB_ROOT=$ROOT/target
CLANG=$LIB_ROOT/bin/clang
GDBSERVER=$LIB_ROOT/bin/gdbserver

# The actual target to build
TARGET=$(basename $1 .ll)

# All output is sent here
OUT=$TARGET.xml

# Static libstdc++ for linking locally, assumes it is installed
LIBSUP=$(ls /usr/lib/gcc/$(gcc -dumpmachine)/*/libsupc++.a | sort -nr | head -1)

export LD_LIBRARY_PATH=$LIB_ROOT/lib

function finish {
    rm target.sh
}

function compile {
    cd $BUILD
    $CLANG -o $TARGET $TARGET_LDFLAGS $@ $LIBSUP 
}

function run {
    case $TARGET_MODE in
	run)
	    ./$TARGET --gtest_output=xml:$OUT
	    ;;
	debug*)
	    $GDBSERVER - ./$TARGET
	    ;;
	valgrind)
	    ./valgrind/bin/valgrind --tool=memcheck --leak-check=full ./$TARGET
	    ;;
	*)
	    echo "Error: Bad TARGET_MODE, should never reach here"
	    exit 1
	    ;;
    esac
}

#
# Take care of business
#
trap finish EXIT
compile $@
run

