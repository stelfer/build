#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

LIBNL_VER		:= 3.2.25
LIBNL			:= libnl-$(LIBNL_VER)
$(LIBNL)_ARCHIVE 	:= $(LIBNL).tar.gz
$($(LIBNL)_ARCHIVE)_URL := http://www.infradead.org/~tgr/libnl/files/$($(LIBNL)_ARCHIVE)
$(LIBNL)_UNARCHIVE_CMD 	:= tar -z -xf $($(LIBNL)_ARCHIVE) -C $(LIBNL) --strip-components=1

include build/$(LIBNL)/.install

build/$(LIBNL)/.unpack: | build/$(LLVM)/.build/.install

build/$(LIBNL)/.install: | build/$(LIBNL)/.unpack
	mkdir -p $(@D)
	cd $(@D);\
	./configure --prefix=$(PWD)/build/ --disable-cli --disable-pthreads CC=$(PWD)/$(CC) CXX=$(PWD)/$(CXX) CXXFLAGS="$(CXXSTD)"
	$(MAKE) -C $(@D)
	$(MAKE) -C $(@D) install
	touch $@



#LIBNL_LIBS		:= -lpthread -llibnl
