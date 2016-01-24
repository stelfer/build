#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

#
# Automatically generate build/include/config.h
#

define nl


endef

define _CONFIG_H_PRE
// Automatically generated $(shell date +%FT%TZ)
#ifndef _CONFIG_H
#define _CONFIG_H

#define BUILD_SPEC 		"$(BUILD_SPEC)"
#define SYSNAME			"$(SYSNAME)"
#define REL_VER_MAJ		"$(REL_VER_MAJ)"
#define REL_VER_MIN		"$(REL_VER_MIN)"
#define REL_VER_PAT		"$(REL_VER_PAT)"

endef

define _CONFIG_H_POST
#endif
endef

build/include/config.h:
	$(file >$@,$(_CONFIG_H_PRE))
	$(file >>$@,$(foreach x,$(DEFINES),#define $(subst =, ,$(x))$(nl)))
	$(file >>$@,$(_CONFIG_H_POST))
