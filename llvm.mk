#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

COMPILER_VER			:= $(LLVM)

BUILD_LLDB			?= no

LLVM_VER			:= 3.7.0
LLVM				:= llvm-$(LLVM_VER)
LLVM_UNPACK			:= $(OPTDIR)/$(LLVM)/.unpack
LLVM_INSTALL			:= $(OPTDIR)/$(LLVM)/.build/.install
$(LLVM)_ARCHIVE 		:= $(LLVM).src.tar.xz
$($(LLVM)_ARCHIVE)_URL 		:= http://llvm.org/releases/$(LLVM_VER)/$($(LLVM)_ARCHIVE)
$(LLVM_UNPACK)			: $(DOWNLOADS)/$($(LLVM)_ARCHIVE)

CLANG				:= $(LLVM)/tools/clang
CLANG_UNPACK			:= $(OPTDIR)/$(LLVM)/tools/clang/.unpack
$(CLANG)_ARCHIVE		:= cfe-$(LLVM_VER).src.tar.xz
$($(CLANG)_ARCHIVE)_URL		:= http://llvm.org/releases/$(LLVM_VER)/$($(CLANG)_ARCHIVE)
$(CLANG_UNPACK)			: $(DOWNLOADS)/$($(CLANG)_ARCHIVE)

ifeq ($(BUILD_LLDB),yes)
LLDB				:= $(LLVM)/tools/lldb
LLDB_UNPACK			:= $(OPTDIR)/$(LLDB)/.unpack
$(LLDB)_ARCHIVE			:= lldb-$(LLVM_VER).src.tar.xz
$($(LLDB)_ARCHIVE)_URL		:= http://llvm.org/releases/$(LLVM_VER)/$($(LLDB)_ARCHIVE)
$(LLDB_UNPACK)			: $(DOWNLOADS)/$($(LLDB)_ARCHIVE)
endif

COMPILER_RT			:= $(LLVM)/projects/compiler-rt
COMPILER_RT_UNPACK		:= $(OPTDIR)/$(LLVM)/projects/compiler-rt/.unpack
$(COMPILER_RT)_ARCHIVE		:= compiler-rt-$(LLVM_VER).src.tar.xz
$($(COMPILER_RT)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(COMPILER_RT)_ARCHIVE)
$(COMPILER_RT_UNPACK)		: $(DOWNLOADS)/$($(COMPILER_RT)_ARCHIVE)

LIBCXX				:= $(LLVM)/projects/libcxx
LIBCXX_UNPACK			:= $(OPTDIR)/$(LLVM)/projects/libcxx/.unpack
$(LIBCXX)_ARCHIVE		:= libcxx-$(LLVM_VER).src.tar.xz
$($(LIBCXX)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LIBCXX)_ARCHIVE)
$(LIBCXX_UNPACK)		: $(DOWNLOADS)/$($(LIBCXX)_ARCHIVE)

LIBCXXABI			:= $(LLVM)/projects/libcxxabi
LIBCXXABI_UNPACK		:= $(OPTDIR)/$(LLVM)/projects/libcxxabi/.unpack
$(LIBCXXABI)_ARCHIVE		:= libcxxabi-$(LLVM_VER).src.tar.xz
$($(LIBCXXABI)_ARCHIVE)_URL	:= http://llvm.org/releases/$(LLVM_VER)/$($(LIBCXXABI)_ARCHIVE)
$(LIBCXXABI_UNPACK)		: $(DOWNLOADS)/$($(LIBCXXABI)_ARCHIVE)

EXTRA				:= $(LLVM)/tools/clang/tools/extra
EXTRA_UNPACK			:= $(OPTDIR)/$(LLVM)/tools/clang/tools/extra/.unpack
$(EXTRA)_ARCHIVE		:= clang-tools-extra-$(LLVM_VER).src.tar.xz
$($(EXTRA)_ARCHIVE)_URL		:= http://llvm.org/releases/$(LLVM_VER)/$($(EXTRA)_ARCHIVE)
$(EXTRA_UNPACK)			: $(DOWNLOADS)/$($(EXTRA)_ARCHIVE)

ifeq ($(BUILD_LLDB),yes)
# lldb requires libedit
include $(BUILD)/libedit.mk
endif

# Use gnu gold built for this
include $(BUILD)/gold.mk

include $(LLVM_INSTALL)

$(OPTDIR)/$(LLVM)/.build/.install: | $(OPTDIR)/$(LLVM)/.build/.configure
	mkdir -p $(@D)
	cd $(@D);\
	cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo 			\
		 -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_VERBOSE_MAKEFILE=ON 	\
		 -DCMAKE_INSTALL_PREFIX=$(PWD)/$(BUILD)			\
		 -DLLVM_ENABLE_ASSERTIONS=On 				\
		 -DLLVM_TARGETS_TO_BUILD="X86"				\
		 -DLLVM_BINUTILS_INCDIR=$(PWD)/$(GOLD_INCLUDEDIR)	\
		 -DCMAKE_CXX_FLAGS=-I$(PWD)/$(INCLUDEDIR) 		\
		 -DCMAKE_LIBRARY_PATH=-$(PWD)/$(LIBDIR);		\
	$(MAKE) install
	touch $@

$(OPTDIR)/$(LLVM)/.build/.configure : |		\
			$(GOLD_INSTALL)		\
			$(LIBEDIT_INSTALL)	\
			$(LLVM_UNPACK) 		\
			$(COMPILER_RT_UNPACK)	\
			$(CLANG_UNPACK)		\
			$(LLDB_UNPACK)		\
			$(EXTRA_UNPACK)		\
			$(LIBCXX_UNPACK)	\
			$(LIBCXXABI_UNPACK)


CC			:= $(BINDIR)/clang
CCARCH			:= -match=native -mtune=native
CCWARN			:= -Wall -Werror -Wextra -pedantic -Wno-language-extension-token
CCDIAG			:= -ferror-limit=2
CCFLAGS			:= $(CCWARN) $(CCDIAG)
CCSTD			:= -std=gnu99 -x c
CCINCLUDES		:= -I$(INCLUDEDIR)
COMPILE_CC		:= $(CC) $(CCARCH) $(CCFLAGS) $(CCINCLUDES) $(DEPFLAGS)


CXX			:= $(BINDIR)/clang++
CCARCH			:= $(CCARCH)
CXXWARN			:= $(CCWARN)
CXXDIAG			:= -ferror-limit=2 -fdiagnostics-show-template-tree
CXXDEBUG		:= -ggdb3
CXXINLINES		:= -include $(INCLUDEDIR)/config.h

ifeq ($(OPT),yes)
CXXOPT			:= -O3
endif

CXXFLTO			:= -flto
CXXFLAGS		:= $(CXXWARN) $(CXXDIAG) $(CXXDEBUG) $(CXXOPT) $(CXXINLINES) $(CXXFLTO)
CXXINCLUDES		:= -I$(INCLUDEDIR)/c++/v1 -I$(INCLUDEDIR)
CXXSTD			:= -std=c++14 -stdlib=libc++ -x c++
COMPILE_CXX 		 = $(CXX) $(CXXFLAGS) $(CXXSTD) $(CXXINCLUDES)

LDFLAGS			 = -use-gold-plugin -Wl,-duse-ld=gold -Wl,-Map,$@.map -Wl,-demangle
DEPFLAGS 	 	 = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td
LINK			 = $(CXX) -B$(BUILD) $(CXXSTD) $(LDFLAGS) -L$(LIBDIR) -lc++ -lc++abi $(CXXFLTO)

COMPILE_COMMANDS	:= $(BUILD)/compile_commands.json
POSTCOMPILE_DEP		 = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@
POSTCOMPILE_CMD		 = ./build/build_compile_commands.py \
				$(COMPILE_COMMANDS) $@.json && rm $@.json
POSTCOMPILE 	 	 = $(POSTCOMPILE_DEP) ; $(POSTCOMPILE_CMD)

define emit_compile_command

{
	"directory" : "$(PWD)",
	"command" : "$(1) $(2)",
	"file" : "$(2)"
}
endef

PRECOMPILE_DEP 		 = $(shell mkdir -p $(@D) $(dir $(DEPDIR)/$*.Td))


# Build the $@.json compile_command file for clang ast parsing tools
PRECOMPILE_CMD	 	 = $(file >$@.json,						\
				[$(foreach x,$(filter build/%.h,$^),			\
				$(call emit_compile_command,$(1) -fsyntax-only,$(x)),)	\
				$(call emit_compile_command,$(1) -o $@ -c     ,$(2))])



