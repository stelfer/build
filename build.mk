#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

BUILD		:= $(ROOT)build
DEPDIR 		:= $(BUILD)/deps
DEPS		:= $(shell find $(DEPDIR) -name \*.d)
#TEST_SOURCES	:= $(shell find test -name \*.cpp)
#TESTS		:= $(patsubst %.cpp,$(BUILD)/%,$(TEST_SOURCES))
OPT		?= yes
COMPILER	?= LLVM
INSTALL_RTAGS	?= yes
DOWNLOADS	:= $(BUILD)/downloads
OPTDIR		:= $(BUILD)/opt
LIBDIR		:= $(BUILD)/lib
INCLUDEDIR	:= $(BUILD)/include
BINDIR		:= $(BUILD)/bin
TEST		:= $(BUILD)/test
PROJECTS	:= $(ROOT)projects

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

# Emacs stuff
ifeq ($(NO_EMACS),)
include $(BUILD)/emacs.mk
endif

# include $(BUILD)/libnl.mk

# We only need to include the system mk file if the config.h doesn't exist
ifeq ($(wildcard $(BUILD)/include/config.h),)
include $(BUILD)/config.mk
endif

BIN 		 = $(BUILD)/bin/hello 

ALL: $(BIN)

# BIN have order-only prereqs for test.. everything always has to test clean
$(BIN) : | $(TESTS) $(LIBS)

#
# Rules to build ELF objects
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

$(BUILD)/%.o : %.asm | $(DEPDIR)/%.d
	$(call NASM_BUILD,$(TARGET_FORMAT))

$(BUILD)/%.$(TARGET_FORMAT): $(BUILD)/%.$(TARGET_FORMAT).o | %.$(TARGET_LDEMU).ld
	$(TARGET_LD) -m $(TARGET_LDEMU) -T$(*).$(TARGET_LDEMU).ld $^ $(KERNEL_LD_OPTS) -o $@

$(BUILD)/%.$(TARGET_FORMAT).bin: $(BUILD)/%.$(TARGET_FORMAT).o | %.$(TARGET_LDEMU).ld $(DEPDIR)/%.d
	$(TARGET_LD) -m $(TARGET_LDEMU) -T$(*).$(TARGET_LDEMU).ld $^ $(KERNEL_LD_OPTS) -o $@ --oformat binary

$(BUILD)/%.a :
	ar rcs $@ $^

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
		".zip") 		unzip -d $(OPTDIR) $< ;;\
		".xz"| ".bz2" | ".gz") 	tar maxvf $< -C $(@D) --strip-components=1 ;;\
		*) echo "Don't know how to unarchive $($(*)_ARCHIVE)"; exit 1;;\
	esac
	touch $@

# This allows us to cleanly link the header directories
$(INCLUDEDIR)/%/.link : projects/%/include
	ln -sf ../../projects/$(*)/include $(@D)
	touch $@

clean:
	@echo "Available clean targets: all-clean $(BUILD_CLEAN)"

all-clean:
	rm -rf $(LIBS) $(BIN)
	$(MAKE) $(BUILD_CLEAN)

.PHONY: check-syntax
check-syntax: | check-hosts
	$(COMPILE) -fsyntax-only $(CHK_SOURCES)

%/check :
	@ssh $(@D) '[ $$(./build-$(TARGET_OS)/target/bin/clang -v 2>&1 | grep "clang version" | cut -d" " -f3) = "$(LLVM_VER)" ]' ||  $(MAKE) $(@D)/install

%/install :
	$(MAKE) $(BUILD)/targets/target-$(TARGET_OS).tar.xz
	scp $(BUILD)/targets/target-$(TARGET_OS).tar.xz $(@D):
	ssh $(@D) tar maxfv target-$(TARGET_OS).tar.xz


$(BUILD)/targets/target-$(TARGET_OS).tar.xz: $(BUILD)/downloads/$($(LLVM)_ARCHIVE)
	@p=( $(TARGET_HOSTS) );	n=$$(( RANDOM % $${#p[@]} )); h=$${p[$$n]};\
	$(TARGET_SCP) $(BUILD)/build-target.sh $$h:/tmp;\
	$(TARGET_SSH) $$h sh /tmp/build-target.sh $($($(LLVM)_ARCHIVE)_URL)


$(BUILD)/targets/host-$(TARGET_OS).tar.xz:
	p=( $(TARGET_HOSTS) );	n=$$(( RANDOM % $${#p[@]} )); h=$${p[$$n]};\
	$(TARGET_SCP) $(BUILD)/host-$(TARGET_OS).sh $$h:/tmp;\
	$(TARGET_SSH) $$h sh /tmp/host-$(TARGET_OS).sh;\
	$(TARGET_SCP) $$h:/tmp/host-$(TARGET_OS)/host-centos-7.2-x86_64.tar.xz $@



.PHONY: check-setup
check-setup: ;

.PHONY: check-hosts
check-hosts: | $(TARGET_HOSTS:=/check)




$(DEPDIR)/%.d: ;

include $(DEPS)
