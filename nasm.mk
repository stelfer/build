#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

NASM_VER		:= 2.12
NASM			:= nasm-$(NASM_VER)
NASM_INSTALL		:= $(OPTDIR)/$(NASM)/.install
NASM_UNPACK		:= $(OPTDIR)/$(NASM)/.unpack
$(NASM)_ARCHIVE 	:= $(NASM).tar.gz
$($(NASM)_ARCHIVE)_URL 	:= http://www.nasm.us/pub/nasm/releasebuilds/$(NASM_VER)/$($(NASM)_ARCHIVE)
$(NASM_UNPACK) 		: $(DOWNLOADS)/$($(NASM)_ARCHIVE)

include $(NASM_INSTALL)

$(NASM_INSTALL): | $(NASM_UNPACK)
	cd $(@D) && sh configure --prefix=$(PWD)/$(BUILD) CXX=$(HOST_CC) CC=$(HOST_CC)
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	touch $@


NASM			:= $(BINDIR)/nasm
NASM_DEPFLAGS		 = -MT $@ -MF $(DEPDIR)/$(*).Td

define NASM_BUILD
$(PRECOMPILE_DEP)
$(NASM) $(NASM_DEPFLAGS) $< -f $(1) -o $@
$(POSTCOMPILE_DEP)
endef




