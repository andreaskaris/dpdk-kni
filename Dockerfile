FROM registry.fedoraproject.org/fedora:34
COPY build-kni.sh /build-kni.sh
RUN /bin/bash -x /build-kni.sh

FROM registry.fedoraproject.org/fedora:34
RUN yum install -y iputils iproute ethtool
COPY --from=0 /dpdk-compiled.tar.gz /dpdk-compiled.tar.gz
RUN tar -xf /dpdk-compiled.tar.gz
RUN rm -f /dpdk-compiled.tar.gz
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"] 
