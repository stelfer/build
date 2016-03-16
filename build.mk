#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

PWD		:= $(shell pwd -P)
PROJECT		?= $(notdir $(PWD))
BUILD		:= build
DEPDIR 		:= $(BUILD)/deps
DEPS		:= $(shell find $(DEPDIR) -name \*.d)
TEST_SOURCES	:= $(shell find test -name \*.cpp)
TESTS		:= $(patsubst %.cpp,$(BUILD)/%,$(TEST_SOURCES))
UNAME 		:= $(shell uname -rs)
SYSNAME		:= $(firstword $(UNAME))
REL 		:= $(lastword $(UNAME))
OPT		?= yes
COMPILER	?= LLVM
INSTALL_RTAGS	?= yes
DOWNLOADS	:= $(BUILD)/downloads
OPTDIR		:= $(BUILD)/opt
LIBDIR		:= $(BUILD)/lib
INCLUDEDIR	:= $(BUILD)/include
BINDIR		:= $(BUILD)/bin

.PHONY: ALL
all: ALL

# This makes sure that the includes are linked correctly
include $(BUILD)/include/$(PROJECT)/.link

# Targets
include $(BUILD)/target.mk

# Compiler specific stuff
ifeq ($(COMPILER),LLVM)
include $(BUILD)/llvm.mk
else ifeq ($(COMPILER),GCC)
include $(BUILD)/gcc.mk
endif

# NASM
include $(BUILD)/nasm.mk

# Rtags
ifeq ($(INSTALL_RTAGS),yes)
include $(BUILD)/rtags.mk
endif

# Gtest stuff
include $(BUILD)/gtest.mk


# We only need to include the system mk file if the config.h doesn't exist
ifeq ($(wildcard $(BUILD)/include/config.h),)
include $(BUILD)/$(SYSNAME).mk
include $(BUILD)/config.mk
endif

BIN 		 = $(BUILD)/bin/hello 

ALL: $(BIN)

# BIN have order-only prereqs for test.. everything always has to test clean
$(BIN) : | $(TESTS) $(LIBS)

#
# Targets to build everything
#

$(BUILD)/% : $(BUILD)/%.o
	mkdir -p $(@D)
	$(LINK) -o $@ $^

.PRECIOUS: $(DEPDIR)/%.d
$(BUILD)/%.o : %.cpp $(DEPDIR)/%.d | $(BUILD)/include/config.h
	$(PRECOMPILE_DEP)
	$(call PRECOMPILE_CMD,$(COMPILE_CXX),$<)
	$(COMPILE_CXX) $(DEPFLAGS) -c -o $@ $<
	$(POSTCOMPILE_CMD)
	$(POSTCOMPILE_DEP)

$(BUILD)/%.o : %.c | $(DEPDIR)/%.d
	$(PRECOMPILE_DEP)
	$(call PRECOMPILE_CMD,$(TARGET_COMPILE_CC),$<)
	$(TARGET_COMPILE_CC) $(DEPFLAGS) -o $@ -c $<
	$(POSTCOMPILE_CMD)
	$(POSTCOMPILE_DEP)

$(BUILD)/%.bin : %.asm | $(DEPDIR)/%.d
	$(call NASM_BUILD,bin)


$(BUILD)/%.$(TARGET_FORMAT).o : %.asm | $(DEPDIR)/%.d
	$(call NASM_BUILD,$(TARGET_FORMAT))

$(BUILD)/%.$(TARGET_FORMAT): $(BUILD)/%.$(TARGET_FORMAT).o | %.$(TARGET_LDEMU).ld $(DEPDIR)/%.d
	$(TARGET_LD) -m $(TARGET_LDEMU) -T$(*).$(TARGET_LDEMU).ld $^ $(KERNEL_LD_OPTS) -o $@ #--oformat binary

$(BUILD)/%.$(TARGET_FORMAT).bin: $(BUILD)/%.$(TARGET_FORMAT).o | %.$(TARGET_LDEMU).ld $(DEPDIR)/%.d
	$(TARGET_LD) -m $(TARGET_LDEMU) -T$(*).$(TARGET_LDEMU).ld $^ $(KERNEL_LD_OPTS) -o $@ --oformat binary

$(BUILD)/%.a :
	ar rcs $@ $^

$(BUILD)/test/% : $(BUILD)/test/%.o
	mkdir -p $(@D)
	$(LINK) -o $@.fail $^ $(GTEST_LIBS)
	LD_LIBRARY_PATH=$(LIBDIR) $@.fail --gtest_output=xml:$(@D)/
	python $(BUILD)/parse_perf_tests.py $@.xml
	mv $@.fail $@

foofofof:
	mv $< $@

#
# The rest of this used to auto-install packages. See llvm.mk and gtest.mk for examples of how to
# use
#
$(DOWNLOADS)/% :
	mkdir -p $(@D)
	curl -o $@ $($(*)_URL)

$(OPTDIR)/%/.unpack : $(%_ARCHIVE)
	mkdir -p $(@D)
	case "$(suffix $($(*)_ARCHIVE))" in \
		".zip") unzip -d $(OPTDIR) $< ;;\
		".xz") 	tar -J -xf $< -C $(@D) --strip-components=1 ;;\
		".gz") 	tar -z -xf $< -C $(@D) --strip-components=1 ;;\
		*) echo "Don't know how to unarchive $($(*)_ARCHIVE)"; exit 1;;\
	esac
	touch $@

$(BUILD)/include/$(PROJECT)/.link:
	mkdir -p $(BUILD)/include
	ln -sf ../../include $(BUILD)/include/$(PROJECT)
	touch $@


clean:
	rm -rf $(LIBS) $(BIN)
	$(MAKE) $(PROJECT)-clean

.PHONY: check-syntax
check-syntax:
	$(COMPILE) -fsyntax-only $(CHK_SOURCES)

.PHONY: check-setup
check-setup: ;


$(DEPDIR)/%.d: ;

include $(DEPS)
