## Purpose

The purpose is to troubleshoot SR-IOV interfaces which are bound to the vfio-pci driver and to forward packets from user space to the pod's kernel space on interface `dp0`.

This repository should rather be named dpdk-testpmd. The testpmd container allows running a privileged pod which will run testpmd.
The testpmd will have the pod's single VFIO-PCI interface connected on one end, and a tunnel interface to the pod's kernel on the other end.
All packets are forwarded with testpmd between the vfio-pci interface and the pod's kernel space.

## How to run a testpod

Make sure to check all prerequisites, first. See the `Prerequisites` section for more info.

Deploy the net-attach-def in the application namespace:
~~~
# oc new-project sriov-testing
# cat <<'EOF' > sriovnetwork-enp5s0f0.yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-net-enp5s0f0-vfiopci
  namespace: openshift-sriov-network-operator
spec:
  networkNamespace: sriov-testing
  ipam: '{ "type": "static" }'
  vlan: 109
  resourceName: enp5s0f0Vfiopci
  trust: "on"
  capabilities: '{ "mac": true, "ips": true }'
EOF
# oc apply -f sriovnetwork-enp5s0f0.yaml
~~~

Now, adjust the `testpmd.yaml` file according to your settings:
~~~
apiVersion: v1
kind: Pod
metadata:
  name: testpmd
  annotations:
    k8s.v1.cni.cncf.io/networks: '[
{
"name": "sriov-net-enp5s0f0-vfiopci",
"mac": "20:04:0f:f1:88:01",
"ips": ["192.168.109.10/24"]
}
]'
spec:
  containers:
  - name: testpmd
    image: quay.io/akaris/dpdk-kni:v1.0
    env:
      - name: PCI_DEVICE_FILTER
        value: "PCIDEVICE_OPENSHIFT_IO"
      - name: IP_ADDRESS
        value: "192.168.109.10/24"
    imagePullPolicy: IfNotPresent
    command: ["/bin/bash", "-c", "/entrypoint.sh"]
    resources:
      limits:
        hugepages-1Gi: "1Gi"
        memory: "2Gi"
        cpu: "4000m"
      requests:
        hugepages-1Gi: "1Gi"
        memory: "2Gi"
        cpu: "4000m"
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /dev/hugepages
      name: hugepage
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
~~~

The `PCI_DEVICE_FILTER` should be o.k. as is for OpenShift deployments. It will run `env | grep PCIDEVICE_OPENSHIFT_IO` and take the first value that it can find here as the PCI address of the SR-IOV interface.
The `IP_ADDRESS` must be adjusted and must contain the IP address and subnet mask that the vfio-pci interface (or rather it's kernel tunnel endpoint) should have. The IP will be statically added.
Adjust the `k8s.v1.cni.cncf.io/networks:` annotation according to your needs and environment.
Adjust the `imagePullPolicy: IfNotPresent` if needed.

After adjusting the file, apply it:
~~~
# oc apply -f testpmd.yaml
~~~

### Prerequisites

First of all, deploy the SR-IOV operator and the Performance Addon Operator. The following steps are for OpenShift 4.6 and will vary depending on the OpenShift version. You will need working SR-IOV, CPU isolation and memory hugepages.

#### Performance addon operator

Install the Performance Addon Operator (https://docs.openshift.com/container-platform/4.6/scalability_and_performance/cnf-performance-addon-operator-for-low-latency-nodes.html):
~~~
# cat <<'EOF' > pao-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-performance-addon-operator
EOF
# oc apply -f pao-namespace.yaml
# cat <<'EOF' > pao-operatorgroup.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-performance-addon-operator
  namespace: openshift-performance-addon-operator
spec:
  targetNamespaces:
  - openshift-performance-addon-operator
EOF
# oc apply -f pao-operatorgroup.yaml
# cat <<'EOF' > pao-sub.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-performance-addon-operator-subscription
  namespace: openshift-performance-addon-operator
spec:
  channel: "4.6" 
  name: performance-addon-operator
  source: redhat-operators 
  sourceNamespace: openshift-marketplace
EOF
# oc create -f pao-sub.yaml
~~~

Once the Performance Addon Operator was successfully installed, go ahead and create the PerformanceProfile and wait until it's deployed correctly. The nodes should have 1G hugepages and CPU pinning enabled after this:
~~~
# oc label mcp worker machineconfiguration.openshift.io/role=worker
# cat <<'EOF' > pp.yaml
apiVersion: performance.openshift.io/v1
kind: PerformanceProfile
metadata:
  name: performance
spec:
  cpu:
    isolated: "8-39"
    reserved: "0-7"
  hugepages:
    defaultHugepagesSize: "1G"
    pages:
    - size: "1G"
      count: 16
      node: 0
    - size: "1G"
      count: 16
      node: 1
  nodeSelector:
    node-role.kubernetes.io/worker: ""
EOF
# oc apply -f pp.yaml
~~~

#### SR-IOV 

Make sure to set up SR-IOV operator (https://docs.openshift.com/container-platform/4.6/networking/hardware_networks/installing-sriov-operator.html):
~~~
# cat <<'EOF' > sriov-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-sriov-network-operator
  labels:
    openshift.io/run-level: "1"
EOF
# oc apply -f sriov-namespace.yaml
# cat <<'EOF' > sriov-operatorgroup.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: sriov-network-operators
  namespace: openshift-sriov-network-operator
spec:
  targetNamespaces:
  - openshift-sriov-network-operator
EOF
# oc apply -f sriov-operatorgroup.yaml
# cat <<'EOF' > sriov-sub.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sriov-network-operator-subscription
  namespace: openshift-sriov-network-operator
spec:
  channel: "4.6"
  name: sriov-network-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
# oc apply -f sriov-sub.yaml
~~~

After installation of the SR-IOV operator, deploy the SriovNetworkNodePolicy:
~~~
# cat <<'EOF' > ./networkpolicy-vfiopci.yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: sriov-enp5s0f0-vfiopci
  namespace: openshift-sriov-network-operator
spec:
  resourceName: enp5s0f0Vfiopci
  nodeSelector:
    feature.node.kubernetes.io/network-sriov.capable: "true"
  priority: 10
  mtu: 1500
  numVfs: 5
  nicSelector:
    pfNames: ["enp5s0f0"]
  deviceType: "vfio-pci"
  isRdma: false
EOF
# oc apply -f ./networkpolicy-vfiopci.yaml
~~~

## How to build the containers

### testpmd container

The testpmd container can be built with:
~~~
make build-testpmd
~~~

### dpdk binaries

Dpdk binaries can be built with:
~~~
make build-dpdk
~~~
