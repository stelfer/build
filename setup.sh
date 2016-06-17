#!/bin/bash
#
# Copyright (C) 2016 by AT&T Services Inc. - MIT License. See LICENSE.txt
#
# Automatically generate the basic files
#
set -e

bits=32
# Figure out the host
v=($(file -Ls -F":" /bin/sh))
case ${v[2]} in
    64-bit)
	bits=64;;
esac


function get_default {
    local _x=$1
    local val
    case $1 in
	ORGANIZATION)
	    val=$(id -F);;
	HOST_CC)
	    val=$(which gcc);;
	HOST_CXX)
	    val=$(which g++);;
	TARGET_ARCH)
	    val=$(uname -m);;
	TARGET_ABI)
	    val="elf";;
	TARGET)
	    val="${TARGET_ARCH}-${TARGET_ABI}";;
	TARGET_FORMAT)
	    val="${TARGET_ABI}${bits}";;
	TARGET_CCARCH)
	    val="-m${bits}";;
	TARGET_LDEMU)
	    val="${TARGET_ABI}_${TARGET_ARCH}";;
    esac
    eval $_x=$val
}

function get_var {
    eval _y=\${$1}
    if [ -z $_y ]
    then
	get_default $1
    fi
    eval _y=\${$1}
    read -p "$1 [$_y]: " x
    local _z=$1
    eval $_z=\"${x:-$_y}\"
}


function backup {
    if [ -f $1 ]; then
	echo "Backing up Existing $1"
	cp $1 $1.bk
    fi

}


if [ x$INTERACTIVE != x"no" ]
then

    tgt_files=""
    tgt_types=""
    while read line
    do
	tgt_files="$tgt_files $line"
	tgt_types="$tol $(basename $line .tar.xz)"
    done <<< "$(ls -C1 build/targets/*.tar.xz)"

    echo "Select target os:"
    tgt_types=( $tgt_types )
    i=0
    for t in ${tgt_types[@]}
    do
	echo "[$i] $t"
	i=$(( i + 1 ))
    done
    read -p "> " osi


    tgt_type=${tgt_types[$osi]}
    tgt_tuple=( ${tgt_type//-/ } )
    TARGET_OS_FLAVOR=${tgt_tuple[0]}
    TARGET_OS_VERSION=${tgt_tuple[1]}
    TARGET_ARCH=${tgt_tuple[2]}

    get_var ORGANIZATION
    get_var HOST_CC
    get_var HOST_CXX
    get_var TARGET_ARCH
    get_var TARGET_ABI
    get_var TARGET
    get_var TARGET_FORMAT
    get_var TARGET_CCARCH
    get_var TARGET_LDEMU
    get_var TARGET_HOSTS
fi

cat <<EOF > .setup.sh
#!/bin/bash

# This script will re-run setup 
export ORGANIZATION=$ORGANIZATION
export HOST_CC=$HOST_CC
export HOST_CXX=$HOST_CXX
export TARGET_ARCH=$TARGET_ARCH
export TARGET_ABI=$TARGET_ABI
export TARGET=$TARGET
export TARGET_FORMAT=$TARGET_FORMAT
export TARGET_CCARCH=$TARGET_CCARCH
export TARGET_LDEMU=$TARGET_LDEMU
export TARGET_HOSTS=$TARGET_HOSTS
export TARGET_OS_FLAVOR=$TARGET_OS_FLAVOR
export TARGET_OS_VERSION=$TARGET_OS_VERSION
export TARGET_ARCH=$TARGET_ARCH
export INTERACTIVE=no

sh $0

EOF

echo "Creating Makefile"
backup "Makefile"    
cat <<EOF > Makefile
#
# Automatically generated on $(date +%FT%T%Z)
#

# We need these to bootstrap our toolchain
HOST_CC			:= ${HOST_CC}
HOST_CXX		:= ${HOST_CXX}

TARGET_ARCH		:= ${TARGET_ARCH}
TARGET_ABI		:= ${TARGET_ABI}
TARGET			?= ${TARGET_ARCH}-${TARGET_ABI}
TARGET_FORMAT		:= ${TARGET_FORMAT}
TARGET_CCARCH		:= ${TARGET_CCARCH}
TARGET_LDEMU		:= ${TARGET_LDEMU}
TARGET_OS_FLAVOR	:= ${TARGET_OS_FLAVOR}
TARGET_OS_VERSION	:= ${TARGET_OS_VERSION}


# Include the mothership
include build/build.mk

# Include your projects under projects/PROJECT
include projects/**/Makefile

# Include your tests here under test/PROJECT
include test/**/Makefile
EOF

echo "Setting up directories"
DIRS="test projects"
for d in $DIRS; do
    mkdir -p $d
done

echo "Setting up license"
backup "LICENSE.txt"
cp build/LICENSE.txt LICENSE.txt

echo "Setting up emacs c++-style"
backup ".build-c-style.el"
cat <<EOF > .build-c-style.el
(defconst build-c-style
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
    (c-echo-syntactic-information-p . t)) "build Programming Style")

(provide 'build-c-style)

EOF

echo "Setting up .dir-locals.el "
backup ".dir-locals.el"
cat <<EOF > .dir-locals.el
((nil . ((eval . (setenv "ORGANIZATION" "$ORGANIZATION - MIT License. See LICENSE.txt"))
	 (eval . (let ((path "${PWD}/build/bin"))
		   (unless (string= path (car (parse-colon-path (getenv "PATH"))))
		     (setenv "PATH" (concat path ":" (getenv "PATH"))))
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
			(unless (assoc "build-c-style" c-style-alist)
			  (load (concat "${PWD}/" ".build-c-style.el"))
			  (c-add-style "build-c-style" build-c-style))
			(c-set-style "build-c-style")
			(unless rtags-path
			  (setq rtags-path "${PWD}/build/bin")
			  (setq rtags-process-flags "-d ${PWD}/build/.rtags"))
			(rtags-start-process-unless-running)))))
 (c-mode . ((eval . (progn
			(unless (assoc "build-c-style" c-style-alist)
			  (load (concat "${PWD}/" ".build-c-style.el"))
			  (c-add-style "build-c-style" build-c-style))
			(c-set-style "build-c-style")
			(unless rtags-path
			  (setq rtags-path "${PWD}/build/bin")
			  (setq rtags-process-flags "-d ${PWD}/build/.rtags"))
			(rtags-start-process-unless-running))))))
EOF

echo "Setting up clang-format"
backup ".clang-format"
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

