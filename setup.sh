#!/bin/bash
#
# Copyright (C) 2016 by AT&T Services Inc. - MIT License. See LICENSE.txt
#
# Automatically generate the basic files
#
set -e

PROJECT=$(basename $PWD)
if [ $# -ge 1 ]; then
    PROJECT=$1
fi

if [ -z "$ORGANIZATION" ]; then
    ORGANIZATION=$USER
fi

if [ -z "$HOST_CC" ] ; then
    HOST_CC=$(which gcc)
fi

if [ -z "$HOST_CXX" ] ; then
    HOST_CC=$(which g++)
fi

if [ -z $TARGET ] ; then
    TARGET=i686-elf
fi

if [ -z $TARGET_FORMAT ] ; then
    TARGET_FORMAT=elf32
fi

if [ -z $TARGET_CCARCH ] ; then
    TARGET_CCARCH=-m32
fi

if [ -z $TARGET_LDEMU ] ; then
    TARGET_LDEMU=elf_i386
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

# We need these to bootstrap our toolchain
HOST_CC			:= ${HOST_CC}
HOST_CXX		:= ${HOST_CXX}

TARGET			:= ${TARGET}
TARGET_FORMAT		:= ${TARGET_FORMAT}
TARGET_CCARCH		:= ${TARGET_CCARCH}
TARGET_LDEMU		:= ${TARGET_LDEMU}

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
((nil . ((eval . (setenv "ORGANIZATION" "$ORGANIZATION - MIT License. See LICENSE.txt"))
	 (eval . (let ((path (concat (projectile-project-p) "build/bin/")))
		   (unless (string= path (car (parse-colon-path (getenv "PATH"))))
		     (setenv "PATH" (concat path ":" (getenv "PATH"))))))
	 (eval . (let ((path (concat (projectile-project-p) "build/bin")))
		   (unless (string= path (car exec-path))
		     (setq exec-path (push path exec-path)))))
	 (eval . (progn
		   (define-auto-insert '"\\\\.\\\\([Hh]\\\\|hh\\\\|hpp\\\\)\\\\'"
		     (lambda ()
		       (let* ((yas-indent-line 'auto)
			      (d (file-name-nondirectory (file-name-sans-extension buffer-file-name)))
			      (u (upcase d))
			      (ns "layers")
			      (s (concat "// " (getenv "ORGANIZATION") "\n\n"
					 "#ifndef _" u "_H\n"
					 "#define _" u "_H\n"
					 "namespace \${1:" ns "}\n{\n\n"
					 "class " d "\n{\n"
					 "public:\n"
					 d "(\${2});\n"
					 "\$0"
					 "\n};\n\n} // namespace \$1\n\n"
					 "#endif _" u "_H\n")))
			 (yas-expand-snippet s (point) (point) nil) )))

		   (define-auto-insert '"\\\\.\\\\(C\\\\|cc\\\\|cpp\\\\)\\\\'"
		     (lambda ()
		       (let* ((yas-indent-line 'auto)
			      (d (file-name-nondirectory (file-name-sans-extension buffer-file-name)))
			      (u (upcase d))
			      (ns "layers")
			      (s (concat "// " (getenv "ORGANIZATION") "\n\n"
					 "#include \\"\${1:" ns "}/\${2:" d "}.h\\"\n\n"
					 "using namespace " ns ";\n\n"
					 "\$0"
					 "\n\n")))
			 (yas-expand-snippet s (point) (point) nil) )))))))
 (c++-mode . ((eval . (progn
			(add-hook 'before-save-hook 'clang-format-buffer)
			(unless (assoc "${PROJECT}-c-style" c-style-alist)
			  (load (concat "${PWD}/" ".${PROJECT}-c-style.el"))
			  (c-add-style "${PROJECT}-c-style" ${PROJECT}-c-style))
			(c-set-style "${PROJECT}-c-style")
			(unless rtags-path
			  (setq rtags-path (concat (projectile-project-p) "build/bin" ))
			  (setq rtags-process-flags "-d ${PWD}/build/.rtags"))
			(rtags-start-process-unless-running))))))

EOF

echo "Setting up clang-format"
cat <<EOF > .clang-format
---
Language:        Cpp
AccessModifierOffset: -2
AlignAfterOpenBracket: true
AlignConsecutiveAssignments: true
AlignEscapedNewlinesLeft: true
AlignOperands:   true
AlignTrailingComments: true
AllowAllParametersOfDeclarationOnNextLine: false
AllowShortBlocksOnASingleLine: false
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: Inline
AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false
AlwaysBreakAfterDefinitionReturnType: All
AlwaysBreakBeforeMultilineStrings: true
AlwaysBreakTemplateDeclarations: true
BinPackArguments: false
BinPackParameters: false
BreakBeforeBinaryOperators: None
BreakBeforeBraces: Linux
BreakBeforeTernaryOperators: true
BreakConstructorInitializersBeforeComma: true
ColumnLimit:     80
CommentPragmas:  '^ IWYU pragma:'
ConstructorInitializerAllOnOneLineOrOnePerLine: true
ConstructorInitializerIndentWidth: 4
ContinuationIndentWidth: 4
Cpp11BracedListStyle: true
DerivePointerAlignment: false
DisableFormat:   false
ExperimentalAutoDetectBinPacking: false
ForEachMacros:   [ foreach, Q_FOREACH, BOOST_FOREACH ]
IndentCaseLabels: false
IndentWidth:     4
IndentWrappedFunctionNames: false
KeepEmptyLinesAtTheStartOfBlocks: false
MacroBlockBegin: '^IPC_END_MESSAGE_MAP$'
MacroBlockEnd:   ''
MaxEmptyLinesToKeep: 1
NamespaceIndentation: None
ObjCBlockIndentWidth: 2
ObjCSpaceAfterProperty: false
ObjCSpaceBeforeProtocolList: false
PenaltyBreakBeforeFirstCallParameter: 1
PenaltyBreakComment: 300
PenaltyBreakFirstLessLess: 120
PenaltyBreakString: 1000
PenaltyExcessCharacter: 1000000
PenaltyReturnTypeOnItsOwnLine: 200
PointerAlignment: Left
SpaceAfterCStyleCast: false
SpaceBeforeAssignmentOperators: true
SpaceBeforeParens: ControlStatements
SpaceInEmptyParentheses: false
SpacesBeforeTrailingComments: 2
SpacesInAngles:  false
SpacesInContainerLiterals: true
SpacesInCStyleCastParentheses: false
SpacesInParentheses: false
SpacesInSquareBrackets: false
Standard:        Auto
TabWidth:        8
UseTab:          Never
...


EOF

echo "Building tooling"
make -j check-setup

