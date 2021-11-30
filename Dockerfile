FROM registry.fedoraproject.org/fedora:34
COPY build-kni.sh /build-kni.sh
RUN /bin/bash -x /build-kni.sh

FROM registry.fedoraproject.org/fedora:34
RUN yum install -y iputils iproute ethtool
COPY --from=0 /dpdk-21.11/build/examples/dpdk-kni /dpdk-kni
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"] 
