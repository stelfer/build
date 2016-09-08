#Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt

EMACS_CLIENT			?= /Applications/Emacs.app/Contents/MacOS/bin/emacsclient

define EMACS_REMOTE_GDB_PROGN =
((lambda nil\
	(gdb "$(TARGET_GDB) -i=mi")\
	(insert\
	(concat "target remote | $(TARGET_SSH) $(HOST) "\
		(shell-quote-argument  "TARGET_MODE=\"$(TARGET_MODE)\" ")\
		(shell-quote-argument  "TARGET_LDFLAGS=\"$(LLVM_BC_LDFLAGS)\" ")\
		" sh $(TARGET_SCRIPT) $(@F)"))(comint-send-input)))
endef

EMACS_LAUNCH_REMOTE_GDB		 = $(EMACS_CLIENT) --eval '$(EMACS_REMOTE_GDB_PROGN)'

$(BUILD)/remote-debug-in-emacs/%.ll:
	@$(EMACS_LAUNCH_REMOTE_GDB)
