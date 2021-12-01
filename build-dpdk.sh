#!/bin/bash

# https://doc.dpdk.org/guides-20.11/prog_guide/build-sdk-meson.html
# https://doc.dpdk.org/guides/sample_app_ug/compiling.html

yum install xz meson -y
yum install "@Development Tools" -y
yum install python3-pyelftools.noarch -y

cd /
curl -o dpdk.tar.xz https://fast.dpdk.org/rel/dpdk-21.11.tar.xz
tar -xf dpdk.tar.xz
cd dpdk-21.11
meson -Dplatform=generic build
cd build
meson configure -Dexamples=all
ninja

cd /
tar -czf dpdk-compiled.tar.gz dpdk-21.11
