#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

PWD		:= $(shell pwd -P)
PROJECT		?= $(notdir $(PWD))
BUILD		:= build
DEPDIR 		:= $(BUILD)/deps
DEPS		:= $(shell find $(DEPDIR) -name \*.d)
TEST_SOURCES	:= $(shell find test -name \*.cpp)
TESTS		:= $(patsubst %.cpp,$(BUILD)/%,$(TEST_SOURCES))
OPT		?= yes
COMPILER	?= LLVM
INSTALL_RTAGS	?= yes
DOWNLOADS	:= $(BUILD)/downloads
OPTDIR		:= $(BUILD)/opt
LIBDIR		:= $(BUILD)/lib
INCLUDEDIR	:= $(BUILD)/include
BINDIR		:= $(BUILD)/bin
PROJECTS	:= projects

.PHONY: ALL
all: ALL

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

$(BUILD)/%.o : %.asm | $(DEPDIR)/%.d
	$(call NASM_BUILD,$(TARGET_FORMAT))

$(BUILD)/%.$(TARGET_FORMAT): $(BUILD)/%.$(TARGET_FORMAT).o | %.$(TARGET_LDEMU).ld
	$(TARGET_LD) -m $(TARGET_LDEMU) -T$(*).$(TARGET_LDEMU).ld $^ $(KERNEL_LD_OPTS) -o $@

$(BUILD)/%.$(TARGET_FORMAT).bin: $(BUILD)/%.$(TARGET_FORMAT).o | %.$(TARGET_LDEMU).ld $(DEPDIR)/%.d
	$(TARGET_LD) -m $(TARGET_LDEMU) -T$(*).$(TARGET_LDEMU).ld $^ $(KERNEL_LD_OPTS) -o $@ --oformat binary

$(BUILD)/%.a :
	ar rcs $@ $^

$(BUILD)/test/%.ll : $(BUILD)/test/%.bc
	build/bin/llvm-link -o $@ $^ build/lib/gtest.bc

$(BUILD)/test/% : $(BUILD)/test/%.ll
	@p=( $(TARGET_HOSTS) );	n=$$(( RANDOM % $${#p[@]} )); h=$${p[$$n]};\
	echo "[==========]" Running on $$h;\
	rsync $< build/target.sh build/parse_perf_tests.py $$h:build-$(TARGET_OS) ;\
	$(TARGET_SSH) $$h sh build-$(TARGET_OS)/target.sh ${<F}


PROGN 		= ((lambda nil (gdb "~/src/work/build/bin/x86_64-linux-gnu-gdb -i=mi") (insert "target remote | ssh -T $(*D) sh build-centos-7.2-x86_64/debug.sh $(@F)") (comint-send-input)))


#.INTERMEDIATE: $(BUILD)/test/%.gdb
$(BUILD)/remotes/%.ll:
	/Applications/Emacs.app/Contents/MacOS/bin/emacsclient --eval '$(PROGN)'

zoo:
	@p=( $(TARGET_HOSTS) );	n=$$(( RANDOM % $${#p[@]} )); h=$${p[$$n]};\
	echo "[==========]" Running on $${p[$$n]};\
	rsync $< build/debug.sh build/parse_perf_tests.py $${p[$$n]}:build-$(TARGET_OS);\
	echo "target remote | ssh -T $${p[$$n]} sh build-centos-7.2-x86_64/debug.sh ${<F}" > $@

$(BUILD)/test/%.debug : $(BUILD)/test/%.ll
	@p=( $(TARGET_HOSTS) );	n=$$(( RANDOM % $${#p[@]} )); h=$${p[$$n]};\
	echo "[==========]" Running on $${p[$$n]};\
	rsync $< build/debug.sh build/parse_perf_tests.py $${p[$$n]}:build-$(TARGET_OS);\
	$(MAKE) $(BUILD)/remotes/$${p[$$n]}/${<F}


foo:
	ssh -q -T -t bbox3 "./clang/bin/clang -o test -Lclang/lib -lpthread -lc++abi -lc++ work/$< /usr/lib/gcc/x86_64-redhat-linux/4.8.2/libsupc++.a && LD_LIBRARY_PATH=clang/lib ./test; a=$$? ; rm ./test; exit $$a"
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
		".bz2") tar -j -xf $< -C $(@D) --strip-components=1 ;;\
		".gz") 	tar -z -xf $< -C $(@D) --strip-components=1 ;;\
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
	ssh $(@D) ./build-$(TARGET_OS)/clang/bin/clang -v >& /dev/null ||  $(MAKE) $(@D)/install

%/install :
	scp build/targets/build-$(TARGET_OS).tar.xz $(@D):
	ssh $(@D) tar Jxfv build-$(TARGET_OS).tar.xz

.PHONY: check-setup
check-setup: ;

.PHONY: check-hosts
check-hosts: | $(TARGET_HOSTS:=/check)




$(DEPDIR)/%.d: ;

include $(DEPS)
