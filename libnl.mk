#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

LIBNL_VER		:= 3.2.25
LIBNL			:= libnl-$(LIBNL_VER)
$(LIBNL)_ARCHIVE 	:= $(LIBNL).tar.gz
$($(LIBNL)_ARCHIVE)_URL := http://www.infradead.org/~tgr/libnl/files/$($(LIBNL)_ARCHIVE)

include $(OPTDIR)/$(LIBNL)/.install

$(OPTDIR)/$(LIBNL)/.unpack: | $(OPTDIR)/$(LLVM)/.build/.install

$(OPTDIR)/$(LIBNL)/.install: | $(OPTDIR)/$(LIBNL)/.unpack
	mkdir -p $(@D)
	cd $(@D);\
	./configure --prefix=$(PWD)/$(BUILD) --disable-cli --disable-pthreads CC=$(PWD)/$(CC) CXX=$(PWD)/$(CXX) CXXFLAGS="$(CXXSTD)"
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	touch $@



#LIBNL_LIBS		:= -lpthread -llibnl
