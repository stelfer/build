#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

#http://www.netgull.com/gcc/releases/gcc-5.2.0/gcc-5.2.0.tar.gz
#http://mirrors.kernel.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.gz

GCC_VER			:= 5.2.0
GCC			:= gcc-$(GCC_VER)
$(GCC)_ARCHIVE 		:= $(GCC).tar.gz
$($(GCC)_ARCHIVE)_URL 	:= http://mirrors.kernel.org/gnu/gcc/$(GCC)/$($(GCC)_ARCHIVE)

COMPILER_VER		:= $(GCC)

include $(OPTDIR)/$(GCC)/.build/.install

$(OPTDIR)/$(GCC)/.build/.install: | $(OPTDIR)/$(GCC)/.build/.configure
	mkdir -p $(@D)
	cd $(@D)/.. && 	./contrib/download_prerequisites
	cd $(@D);\
	../configure --prefix=$(PWD)/$(BUILD) --enable-languages=c,c++ --disable-multilib;\
	$(MAKE) -j;\
	$(MAKE) install
	touch $@

$(OPTDIR)/$(GCC)/.build/.configure : | $(OPTDIR)/$(GCC)/.unpack


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
CXXINLINES		:= -include $(INCLUDEDIR)/config.h

ifeq ($(OPT),yes)
CXXOPT			:= -O3
endif

CXXFLAGS		:= $(CXXWARN) $(CXXDIAG) $(CXXDEBUG) $(CXXOPT) $(CXXINLINES)
CXXINCLUDES		:= -I$(INCLUDEDIR)
CXXSTD			:= -std=gnu++14
LDFLAGS			 = -Wl,-duse-ld=gold -Wl,-Map,$@.map -Wl,-demangle
DEPFLAGS 	 	 = -MT $@ -MD -MF $(DEPDIR)/$*.Td
COMPILE 		 = $(CXX) $(CXXFLAGS) $(CXXSTD) $(CXXINCLUDES) $(DEPFLAGS)
LINK			 = $(CXX) $(CXXDIAG) $(CXXSTD) $(LDFLAGS) -L$(LIBDIR)
POSTCOMPILE 	 	 = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@




