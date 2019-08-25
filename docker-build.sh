#!/bin/bash

set -e

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

LLVM_BRANCH=${LLVM_BRANCH:-llvmorg-8.0.1}
TARGETS=${TARGETS:-install-clang install-clang-headers install-libclang install-libclang-python-bindings install-llvm-config}

IMAGE_PREFIX=${IMAGE_PREFIX:-dmrub/clang}
IMAGE_TAG=${IMAGE_TAG:-${LLVM_BRANCH}}
IMAGE_NAME=${IMAGE_PREFIX}:${IMAGE_TAG}

set -e

export LC_ALL=C
unset CDPATH

set -x
docker build -t "${IMAGE_NAME}" \
    --build-arg "LLVM_BRANCH=$LLVM_BRANCH" \
    --build-arg "TARGETS=$TARGETS" \
    "$THIS_DIR"

set +x
echo "Successfully built docker image $IMAGE_NAME"
