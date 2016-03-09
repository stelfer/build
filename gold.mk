#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GOLD			:= gold
GOLD_DIR		:= $(OPTDIR)/$(GOLD)
GOLD_INSTALL		:= $(GOLD_DIR)/.build/.install
GOLD_INCLUDEDIR		:= $(INCLUDEDIR)/binutils
GOLD_GIT_COMMIT_ISH	:= HEAD
GOLD_TARGET		:= i686-elf

$(GOLD_INSTALL): | $(GOLD_DIR)
	cd $(GOLD_DIR) && git reset --hard $(GOLD_GIT_COMMIT_ISH)
	mkdir -p $(@D)
	cd $(@D) && ../configure --target=$(TARGET) --prefix=$(PWD)/$(BUILD) --with-sysroot --disable-nls --disable-werror --enable-plugins --enable-gold CXX=$(HOST_CC) CC=$(HOST_CC)
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	ln -sf $(GOLD_TARGET)-ld.gold $(BINDIR)/ld
	touch $@


$(GOLD_DIR):
	mkdir -p $(OPTDIR)
	cd $(OPTDIR) &&  git clone --depth 1 git://sourceware.org/git/binutils-gdb.git $(GOLD)



