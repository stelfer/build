#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

BINUTILS			:= binutils
BINUTILS_DIR			:= $(OPTDIR)/$(BINUTILS)
BINUTILS_INSTALL		:= $(BINUTILS_DIR)/.build/.install
BINUTILS_INCLUDEDIR		:= $(INCLUDEDIR)/binutils
BINUTILS_GIT_COMMIT_ISH		:= HEAD

$(BINUTILS_INSTALL): | $(BINUTILS_DIR)
	cd $(BINUTILS_DIR) && git reset --hard $(BINUTILS_GIT_COMMIT_ISH)
	mkdir -p $(@D)
	cd $(@D) && ../configure --target=$(TARGET) --prefix=$(PWD)/$(BUILD) --with-sysroot --disable-nls --disable-werror --enable-plugins --enable-gold CXX=$(HOST_CXX) CC=$(HOST_CC)
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	cp -af $(BINUTILS_DIR)/include $(BUILD)/include/binutils
	ln -sf $(TARGET)-ld.gold $(BINDIR)/ld
	touch $@


$(BINUTILS_DIR):
	mkdir -p $(OPTDIR)
	cd $(OPTDIR) &&  git clone --depth 1 git://sourceware.org/git/binutils-gdb.git $(BINUTILS)



