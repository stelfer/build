#!/bin/bash

set -ue


DIR=$(dirname $0)
cd $DIR

CLANG=./clang/bin/clang
OUT=test.$$
SRC=$1
function finish {
    rm $OUT
    rm $SRC
    rm target.sh
    rm parse_perf_tests.py
}

LIBSUP=$(ls /usr/lib/gcc/x86_64-redhat-linux/*/libsupc++.a | sort -nr | head -1)
    
trap finish EXIT

$CLANG -o $OUT -Wno-override-module -Lclang/lib -lpthread -lc++abi -lc++ $SRC $LIBSUP
LD_LIBRARY_PATH=clang/lib ./$OUT --gtest_output=xml:$SRC.xml
python ./parse_perf_tests.py $SRC.xml

