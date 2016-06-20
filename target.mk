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


TARGET_OS		 = $(TARGET_OS_FLAVOR)-$(TARGET_OS_VERSION)-$(TARGET_ARCH)

TARGET_HEADERS		:= $(INCLUDEDIR)/$(TARGET_OS)

TARGET_SSH		:= ssh -o Ciphers=arcfour -o Compression=no -T -t


include $(TARGET_HEADERS)/.link

include build/gdb.mk


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




