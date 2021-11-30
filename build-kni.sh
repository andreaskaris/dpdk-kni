#!/bin/bash

# https://doc.dpdk.org/guides-20.11/prog_guide/build-sdk-meson.html
# https://doc.dpdk.org/guides/sample_app_ug/compiling.html

yum install xz meson -y
yum install "@Development Tools"
yum install python3-pyelftools.noarch -y
curl -o dpdk.tar.xz https://fast.dpdk.org/rel/dpdk-21.11.tar.xz
tar -xf dpdk.tar.xz
cd dpdk-21.11
meson build
cd build
meson configure -Dexamples=kni
ninja
