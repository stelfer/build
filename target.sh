#!/bin/bash
#
# Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt
#
#
set -ue

CLANG=./clang/bin/clang
GDBSERVER=./gdbserver
SRC=$@
EXE=$(basename $1 .ll)
OUT=$EXE.xml
LIBSUP=$(ls /usr/lib/gcc/$(gcc -dumpmachine)/*/libsupc++.a | sort -nr | head -1)
DIR=$(dirname $0)
TEST_DIR=test

function finish {
    rm $SRC
    rm target.sh
}
    
trap finish EXIT

cd $DIR

rm -rf $TEST_DIR

export LD_LIBRARY_PATH=clang/lib
$CLANG -o $EXE $TARGET_LDFLAGS $SRC $LIBSUP 
case $TARGET_MODE in
    run)
	./$EXE --gtest_output=xml:$OUT
	;;
    debug*)
	$GDBSERVER - ./$EXE
	;;
    valgrind)
	./valgrind/bin/valgrind --tool=memcheck --leak-check=full ./$EXE
	;;
    *)
	echo "Error: Bad TARGET_MODE, should never reach here"
	exit 1
	;;
esac
