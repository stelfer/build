#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

RTAGS			:= rtags
RTAGS_DIR		:= $(OPTDIR)/$(RTAGS)
RTAGS_UNPACK		:= $(RTAGS_DIR)/.unpack
RTAGS_INSTALL		:= $(RTAGS_DIR)/build/.install
RTAGS_GIT_SHA		:= HEAD
#RTAGS_GIT_SHA		:= 9b86f0d
RTAGS_CMAKE_FLAGS	:= -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_INSTALL_PREFIX:PATH=$(PWD)/build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=$(PWD)/build

include $(RTAGS_INSTALL)

$(RTAGS_INSTALL): | $(RTAGS_UNPACK)
	mkdir -p $(@D)
	cd $(@D) && cmake $(RTAGS_CMAKE_FLAGS) ..
	$(MAKE) -C $(@D) -j all install
	touch $@

$(RTAGS_UNPACK): | $(LLVM_INSTALL)
	mkdir -p $(OPTDIR)
	cd $(OPTDIR) && git clone https://github.com/Andersbakken/rtags.git
	cd $(@D) && git reset --hard $(RTAGS_GIT_SHA) && git submodule init && git submodule update
	touch $@



