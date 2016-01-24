#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

PWD		:= $(shell pwd -P)
PROJECT		?= $(notdir $(PWD))
DEPDIR 		:= build/deps
DEPS		!= find $(DEPDIR) -name \*.d
COMPILE_CMDS	!= find build -name \*.o.json
TEST_SOURCES	!= find test -name \*.cpp
TESTS		:= $(patsubst %.cpp,build/%,$(TEST_SOURCES))
UNAME 		!= uname -rs
SYSNAME		:= $(firstword $(UNAME))
REL 		:= $(lastword $(UNAME))
OPT		?= yes
BUILD		:= build
COMPILER	?= LLVM
INSTALL_RTAGS	?= yes



.PHONY: ALL
all: ALL

# This makes sure that the includes are linked correctly
include build/include/$(PROJECT)/.link

# Compiler specific stuff
ifeq ($(COMPILER),LLVM)
include $(BUILD)/llvm.mk
else ifeq ($(COMPILER),GCC)
include $(BUILD)/gcc.mk
endif

# Rtags
ifeq ($(INSTALL_RTAGS),yes)
include $(BUILD)/rtags.mk
endif

# Gtest stuff
include $(BUILD)/gtest.mk


# We only need to include the system mk file if the config.h doesn't exist
ifeq ($(wildcard build/include/config.h),)
include $(BUILD)/$(SYSNAME).mk
include $(BUILD)/config.mk
endif

BIN 		 = build/bin/hello

ALL: $(BIN)

# BIN have order-only prereqs for test.. everything always has to test clean
$(BIN) : | $(TESTS) $(LIBS)

#
# Targets to build everything
#

build/% : build/%.o
	mkdir -p $(@D)
	$(LINK) -o $@ $^

.PRECIOUS: $(DEPDIR)/%.d build/%.o.json
build/%.o : %.cpp $(DEPDIR)/%.d build/%.o.json | build/include/config.h
	$(PRECOMPILE)
	mkdir -p $(@D) $(dir $(DEPDIR)/$*.Td)
	$(COMPILE) -c -o $@ $<
	$(POSTCOMPILE)

build/%.o.json:
	mkdir -p $(@D)

build/compile_commands.json: $(COMPILE_CMDS)
	python $(BUILD)/build_compile_commands.py $@ $^

build/%.a :
	ar rcs $@ $^

build/test/% : build/test/%.o
	mkdir -p $(@D)
	$(LINK) -o $@.fail $^ $(GTEST_LIBS)
	LD_LIBRARY_PATH=build/lib $@.fail --gtest_output=xml:$(@D)/
	python $(BUILD)/parse_perf_tests.py $@.xml
	mv $@.fail $@

foofofof:
	mv $< $@

#
# The rest of this used to auto-install packages. See llvm.mk and gtest.mk for examples of how to
# use
#
build/%/.unpack :
	echo $*
	mkdir -p build
	cd build ;\
	if [ ! -f $($(*)_ARCHIVE) ]; then\
		curl -o $($(*)_ARCHIVE) $($($(*)_ARCHIVE)_URL);\
	fi;\
	mkdir -p $*;\
	$($(*)_UNARCHIVE_CMD)
	touch $@

build/include/$(PROJECT)/.link:
	mkdir -p build/include
	ln -sf ../../include build/include/$(PROJECT)
	touch $@


clean:
	rm -rf build/$(PROJECT) build/test build/deps $(LIBS) $(BIN)


.PHONY: check-syntax
check-syntax:
	$(COMPILE) -fsyntax-only $(CHK_SOURCES)


$(DEPDIR)/%.d: ;

include $(DEPS)
