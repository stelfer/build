#Copyright (C) 2016 by Soren Telfer - MIT License. See LICENSE.txt

TARGET_OPT		?= yes


TARGET_ARCH		:= elf32


TARGET			:= i686-elf


TARGET_CCARCH		:= -target $(TARGET) -m32
TARGET_CCWARN		 = $(CCWARN)
TARGET_CCDIAG		 = $(CCDIAG)
TARGET_CCFLAGS		 = $(TARGET_CCWARN) $(TARGET_CCDIAG)
TARGET_CCINCLUDES	 = $(CCINCLUDES)
TARGET_CCSTD		 = $(CCSTD)

ifeq ($(TARGET_OPT),yes)
TARGET_CCOPT		:= -O1
endif

TARGET_COMPILE_CC	 = $(CC) $(TARGET_CCARCH) $(TARGET_CCFLAGS) $(TARGET_CCINCLUDES) $(TARGET_CCSTD) $(TARGET_CCOPT)

TARGET_LD		 = $(BINDIR)/$(TARGET)-ld
TARGET_STRIP		 = $(BINDIR)/$(TARGET)-strip
