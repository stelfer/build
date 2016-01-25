#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

BUILD_LLDB		?= no

LLVM_VER		:= 3.7.0
LLVM			:= llvm-$(LLVM_VER)
$(LLVM)_ARCHIVE 	:= $(LLVM).src.tar.xz
$($(LLVM)_ARCHIVE)_URL 	:= http://llvm.org/releases/$(LLVM_VER)/$($(LLVM)_ARCHIVE)

CLANG			:= $(LLVM)/tools/clang
$(CLANG)_ARCHIVE	:= cfe-$(LLVM_VER).src.tar.xz
$($(CLANG)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(CLANG)_ARCHIVE)

ifeq ($(BUILD_LLDB),yes)
LLDB			:= $(LLVM)/tools/lldb
$(LLDB)_ARCHIVE	:= lldb-$(LLVM_VER).src.tar.xz
$($(LLDB)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LLDB)_ARCHIVE)
LLDB_UNPACK		:= $(OPTDIR)/$(LLDB)/.unpack

COMPILER_VER		:= $(LLVM)

# lldb requires libedit
include $(BUILD)/libedit.mk
endif

COMPILER_RT			:= $(LLVM)/projects/compiler-rt
$(COMPILER_RT)_ARCHIVE		:= compiler-rt-$(LLVM_VER).src.tar.xz
$($(COMPILER_RT)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(COMPILER_RT)_ARCHIVE)

LIBCXX				:= $(LLVM)/projects/libcxx
$(LIBCXX)_ARCHIVE		:= libcxx-$(LLVM_VER).src.tar.xz
$($(LIBCXX)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LIBCXX)_ARCHIVE)

LIBCXXABI			:= $(LLVM)/projects/libcxxabi
$(LIBCXXABI)_ARCHIVE		:= libcxxabi-$(LLVM_VER).src.tar.xz
$($(LIBCXXABI)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LIBCXXABI)_ARCHIVE)

EXTRA			:= $(LLVM)/tools/clang/tools/extra
$(EXTRA)_ARCHIVE	:= clang-tools-extra-$(LLVM_VER).src.tar.xz
$($(EXTRA)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(EXTRA)_ARCHIVE)

include $(OPTDIR)/$(LLVM)/.build/.install

$(OPTDIR)/$(LLVM)/.build/.install: | $(OPTDIR)/$(LLVM)/.build/.configure
	mkdir -p $(@D)
	cd $(@D);\
	cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo 			\
		 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_VERBOSE_MAKEFILE=ON 	\
		 -DCMAKE_INSTALL_PREFIX=$(PWD)/$(BUILD)			\
		 -DLLVM_ENABLE_ASSERTIONS=On 				\
		 -DLLVM_TARGETS_TO_BUILD="X86"				\
		 -DCMAKE_CXX_FLAGS=-I$(PWD)/$(INCLUDEDIR) 		\
		 -DCMAKE_LIBRARY_PATH=-$(PWD)/$(LIBDIR);		\
	$(MAKE) install
	touch $@

$(OPTDIR)/$(LLVM)/.build/.configure : |					\
			$(LIBEDIT_INSTALL)				\
			$(OPTDIR)/$(LLVM)/.unpack 				\
			$(OPTDIR)/$(LLVM)/projects/compiler-rt/.unpack	\
			$(OPTDIR)/$(LLVM)/tools/clang/.unpack		\
			$(LLDB_UNPACK)					\
			$(OPTDIR)/$(LLVM)/tools/clang/tools/extra/.unpack	\
			$(OPTDIR)/$(LLVM)/projects/libcxx/.unpack		\
			$(OPTDIR)/$(LLVM)/projects/libcxxabi/.unpack


CC			:= $(BINDIR)/clang
CXX			:= $(BINDIR)/clang++
CXXWARN			:= -Wall -Werror
CXXDIAG			:= -ferror-limit=2 -fdiagnostics-show-template-tree
CXXDEBUG		:= -ggdb3
CXXINLINES		:= -include $(INCLUDEDIR)/config.h

ifeq ($(OPT),yes)
CXXOPT			:= -O3
endif

CXXFLAGS		:= $(CXXWARN) $(CXXDIAG) $(CXXDEBUG) $(CXXOPT) $(CXXINLINES)
CXXINCLUDES		:= -I$(INCLUDEDIR)/c++/v1 -I$(INCLUDEDIR)
CXXSTD			:= -std=c++14 -stdlib=libc++ 
LDFLAGS			 = -Wl,-duse-ld=gold -Wl,-Map,$@.map -Wl,-demangle
DEPFLAGS 	 	 = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td
COMPILE 		 = $(CXX) $(CXXFLAGS) $(CXXSTD) $(CXXINCLUDES) $(DEPFLAGS)
LINK			 = $(CXX) $(CXXSTD) $(LDFLAGS) -L$(LIBDIR) -lc++ -lc++abi
POSTCOMPILE 	 	 = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@


define header_command 	 =

{
	"directory" : "$(PWD)",
	"command" : "$(CXX) -x c++ -fsyntax-only $(CXXFLAGS) $(CXXSTD) $(CXXINCLUDES) $(1)",
	"file" : "$(1)"
},
endef

define tgt_command 	 =

{
	"directory" : "$(PWD)",
	"command" : "$(COMPILE) -c -o $@ $<",
	"file" : "$<"
}
endef

# Build the $@.json compile_command file for clang ast parsing tools
PRECOMPILE	 	 = $(file >$@.json,					\
				[$(foreach x,$(filter build/%.h,$^),		\
				$(call header_command,$(x)))$(tgt_command)])
