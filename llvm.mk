#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

BUILD_LLDB		?= no

LLVM_VER		:= 3.7.0
LLVM			:= llvm-$(LLVM_VER)
$(LLVM)_ARCHIVE 	:= $(LLVM).src.tar.xz
$($(LLVM)_ARCHIVE)_URL 	:= http://llvm.org/releases/$(LLVM_VER)/$($(LLVM)_ARCHIVE)
$(LLVM)_UNARCHIVE_CMD 	:= tar -J -xf $($(LLVM)_ARCHIVE) -C $(LLVM) --strip-components=1

CLANG			:= $(LLVM)/tools/clang
$(CLANG)_ARCHIVE	:= cfe-$(LLVM_VER).src.tar.xz
$($(CLANG)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(CLANG)_ARCHIVE)
$(CLANG)_UNARCHIVE_CMD 	:= tar -J -xf $($(CLANG)_ARCHIVE) -C $(CLANG) --strip-components=1

ifeq ($(BUILD_LLDB),yes)
LLDB			:= $(LLVM)/tools/lldb
$(LLDB)_ARCHIVE	:= lldb-$(LLVM_VER).src.tar.xz
$($(LLDB)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LLDB)_ARCHIVE)
$(LLDB)_UNARCHIVE_CMD 	:= tar -J -xf $($(LLDB)_ARCHIVE) -C $(LLDB) --strip-components=1
LLDB_UNPACK		:= build/$(LLDB)/.unpack

COMPILER_VER		:= $(LLVM)

# lldb requires libedit
include $(BUILD)/libedit.mk
endif

COMPILER_RT			:= $(LLVM)/projects/compiler-rt
$(COMPILER_RT)_ARCHIVE		:= compiler-rt-$(LLVM_VER).src.tar.xz
$($(COMPILER_RT)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(COMPILER_RT)_ARCHIVE)
$(COMPILER_RT)_UNARCHIVE_CMD 	:= tar -J -xf $($(COMPILER_RT)_ARCHIVE) -C $(COMPILER_RT) --strip-components=1

LIBCXX				:= $(LLVM)/projects/libcxx
$(LIBCXX)_ARCHIVE		:= libcxx-$(LLVM_VER).src.tar.xz
$($(LIBCXX)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LIBCXX)_ARCHIVE)
$(LIBCXX)_UNARCHIVE_CMD 	:= tar -J -xf $($(LIBCXX)_ARCHIVE) -C $(LIBCXX) --strip-components=1

LIBCXXABI			:= $(LLVM)/projects/libcxxabi
$(LIBCXXABI)_ARCHIVE		:= libcxxabi-$(LLVM_VER).src.tar.xz
$($(LIBCXXABI)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LIBCXXABI)_ARCHIVE)
$(LIBCXXABI)_UNARCHIVE_CMD 	:= tar -J -xf $($(LIBCXXABI)_ARCHIVE) -C $(LIBCXXABI) --strip-components=1

EXTRA			:= $(LLVM)/tools/clang/tools/extra
$(EXTRA)_ARCHIVE	:= clang-tools-extra-$(LLVM_VER).src.tar.xz
$($(EXTRA)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(EXTRA)_ARCHIVE)
$(EXTRA)_UNARCHIVE_CMD 	:= tar -J -xf $($(EXTRA)_ARCHIVE) -C $(EXTRA) --strip-components=1

include build/$(LLVM)/.build/.install

build/$(LLVM)/.build/.install: | build/$(LLVM)/.build/.configure
	mkdir -p $(@D)
	cd $(@D);\
	cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo 			\
		 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_VERBOSE_MAKEFILE=ON 	\
		 -DCMAKE_INSTALL_PREFIX=$(PWD)/build 			\
		 -DLLVM_ENABLE_ASSERTIONS=On 				\
		 -DLLVM_TARGETS_TO_BUILD="X86"				\
		 -DCMAKE_CXX_FLAGS=-I$(PWD)/build/include 		\
		 -DCMAKE_LIBRARY_PATH=-$(PWD)/build/lib;		\
	make -j8 install
	touch $@

build/$(LLVM)/.build/.configure : |					\
			$(LIBEDIT_INSTALL)				\
			build/$(LLVM)/.unpack 				\
			build/$(LLVM)/projects/compiler-rt/.unpack	\
			build/$(LLVM)/tools/clang/.unpack		\
			$(LLDB_UNPACK)					\
			build/$(LLVM)/tools/clang/tools/extra/.unpack	\
			build/$(LLVM)/projects/libcxx/.unpack		\
			build/$(LLVM)/projects/libcxxabi/.unpack


CC			:= build/bin/clang
CXX			:= build/bin/clang++
CXXWARN			:= -Wall -Werror
CXXDIAG			:= -ferror-limit=2 -fdiagnostics-show-template-tree
CXXDEBUG		:= -ggdb3
CXXINLINES		:= -include build/include/config.h

ifeq ($(OPT),yes)
CXXOPT			:= -O3
endif

CXXFLAGS		:= $(CXXWARN) $(CXXDIAG) $(CXXDEBUG) $(CXXOPT) $(CXXINLINES)
CXXINCLUDES		:= -Ibuild/include/c++/v1 -Ibuild/include
CXXSTD			:= -std=c++14 -stdlib=libc++ 
LDFLAGS			 = -Wl,-duse-ld=gold -Wl,-Map,$@.map -Wl,-demangle
DEPFLAGS 	 	 = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td
COMPILE 		 = $(CXX) $(CXXFLAGS) $(CXXSTD) $(CXXINCLUDES) $(DEPFLAGS)
LINK			 = $(CXX) $(CXXSTD) $(LDFLAGS) -Lbuild/lib -lc++ -lc++abi
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
