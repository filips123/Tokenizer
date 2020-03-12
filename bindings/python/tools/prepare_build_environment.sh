#! /bin/bash

set -e
set -x

ROOT_DIR=$PWD
ICU_VERSION=${ICU_VERSION:-64.2}
SENTENCEPIECE_VERSION=${SENTENCEPIECE_VERSION:-0.1.8}
PYBIND11_VERSION=${PYBIND11_VERSION:-2.4.3}

# Install pybind11
pip install pybind11==$PYBIND11_VERSION

# Install CMake on Windows and macOS
if [[ ! -z "${RUNNER_OS}" ]]; then pip install "cmake==3.13.*" || pip install "cmake==3.16.*"; fi

# Skip double installation of libraries
if [ -f built-$PYTHON_ARCH ]; then exit 0; fi
touch built-$PYTHON_ARCH

# Install CMake on manylinux
if [[ -z "${RUNNER_OS}" ]]; then /opt/python/cp37-cp37m/bin/pip install "cmake==3.13.*" && cp /opt/python/cp37-cp37m/bin/cmake /usr/bin; fi

# Install ICU
curl -L -O https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION/./-}/icu4c-${ICU_VERSION/./_}-src.tgz
tar xf icu4c-*-src.tgz
cd icu/source
CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure --disable-shared --enable-static || true
if [[ "${RUNNER_OS}" == "Windows" ]]; then sed -i '1 i\SHELL := /bin/sh\n' Makefile; fi
make -j2 install
cd $ROOT_DIR

# Build SentencePiece
curl -L -o sentencepiece-${SENTENCEPIECE_VERSION}.tar.gz -O https://github.com/google/sentencepiece/archive/v${SENTENCEPIECE_VERSION}.tar.gz
tar zxf sentencepiece-${SENTENCEPIECE_VERSION}.tar.gz
cd sentencepiece-${SENTENCEPIECE_VERSION}
mkdir build; cd build
cmake ..
if [[ "${RUNNER_OS}" == "Windows" ]]; then sed -i '1 i\SHELL := /bin/sh\n' Makefile; fi
make -j2 install
cd $ROOT_DIR

# Set TOKENIZER_ROOT for macOS
if [[ "${RUNNER_OS}" == "macOS" ]]; then TOKENIZER_ROOT=$ROOT_DIR/install; fi

# Build Tokenizer
mkdir build; cd build
cmake -DCMAKE_INSTALL_PREFIX=$TOKENIZER_ROOT -DCMAKE_BUILD_TYPE=Release -DLIB_ONLY=ON -DWITH_ICU=ON ..
if [[ "${RUNNER_OS}" == "Windows" ]]; then sed -i '1 i\SHELL := /bin/sh\n' Makefile; fi
make -j2 install
cd $ROOT_DIR
