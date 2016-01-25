#!/bin/bash

# Automatically generate the basic files

set -e

PROJECT=$(basename $PWD)
if [ $# -ge 1 ]; then
    PROJECT=$1
fi

if [ -z "$ORGANIZATION" ]; then
    ORGANIZATION=$USER
fi

echo "Creating stub for $PROJECT under $ORGANIZATION"

echo "Creating Makefile"
cat <<EOF > Makefile
#
# A Makefile for project \`${PROJECT}'
# Automatically generated on $(date +%FT%T%Z)
#

# Override this if your project source is not the same name as the current directory
PROJECT			:= ${PROJECT}

# Include the mothership
include build/build.mk

# Your source code goes here
include \$(PROJECT)/Makefile

include test/Makefile

# Include other submodules for your project under projects
include projects/Makefile

# Include other Makefiles here...

EOF

echo "Setting up directories"
DIRS="${PROJECT} test projects"
for d in $DIRS; do
    mkdir -p $d
    touch $d/Makefile
done
mkdir -p include

echo "Setting up license"
cp build/LICENSE.txt LICENSE.txt

echo "Setting up emacs c++-style"
cat <<EOF > .${PROJECT}-c-style.el
(defconst ${PROJECT}-c-style
  '((c-basic-offset . 4)
    (indent-tabs-mode . nil)
    (c-recognize-knr-p . nil)
    (c-enable-xemacs-performance-kludge-p . t)
    (c-comment-only-line-offset . (0 . 0))
    (c-hanging-braces-alist
     (defun-open after)
     (defun-close before after)
     (class-open before after)
     (class-close before after)
     (inexpr-class-open after)
     (inexpr-class-close before)
     (brace-list-open)
     (brace-entry-open)
     (substatement-open after)
     (block-close . c-snug-do-while)
     (arglist-cont-nonempty))
    (c-cleanup-list brace-else-brace
		    brace-elseif-brace
		    empty-defun-braces
		    defun-close-semi)
    (c-offsets-alist
     (statement-block-intro . +)
     (knr-argdecl-intro . 0)
     (substatement-open . 0)
     (substatement-label . 0)
     (label . 0)
     (statement-cont . (c-lineup-string-cont c-lineup-cascaded-calls c-lineup-assignments))
     (stream-op . c-lineup-streamop)
     (case-label . +)
     (arglist-cont . (c-lineup-arglist-operators 0))
     (arglist-cont-nonempty . (c-lineup-argcont c-lineup-arglist))
     (innamespace . 0)
     (access-label . /))
    (c-indent-comment-alist . ((empty-line . (align . 0))
    			       (anchored-block . (space . 0))))
    (comment-column . 40)
    (c-hanging-semi&comma-criteria
     . (c-semi&comma-no-newlines-before-nonblanks
	c-semi&comma-no-newlines-for-oneline-inliners
	c-semi&comma-inside-parenlist))
    (c-echo-syntactic-information-p . t)) "${PROJECT} Programming Style")

(provide '${PROJECT}-c-style)

EOF

echo "Setting up .dir-locals.el "
cat <<EOF > .dir-locals.el
(
 (nil . ((eval . (setenv "ORGANIZATION" "$ORGANIZATION - MIT License. See LICENSE.txt"))
	 (eval . (setenv "PATH" (concat (getenv "PATH") ":" (projectile-project-p) "build/bin" )))
	 (eval . (setq exec-path (append exec-path '(concat (projectile-project-p) "build/bin" ))))))
 (c++-mode . ((eval . (progn
			(unless (assoc "${PROJECT}-c-style" c-style-alist)
			  (load (concat "${PWD}/" ".${PROJECT}-c-style.el"))
			  (c-add-style "${PROJECT}-c-style" ${PROJECT}-c-style))
			(c-set-style "${PROJECT}-c-style")
			(unless rtags-path
			  (setq rtags-path (concat (projectile-project-p) "build/bin" )))
			(rtags-start-process-unless-running)
			)))))

EOF


echo "Building tooling"
make -j check-setup

