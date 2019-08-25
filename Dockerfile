# This file is distributed under the Apache 2.0 License
# See LICENSE.txt for details.

# Stage 1. Check out LLVM source code and run the build.
FROM ubuntu:18.04 as builder
LABEL maintainer "Dmitri Rubinstein <dmitri.rubinstein@dfki.de>"

# Install llvm build dependencies.
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential ca-certificates cmake python git \
        ninja-build; \
    rm -rf /var/lib/apt/lists/*

ARG LLVM_BRANCH
ENV LLVM_BRANCH ${LLVM_BRANCH:-llvmorg-8.0.1}

ENV CLANG_SRC_DIR /tmp/clang-src
WORKDIR ${CLANG_SRC_DIR}

RUN set -eux; \
    git clone -n https://github.com/llvm/llvm-project.git; \
    cd llvm-project; \
    git checkout "${LLVM_BRANCH}";

ENV CLANG_INSTALL_DIR /tmp/clang-install
ENV CLANG_BUILD_DIR /tmp/clang-build
WORKDIR ${CLANG_BUILD_DIR}

ARG TARGETS
ENV TARGETS ${TARGETS:-install-clang install-clang-headers install-libclang install-libclang-python-bindings install-llvm-config}

RUN set -eux; \
    cmake -GNinja \
          -DCMAKE_INSTALL_PREFIX="$CLANG_INSTALL_DIR" \
          -DLLVM_ENABLE_PROJECTS=clang \
          -DLLVM_TOOL_CLANG_TOOLS_EXTRA_BUILD=OFF \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_TARGETS_TO_BUILD=X86 \
          -DLLVM_BUILD_LLVM_DYLIB=1 \
          -DCLANG_PYTHON_BINDINGS_VERSIONS="2.7;3.6" \
          -DCLANG_BUILD_TOOLS=ON \
          "${CLANG_SRC_DIR}/llvm-project/llvm"; \
    ninja ${TARGETS};

# Stage 2. Produce a minimal release image with build results.
FROM ubuntu:18.04
LABEL maintainer "Dmitri Rubinstein <dmitri.rubinstein@dfki.de>"
# Copy clang installation into this container.
COPY --from=builder /tmp/clang-install/ /usr/local/
# C++ standard library and binutils are already included in the base package.
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends python; \
    rm -rf /var/lib/apt/lists/*;
ENV PYTHONPATH $PYTHONPATH:/usr/local/lib/python2.7/site-packages
