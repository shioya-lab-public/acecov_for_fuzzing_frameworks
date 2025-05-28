# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG parent_image
FROM $parent_image

RUN apt-get update -y && \
    apt-get install -y wget libstdc++-8-dev libtool-bin automake flex bison \
    libglib2.0-dev libpixman-1-dev python3-setuptools unzip \
    apt-utils apt-transport-https ca-certificates \
    binutils
RUN apt-get install -y \
    build-essential \
    python3-dev \
    python3-setuptools \
    automake \
    cmake \
    git \
    flex \
    bison \
    libglib2.0-dev \
    libpixman-1-dev \
    cargo \
    libgtk-3-dev \
    # for QEMU mode
    ninja-build \
    gcc-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-plugin-dev \
    libstdc++-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-dev

RUN apt install -y lsb-release wget software-properties-common && wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 15

RUN update-alternatives \
    --install /usr/lib/llvm              llvm             /usr/lib/llvm-15  20 \
    --slave   /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-15  \
    --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-15 \
    --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-15 \
    --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-15 \
    --slave   /usr/bin/llvm-c-test       llvm-c-test      /usr/bin/llvm-c-test-15 \
    --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-15 \
    --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-15 \
    --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-15 \
    --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-15 \
    --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-15 \
    --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-15 \
    --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-15 \
    --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-15 \
    --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-15 \
    --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-15 \
    --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-15 \
    --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-15 \
    --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-15 \
    --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-15 \
    --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-15 \
    --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-15 \
    --slave   /usr/bin/llc               llc              /usr/bin/llc-15 \
    --slave   /usr/bin/opt               opt              /usr/bin/opt-15 && \
    update-alternatives \
    --install /usr/bin/clang                 clang                  /usr/bin/clang-15     20 \
    --slave   /usr/bin/clang++               clang++                /usr/bin/clang++-15 \
    --slave   /usr/bin/clang-cpp             clang-cpp              /usr/bin/clang-cpp-15

COPY fuzzer/aflpp.diff /aflpp.diff
RUN /bin/git clone --depth 1 -b v4.10c https://github.com/AFLplusplus/AFLplusplus.git /AFLplusplus && \
	/bin/git clone --depth 1 https://github.com/shioya-lab-public/AceCov.git /AFLplusplus/acecov && \
	/bin/git -C /AFLplusplus apply /AFLplusplus/acecov/aflpp.diff && \
	/bin/sed -i s@'#define MAP_SIZE_POW2 16'@'#define MAP_SIZE_POW2 17'@g /AFLplusplus/include/config.h
COPY acecov.env /AFLplusplus/acecov/.env
RUN unset CFLAGS CXXFLAGS && \
    export EMBED_INFO_BASE=/out/embed CC=/usr/bin/clang-15 CXX=/usr/bin/clang++-15 LLVM_CONFIG=/usr/bin/llvm-config-15 AFL_NO_X86=1 && \
    cd /AFLplusplus && PYTHON_INCLUDE=/ make && \
    cp utils/aflpp_driver/libAFLDriver.a /
RUN make -C /AFLplusplus/acecov/analysis && mv /AFLplusplus/acecov/analysis/plugin.so /AFLplusplus
