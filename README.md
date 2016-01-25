# A build system for C/C++ projects with nice emacs integration #

## Prerequisites ##
- You want to use LLVM, probably
- You use emacs

#### On the local system ####
- A usable c++ compiler
- GNU make

#### Emacs (all from elpa OK) ####
- projectile
- rtags

## Quick Start ##
```
mkdir my-project
cd my-project
git init
git submodule add git@github.com:stelfer/build.git
git commit -m "Initial commit"
ORGANIZATION="YOUR_ORGANIZATION_NAME" ./build/setup.sh my-project
```


