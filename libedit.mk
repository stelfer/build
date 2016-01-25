#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

LIBEDIT_VER			:= 20150325-3.1
LIBEDIT				:= libedit-$(LIBEDIT_VER)
$(LIBEDIT)_ARCHIVE 		:= $(LIBEDIT).tar.gz
$($(LIBEDIT)_ARCHIVE)_URL 	:= http://thrysoee.dk/editline/$($(LIBEDIT)_ARCHIVE)
LIBEDIT_INSTALL			:= $(OPTDIR)/$(LIBEDIT)/.install
LIBEDIT_UNPACK			:= $(OPTDIR)/$(LIBEDIT)/.unpack
LIBEDIT_CONFIGURE		:= $(OPTDIR)/$(LIBEDIT)/.configure

include $(LIBEDIT_INSTALL)

$(LIBEDIT_CONFIGURE): | $(LIBEDIT_UNPACK)
	mkdir -p $(@D)
	cd $(@D);\
	./configure --prefix=$(PWD)/$(BUILD) CC=$(PWD)/$(CC) CXX=$(PWD)/$(CXX) CXXFLAGS="$(CXXSTD)"

$(LIBEDIT_INSTALL): | $(LIBEDIT_CONFIGURE)
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	touch $@
