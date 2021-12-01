#!/bin/bash -x

# https://doc.dpdk.org/guides/linux_gsg/linux_eal_parameters.html
# https://doc.dpdk.org/guides/sample_app_ug/kernel_nic_interface.html

echo "Get PCI_DEVICE_ID from filter expression"
PCI_DEVICE_FILTER=${PCI_DEVICE_FILTER:-PCIDEVICE_OPENSHIFT_IO}
PCI_DEVICE_ID=$(env | grep $PCI_DEVICE_FILTER | awk -F '=' '{print $NF}' | head -1) 

echo "Get MAC ADDRESS"
MACADDR=$(echo "macaddr 0" | /dpdk-ethtool -a $PCI_DEVICE_ID | awk '/Port 0 MAC Address/ {print $NF}')
echo "Get pinned CPUs"
CPUS=$(cat /proc/self/status | awk '/Cpus_allowed_list/ {print $NF}')

echo "Run testpmd and forward everything between dp0 tunnel interface and vfio interface"
/dpdk-testpmd --log-level=10 --legacy-mem --vdev=net_tap1,iface=dp0,mac=${MACADDCR} -l $CPUS -n 4 -a $PCI_DEVICE_ID -- --nb-cores=1 --nb-ports=2  --total-num-mbufs=2048 --auto-start &

sleep 15

if [ "$IP_ADDRESS" != "" ];then
	ip address add dev dp0 $IP_ADDRESS
fi

sleep infinity
