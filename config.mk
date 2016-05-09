#Copyright (C) 2015 by AT&T Services Inc. MIT License. See LICENSE.txt

#
# Automatically generate $(INCLUDEDIR)/config.h
#

define nl


endef

define _CONFIG_H_PRE
// Automatically generated $(shell date +%FT%TZ)
#ifndef _CONFIG_H
#define _CONFIG_H

// Target-specific things here

endef

define _CONFIG_H_POST
#endif
endef

$(INCLUDEDIR)/config.h:
	$(file >$@,$(_CONFIG_H_PRE))
	$(file >>$@,$(foreach x,$(DEFINES),#define $(subst =, ,$(x))$(nl)))
	$(file >>$@,$(_CONFIG_H_POST))
