#!/bin/bash

# https://doc.dpdk.org/guides/linux_gsg/linux_eal_parameters.html
#CPUS=$(cat /proc/self/status | awk '/Cpus_allowed_list/ {print $NF}')
#LCORES=1,2,3
#MEMORY_CHANNELS=4
# https://doc.dpdk.org/guides/sample_app_ug/kernel_nic_interface.html
#PROMISCUOUS="-P"
#HEXMASK="0x1"
#PORTCONFIG="(0,1,2,3)"

# dpdk-21.11/build/examples/dpdk-l2fwd --vdev=net_tap1 -l 10,12,14,16 -n 4 -- -q 1 -p f --portmap="(0,1)"
# sh-5.1# dpdk-21.11/build/app/dpdk-testpmd -l 10,12,14,16 -n 4  -a $PCIDEVICE_OPENSHIFT_IO_ENP5S0F0VFIOPCI -- -i --port-topology=chained
# 

# CPUS=$(cat /proc/self/status | awk '/Cpus_allowed_list/ {print $NF}') dpdk-21.11/build/app/dpdk-testpmd --log-level=10 --legacy-mem --vdev=net_tap1 -l $CPUS -n 4  -a $PCIDEVICE_OPENSHIFT_IO_ENP5S0F0VFIOPCI -- --nb-cores=1 --nb-ports=2 --auto-start --total-num-mbufs=2048 --forward-mode=rxonly

# /dpdk-kni -l $LCORES  -n $MEMORY_CHANNELS -- $PROMISCUOUS -p $HEXMASK -m --config="$PORTCONFIG"
sleep infinity
