#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

#http://www.netgull.com/gcc/releases/gcc-5.2.0/gcc-5.2.0.tar.gz
#http://mirrors.kernel.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.gz

GCC_VER			:= 5.2.0
GCC			:= gcc-$(GCC_VER)
$(GCC)_ARCHIVE 		:= $(GCC).tar.gz
$($(GCC)_ARCHIVE)_URL 	:= http://mirrors.kernel.org/gnu/gcc/$(GCC)/$($(GCC)_ARCHIVE)
$(GCC)_UNARCHIVE_CMD 	:= tar -z -xf $($(GCC)_ARCHIVE) -C $(GCC) --strip-components=1

COMPILER_VER		:= $(GCC)

include build/$(GCC)/.build/.install

build/$(GCC)/.build/.install: | build/$(GCC)/.build/.configure
	mkdir -p $(@D)
	cd $(@D)/.. && 	./contrib/download_prerequisites
	cd $(@D);\
	../configure --prefix=$(PWD)/build/ --enable-languages=c,c++ --disable-multilib;\
	$(MAKE) -j;\
	$(MAKE) install
	touch $@

build/$(GCC)/.build/.configure : | build/$(GCC)/.unpack


CC			:= gcc
CXX			:= g++
CXXWARN			:= -Wall -Werror -Wextra -Wformat=2
CXXDIAG			:= -fdiagnostics-color 		\
			   -ftemplate-backtrace-limit=0	\
			   -fmessage-length=0		\
			   -fmax-errors=2		\
			   -Wno-format-nonliteral	\
			   -Wno-sign-compare

CXXDEBUG		:= -ggdb3
CXXINLINES		:= -include build/include/config.h

ifeq ($(OPT),yes)
CXXOPT			:= -O3
endif

CXXFLAGS		:= $(CXXWARN) $(CXXDIAG) $(CXXDEBUG) $(CXXOPT) $(CXXINLINES)
CXXINCLUDES		:= -Ibuild/include
CXXSTD			:= -std=gnu++14
LDFLAGS			 = -Wl,-duse-ld=gold -Wl,-Map,$@.map -Wl,-demangle
DEPFLAGS 	 	 = -MT $@ -MD -MF $(DEPDIR)/$*.Td
COMPILE 		 = $(CXX) $(CXXFLAGS) $(CXXSTD) $(CXXINCLUDES) $(DEPFLAGS)
LINK			 = $(CXX) $(CXXDIAG) $(CXXSTD) $(LDFLAGS) -Lbuild/lib
POSTCOMPILE 	 	 = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@




