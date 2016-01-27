#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GOLD			:= gold
GOLD_DIR		:= $(OPTDIR)/$(GOLD)
GOLD_INSTALL		:= $(GOLD_DIR)/.install
GOLD_GIT_COMMIT_ISH	:= HEAD

$(GOLD_INSTALL): | $(GOLD_DIR)
	cd $(GOLD_DIR);\
	git reset --hard $(GOLD_GIT_COMMIT_ISH);\
	mkdir .build;\
	cd .build;\
	../configure --enable-gold --enable-plugins --disable-werror --prefix=/opt/home/telfer/l/foo/build;\
	make -j all-gold;\
	make -j install-gold
	touch $(GOLD_INSTALL)

$(GOLD_DIR):
	mkdir -p $(OPTDIR)
	cd $(OPTDIR);\
	git clone --depth 1 git://sourceware.org/git/binutils-gdb.git $(GOLD)



