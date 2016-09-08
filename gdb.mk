#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

GDB_VER			:= 7.11.1
GDB			:= gdb-$(GDB_VER)
$(GDB)_ARCHIVE 		:= $(GDB).tar.xz
$($(GDB)_ARCHIVE)_URL 	:= http://ftp.gnu.org/gnu/gdb/$($(GDB)_ARCHIVE)
GDB_INSTALL		:= $(OPTDIR)/$(GDB)/.install
GDB_UNPACK		:= $(OPTDIR)/$(GDB)/.unpack
GDB_CONFIGURE		:= $(OPTDIR)/$(GDB)/.configure
GDB_REMOTE_CMD 		 = target remote | $(TARGET_SSH_CMD)

$(GDB_UNPACK)		: $(DOWNLOADS)/$($(GDB)_ARCHIVE)

include $(GDB_INSTALL)


$(GDB_CONFIGURE): | $(GDB_UNPACK)
	mkdir -p $(@D)
	cd $(@D);\
	./configure --prefix=$(PWD)/$(BUILD) --target=$(TARGET) CC=$(HOST_CC) CXX=$(HOST_CXX)
	touch $@

$(GDB_INSTALL): | $(GDB_CONFIGURE)
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	touch $@
