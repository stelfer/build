#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

RTAGS			:= rtags
RTAGS_DIR		:= build/$(RTAGS)
RTAGS_INSTALL		:= $(RTAGS_DIR)/.install
RTAGS_GIT_SHA		:= HEAD
RTAGS_CMAKE_FLAGS	:= -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_INSTALL_PREFIX:PATH=$(PWD)/build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=$(PWD)/build

include $(RTAGS_INSTALL)

$(RTAGS_INSTALL): | build/$(LLVM)/.build/.install $(RTAGS_DIR)
	cd $(@D);\
	git reset --hard $(RTAGS_GIT_SHA);\
	git submodule init;\
	git submodule update;\
	mkdir build;\
	cd build;\
	cmake $(RTAGS_CMAKE_FLAGS) .. ;\
	make -j all install
	touch $@

$(RTAGS_DIR):
	cd $(@D);\
	git clone https://github.com/Andersbakken/rtags.git



