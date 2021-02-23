#!/bin/bash -ex
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
OUTPUT_DIR=$HOME/nvim
mkdir -p $OUTPUT_DIR
cd $SCRIPT_DIR
git clean -fxd
make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$OUTPUT_DIR
make install
