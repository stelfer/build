#Copyright (C) 2016 by Soren Telfer - MIT License. See LICENSE.txt

TARGET_OPT		?= yes

#TARGET_ARCH		:= elf32
#TARGET			:= i686-elf


TARGET_CCARCHFLAGS	:= -target $(TARGET) $(TARGET_CCARCH)
TARGET_CCWARN		 = $(CCWARN)
TARGET_CCDIAG		 = $(CCDIAG)
TARGET_CCFLAGS		 = $(TARGET_CCWARN) $(TARGET_CCDIAG)
TARGET_CCINCLUDES	 = $(CCINCLUDES)
TARGET_CCSTD		 = $(CCSTD)

ifeq ($(TARGET_OPT),yes)
TARGET_CCOPT		:= -O1
endif

TARGET_COMPILE_CC	 = $(CC) $(TARGET_CCARCHFLAGS) $(TARGET_CCFLAGS) $(TARGET_CCINCLUDES) $(TARGET_CCSTD) $(TARGET_CCOPT)

TARGET_AR		 = $(BINDIR)/$(TARGET)-ar
TARGET_LD		 = $(BINDIR)/$(TARGET)-ld
TARGET_STRIP		 = $(BINDIR)/$(TARGET)-strip
TARGET_OBJCOPY		 = $(BINDIR)/$(TARGET)-objcopy
TARGET_GDB		 = $(BINDIR)/$(TARGET)-gdb

TARGET_OS		 = $(TARGET_OS_FLAVOR)-$(TARGET_OS_VERSION)-$(TARGET_ARCH)
TARGET_BUILD_DIR	 = build-$(TARGET_OS)

TARGET_HEADERS		:= $(INCLUDEDIR)/$(TARGET_OS)

TARGET_MODE 		?= run
TARGET_SSH		:= ssh -o Ciphers=arcfour -o Compression=no -T -t
TARGET_SCP		:= scp -o Ciphers=arcfour -C -q 
TARGET_SCRIPT		:= $(TARGET_BUILD_DIR)/target.sh
TARGET_SSH_CMD  	= $(TARGET_SSH)\
				$(HOST)\
				TARGET_MODE=\"$(TARGET_MODE)\"\
				TARGET_LDFLAGS=\"$(LLVM_BC_LDFLAGS)\"\
				sh $(TARGET_SCRIPT) $(@F) $(notdir $(TARGET_OBJS))

include $(TARGET_HEADERS)/.link

include build/gdb.mk

$(BUILD)/target-debug/%.ll:
	@$(TARGET_GDB) -ex '$(GDB_REMOTE_CMD)'

$(BUILD)/target-run/%.ll:
	@$(TARGET_SSH_CMD)
	@$(TARGET_SCP) $(HOST):$(TARGET_BUILD_DIR)/$(patsubst %.ll,%,$(@F)){,.xml} $(*D)
	rsync -avz $(HOST):$(TARGET_BUILD_DIR)/test/ build/test

$(BUILD)/target-valgrind/%.ll:
	@$(TARGET_SSH_CMD)

$(INCLUDEDIR)/%/.link: $(BUILD)/targets/%.tar.xz
	tar -Jxf $< -C $(INCLUDEDIR)
	touch $@


# This allows us to cleanly link the header directories
# $(INCLUDEDIR)/%/.link : build/targets/%/include
# 	ln -sf ../../projects/$(*)/include $(@D)
# 	touch $@



.PHONY: check-target-hosts
check-target-hosts: | check-setup
	@for p in $(TARGET_HOSTS);\
	do\
		ssh $$p echo "hi" >& /dev/null || { \
			echo '\033[0;31m[   FAILED ]\033[0m' "$$p. Host unreachable." ;\
			exit 1;\
		};\
		echo '\033[0;32m[       OK ]\033[0m' $$p;\
	done




