#!/bin/bash -x

# https://doc.dpdk.org/guides/linux_gsg/linux_eal_parameters.html
# https://doc.dpdk.org/guides/sample_app_ug/kernel_nic_interface.html

func addip() {
	if [ "$IP_ADDRESS" != "" ];then
	while true; do
		echo "Adding IP address to dp0"
		if ip address add dev dp0 $IP_ADDRESS; then
			break
		fi
		echo "Failed adding IP address to dp0, sleeping for 5 seconds"
		sleep 5
	done
	fi
}

echo "Get PCI_DEVICE_ID from filter expression"
PCI_DEVICE_FILTER=${PCI_DEVICE_FILTER:-PCIDEVICE_OPENSHIFT_IO}
PCI_DEVICE_ID=$(env | grep $PCI_DEVICE_FILTER | awk -F '=' '{print $NF}' | head -1) 

echo "Get MAC ADDRESS"
MACADDR=$(echo "macaddr 0" | /dpdk-ethtool -a $PCI_DEVICE_ID | awk '/Port 0 MAC Address/ {print $NF}')
echo "Get pinned CPUs"
CPUS=$(cat /proc/self/status | awk '/Cpus_allowed_list/ {print $NF}')

echo "Run addip script in background"
addip &

echo "Run testpmd and forward everything between dp0 tunnel interface and vfio interface"
/dpdk-testpmd --log-level=10 --legacy-mem --vdev=net_tap1,iface=dp0,mac=${MACADDR} -l $CPUS -n 4 -a $PCI_DEVICE_ID -- --nb-cores=1 --nb-ports=2  --total-num-mbufs=2048 --auto-start
