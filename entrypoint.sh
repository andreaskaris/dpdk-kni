#!/bin/bash

# https://doc.dpdk.org/guides/linux_gsg/linux_eal_parameters.html
LCORES=1,2,3
MEMORY_CHANNELS=4
# https://doc.dpdk.org/guides/sample_app_ug/kernel_nic_interface.html
PROMISCUOUS="-P"
HEXMASK="0x3"
PORTCONFIG="(0,1,2,3)"

/dpdk-kni -l $LCORES  -n $MEMORY_CHANNELS -- $PROMISCUOUS -p $HEXMASK -m --config="$PORTCONFIG"
sleep infinity
