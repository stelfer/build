#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GTEST_VER		:= 1.7.0
GTEST			:= gtest-$(GTEST_VER)
$(GTEST)_ARCHIVE 	:= $(GTEST).zip
$($(GTEST)_ARCHIVE)_URL := https://googletest.googlecode.com/files/$($(GTEST)_ARCHIVE)
$(GTEST)_UNARCHIVE_CMD 	:= unzip $($(GTEST)_ARCHIVE)


include build/$(GTEST)/.gtest_install
include build/$(GTEST)/.unpack

build/$(GTEST)/.gtest_install:
	mkdir -p build/include build/lib
	cp -an build/$(GTEST)/include/gtest build/include
	$(CXX) $(CXXSTD) $(CXXINCLUDES) -Ibuild/$(GTEST) -c -o build/lib/libgtest.o build/$(GTEST)/src/gtest-all.cc
	ar -rv build/lib/libgtest.a build/lib/libgtest.o
	touch $@

GTEST_LIBS		:= -lpthread -lgtest
