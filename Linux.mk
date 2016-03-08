#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

DEFINES			+= SYS_LINUX

REL_VER 		:= $(firstword $(subst -, ,$(REL)))
REL_VER_L 		:= $(subst ., ,$(REL_VER))
REL_VER_MAJ 		:= $(word 1, $(REL_VER_L))
REL_VER_MIN 		:= $(word 2, $(REL_VER_L))
REL_VER_PAT 		:= $(word 3, $(REL_VER_L))

# Determine Namespase support
NS_BASE			:= 				\
				HAVE_CLONE_NEWNS 	\
				HAVE_CLONE_NEWUTS 	\
				HAVE_CLONE_NEWIPC 	\
				HAVE_CLONE_NEWPID	\
				HAVE_CLONE_NEWNET
NS_PARTIAL 		:= $(shell echo $$(( $(REL_VER_MAJ) == 2 && $(REL_VER_MIN) > 24 )) )
NS_COMPLETE 		:= $(shell echo $$(( $(REL_VER_MAJ) == 2 && $(REL_VER_MIN) > 8 )) )
NS_COMPLETE 		:= $(shell echo $$(( $(NS_COMPLETE) || $(REL_VER_MAJ) > 2 )) )
ifeq ($(NS_COMPLETE), 1)
DEFINES 		+= $(NS_BASE) HAVE_CLONE_NEWUSER
else ifeq ($(NS_PARTIAL), 1)
DEFINES 		+= $(NS_BASE)
endif

DEFINES			+= HAVE_EPOLL

L1_DCACHE_LINESIZE	:= $(shell getconf LEVEL1_DCACHE_LINESIZE)
DEFINES 		+= L1_DCACHE_LINESIZE=$(L1_DCACHE_LINESIZE)


TEST_PERF_INSTR		:= $(wildcard /sys/devices/cpu/events/instructions)
TEST_RDTSC		:= $(shell grep -q rdtsc /proc/cpuinfo && echo "yes")

# perf_timer support
ifeq ($(TEST_PERF_INSTR),/sys/devices/cpu/events/instructions)
DEFINES			+= PERF_TIMER=PERF_INSTR
else ifeq ($(TEST_RDTSC),yes)
DEFINES			+= PERF_TIMER=RDTSC
else
DEFINES			+= PERF_TIMER=CLOCK_MONOTONIC
endif
