#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GTEST_VER		:= 1.7.0
GTEST			:= gtest-$(GTEST_VER)
$(GTEST)_ARCHIVE 	:= $(GTEST).zip
$($(GTEST)_ARCHIVE)_URL := https://googletest.googlecode.com/files/$($(GTEST)_ARCHIVE)

include $(OPTDIR)/$(GTEST)/.gtest_install
include $(OPTDIR)/$(GTEST)/.unpack

$(OPTDIR)/$(GTEST)/.gtest_install: | $(OPTDIR)/$(LLVM)/.build/.install
	mkdir -p build/include $(LIBDIR)
	cp -an $(OPTDIR)/$(GTEST)/include/gtest $(INCLUDEDIR)
	$(CXX) $(CXXSTD) $(CXXINCLUDES) -I$(OPTDIR)/$(GTEST) -c -o $(LIBDIR)/libgtest.o $(OPTDIR)/$(GTEST)/src/gtest-all.cc
	ar -rv $(LIBDIR)/libgtest.a $(LIBDIR)/libgtest.o
	touch $@

GTEST_LIBS		:= -lpthread -lgtest
