build-dpdk:
	buildah bud -f Dockerfile.fulldpdk -t dpdk

build-testpmd:
	buildah bud -f Dockerfile.testpmd -t testpmd
