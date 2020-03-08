#! /bin/bash

set -e
set -x

ROOT_DIR=$PWD
ICU_VERSION=${ICU_VERSION:-64.2}
SENTENCEPIECE_VERSION=${SENTENCEPIECE_VERSION:-0.1.8}
PYBIND11_VERSION=${PYBIND11_VERSION:-2.4.3}

# Install pybind11
pip install pybind11==$PYBIND11_VERSION

# Install CMake
pip install "cmake==3.16.*" || pip install "cmake==3.13.*"

# Skip double installation of libraries
if [ -f built-$PYTHON_ARCH ]; then exit 0; fi
touch built-$PYTHON_ARCH

# Install ICU
curl -L -O https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION/./-}/icu4c-${ICU_VERSION/./_}-src.tgz
tar xf icu4c-*-src.tgz
cd icu/source
if [ "$RUNNER_OS" == "Windows" ]; then PYTHON_BACKUP=$PYTHON; PYTHON="echo Skipping"; fi
CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure --disable-shared --enable-static
if [ "$RUNNER_OS" == "Windows" ]; then PYTHON=$PYTHON_BACKUP; unset PYTHON_BACKUP; fi
make -j2 install
cd $ROOT_DIR

# Build SentencePiece
curl -L -o sentencepiece-${SENTENCEPIECE_VERSION}.tar.gz -O https://github.com/google/sentencepiece/archive/v${SENTENCEPIECE_VERSION}.tar.gz
tar zxf sentencepiece-${SENTENCEPIECE_VERSION}.tar.gz
cd sentencepiece-${SENTENCEPIECE_VERSION}
mkdir build; cd build
cmake ..
make -j2 install
cd $ROOT_DIR

# Build Tokenizer
mkdir build; cd build
cmake -DCMAKE_BUILD_TYPE=Release -DLIB_ONLY=ON -DWITH_ICU=ON ..
make -j2 install
cd $ROOT_DIR
