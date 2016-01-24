#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

LIBEDIT_VER			:= 20150325-3.1
LIBEDIT				:= libedit-$(LIBEDIT_VER)
$(LIBEDIT)_ARCHIVE 		:= $(LIBEDIT).tar.gz
$($(LIBEDIT)_ARCHIVE)_URL 	:= http://thrysoee.dk/editline/$($(LIBEDIT)_ARCHIVE)
$(LIBEDIT)_UNARCHIVE_CMD 	:= tar -z -xf $($(LIBEDIT)_ARCHIVE) -C $(LIBEDIT) --strip-components=1
LIBEDIT_INSTALL			:= build/$(LIBEDIT)/.install
LIBEDIT_UNPACK			:= build/$(LIBEDIT)/.unpack
LIBEDIT_CONFIGURE		:= build/$(LIBEDIT)/.configure

include $(LIBEDIT_INSTALL)

$(LIBEDIT_CONFIGURE): | $(LIBEDIT_UNPACK)
	mkdir -p $(@D)
	cd $(@D);\
	./configure --prefix=$(PWD)/build CC=$(PWD)/$(CC) CXX=$(PWD)/$(CXX) CXXFLAGS="$(CXXSTD)"

$(LIBEDIT_INSTALL): | $(LIBEDIT_CONFIGURE)
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	touch $@
