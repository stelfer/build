#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GTEST_VER		:= 1.7.0
GTEST			:= gtest-$(GTEST_VER)
GTEST_UNPACK		:= $(OPTDIR)/$(GTEST)/.unpack
GTEST_INSTALL		:= $(OPTDIR)/$(GTEST)/.install
$(GTEST)_ARCHIVE 	:= $(GTEST).zip
$($(GTEST)_ARCHIVE)_URL := https://googletest.googlecode.com/files/$($(GTEST)_ARCHIVE)
$(GTEST_UNPACK) 	: $(DOWNLOADS)/$($(GTEST)_ARCHIVE)

include $(GTEST_INSTALL)

$(GTEST_INSTALL): | $(OPTDIR)/$(LLVM)/.build/.install $(GTEST_UNPACK)
	mkdir -p build/include $(LIBDIR)
	cp -af $(OPTDIR)/$(GTEST)/include/gtest $(INCLUDEDIR)
	$(CXX) $(CXXSTD) $(CXXINCLUDES) -I$(OPTDIR)/$(GTEST) -c -o $(LIBDIR)/libgtest.o $(OPTDIR)/$(GTEST)/src/gtest-all.cc
	ar -rv $(LIBDIR)/libgtest.a $(LIBDIR)/libgtest.o
	touch $@


GTEST_LIBS		:= -lpthread -lgtest
