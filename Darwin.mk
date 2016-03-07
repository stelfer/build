#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

DEFINES			+= SYS_DARWIN

REL_VER 		:= $(firstword $(subst -, ,$(REL)))
REL_VER_L 		:= $(subst ., ,$(REL_VER))
REL_VER_MAJ 		:= $(word 1, $(REL_VER_L))
REL_VER_MIN 		:= $(word 2, $(REL_VER_L))
REL_VER_PAT 		:= $(word 3, $(REL_VER_L))

