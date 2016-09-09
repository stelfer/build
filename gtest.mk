#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GTEST_VER		:= 1.8.0
GTEST			:= gtest-$(GTEST_VER)
GTEST_UNPACK		:= $(OPTDIR)/$(GTEST)/.unpack
GTEST_INSTALL		:= $(OPTDIR)/$(GTEST)/.install
$(GTEST)_ARCHIVE 	:= release-$(GTEST_VER).tar.gz
$($(GTEST)_ARCHIVE)_URL := https://codeload.github.com/google/googletest/tar.gz/release-$(GTEST_VER)
$(GTEST_UNPACK) 	: $(DOWNLOADS)/$($(GTEST)_ARCHIVE)

include $(GTEST_INSTALL)

$(GTEST_INSTALL): | $(OPTDIR)/$(LLVM)/.build/.install $(GTEST_UNPACK)
	mkdir -p build/include $(LIBDIR)
	cp -af $(OPTDIR)/$(GTEST)/googletest/include/gtest $(INCLUDEDIR)
	$(CXX) $(CXXSTD) $(CXXINCLUDES) -I$(OPTDIR)/$(GTEST)/googletest -c -o $(LIBDIR)/libgtest.o $(OPTDIR)/$(GTEST)/googletest/src/gtest-all.cc
	ar -rv $(LIBDIR)/libgtest.a $(LIBDIR)/libgtest.o
	$(LLVM_BC_COMPILE_CXX) -I$(OPTDIR)/$(GTEST)/googletest -c -o $(LIBDIR)/gtest.bc $(OPTDIR)/$(GTEST)/googletest/src/gtest-all.cc
	touch $@


GTEST_LIBS		:= -lpthread -lgtest
