#Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt

# We need these to bootstrap our toolchain
HOST_CC			:= /usr/local/bin/gcc-6
HOST_CXX		:= /usr/local/bin/g++-6

TARGET_ARCH		:= x86_64
TARGET_ABI		:= elf
TARGET			?= x86_64-linux-gnu
TARGET_FORMAT		:= elf64
TARGET_CCARCH		:= -m64 -msse4.2
TARGET_LDEMU		:= elf_x86_64
TARGET_OS_FLAVOR	:= centos
TARGET_OS_VERSION	:= 7.2

TARGET_HOSTS 		 = 10.250.3.52 10.16.0.25 192.168.33.2

