# Copyright 2025 Variscite
#
# SPDX-License-Identifier: BSD-3-Clause


# Variscite Openthread - iwxxx_spi


openthread_iwxxx_spi:
	@[ $(SOCFAMILY) != IMX -o $(DISTROVARIANT) = base -o $(DISTROVARIANT) = tiny ] && exit || \
	$(call fbprint_b,"openthread_iwxxx_spi") && \
	$(call repo-mngr,fetch,openthread_iwxxx_spi,apps/connectivity) && \
	SOURCE="$(PKGDIR)/apps/connectivity/openthread_iwxxx_spi" && \
	mkdir -p $$SOURCE && \
	cd $$SOURCE && \
	( \
		if [ ! -f .patchdone ]; then \
			for p in $(FBDIR)/patch/openthread_iwxxx_spi/*.patch; do \
				: # Skip 0062 patch for the imx9 family MACHINE \
				if [ $${MACHINE:0:4} = imx9 ] && [ $$(basename $$p) = 0062-host-handle-power-save-mode-on-ssp-rxd.patch ]; then \
					echo "Skipping $$p for $$MACHINE"; \
					continue; \
				fi; \
				git apply $$p || exit 1; \
			done; \
			touch .patchdone; \
		fi; \
	) && \
	if [ ! -f $(DESTDIR)/usr/include/linux/spi/spidev.h ]; then \
		bld linux-headers -r $(DISTROTYPE):$(DISTROVARIANT) -a $(DESTARCH); \
	fi && \
	# Prefer linux-headers UAPI over toolchain headers for SPI UAPI defines (e.g., SPI_MOSI_IDLE_LOW). \
	export CFLAGS="$(CFLAGS) -isystem $(DESTDIR)/usr/include" && \
	# Keep C++ in sync with C so the same UAPI headers are used. \
	export CXXFLAGS="$(CXXFLAGS) -isystem $(DESTDIR)/usr/include" && \
	export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && \
	export CXX="$(CROSS_COMPILE)g++ --sysroot=$(RFSDIR)" && \
	OT_OPT=" \
			-GNinja \
			-DOT_SLAAC=ON \
			-DOT_ANYCAST_LOCATOR=ON \
			-DOT_BLE_TCAT=ON \
			-DOT_BORDER_AGENT=ON \
			-DOT_BORDER_AGENT_EPSKC=ON \
			-DOT_BORDER_AGENT_ID=ON \
			-DOT_BORDER_ROUTER=ON \
			-DOT_CHANNEL_MANAGER=ON \
			-DOT_CHANNEL_MONITOR=ON \
			-DOT_COAP=ON \
			-DOT_COAPS=ON \
			-DOT_COAP_BLOCK=ON \
			-DOT_COAP_OBSERVE=ON \
			-DOT_COMMISSIONER=ON \
			-DOT_COMPILE_WARNING_AS_ERROR=ON \
			-DOT_COVERAGE=ON \
			-DOT_DATASET_UPDATER=ON \
			-DOT_DHCP6_CLIENT=ON \
			-DOT_DHCP6_SERVER=ON \
			-DOT_DIAGNOSTIC=ON \
			-DOT_DNSSD_SERVER=ON \
			-DOT_DNS_CLIENT=ON \
			-DOT_ECDSA=ON \
			-DOT_HISTORY_TRACKER=ON \
			-DOT_IP6_FRAGM=ON \
			-DOT_JAM_DETECTION=ON \
			-DOT_JOINER=ON \
			-DOT_LOG_LEVEL_DYNAMIC=ON \
			-DOT_MAC_FILTER=ON \
			-DOT_NEIGHBOR_DISCOVERY_AGENT=ON \
			-DOT_NETDATA_PUBLISHER=ON \
			-DOT_NETDIAG_CLIENT=ON \
			-DOT_PING_SENDER=ON \
			-DOT_RCP_TX_WAIT_TIME_SECS=5 \
			-DOT_REFERENCE_DEVICE=ON \
			-DOT_SERVICE=ON \
			-DOT_SNTP_CLIENT=ON \
			-DOT_SRP_CLIENT=ON \
			-DOT_SRP_SERVER=ON \
			-DOT_UPTIME=ON \
			-DOT_TCP=OFF \
			-DOT_LOG_OUTPUT=PLATFORM_DEFINED \
			-DOT_POSIX_MAX_POWER_TABLE=ON \
			-DOT_PLATFORM=posix \
			-DCMAKE_BUILD_TYPE=Release \
			-DOT_COVERAGE=0 \
			-DOT_COMPILE_WARNING_AS_ERROR=0 \
			-DOT_DAEMON=1 \
			-DOT_BACKBONE_ROUTER=1 \
			-DOT_FULL_LOGS=1 \
			-DOT_DUA=1 \
			-DOT_LINK_METRICS_INITIATOR=1 \
			-DOT_LINK_METRICS_SUBJECT=1 \
			-DOT_MLR=1 \
			-DOT_RCP_RESTORATION_MAX_COUNT=5 \
			-DOT_THREAD_VERSION=1.4 \
			-DOT_CHANNEL_MONITOR=0 \
			-DOT_VENDOR_NAME=NXP \
			-DOT_VENDOR_MODEL=IWxxx \
			-DOT_NETDIAG_VENDOR_INFO=ON \
			-DOT_POSIX_PRODUCT_CONFIG=/data/openthread/openthread.conf \
			-DOT_MLE_MAX_CHILDREN=128 \
			-DOT_MAC_CSL_REQUEST_AHEAD_US=16500 \
			-DOT_POSIX_RCP_SPI_BUS=ON \
	" && \
	mkdir -p $$SOURCE/build_$(DISTROTYPE)_$(ARCH) && \
	cmake $$OT_OPT . -B build_$(DISTROTYPE)_$(ARCH) && \
	ninja -j$(JOBS) -C build_$(DISTROTYPE)_$(ARCH) && \
	cd $$SOURCE/build_$(DISTROTYPE)_$(ARCH)/src/posix/ && \
	install ot-ctl $(DESTDIR)/usr/bin/ot-client-iwxxx-spi && \
	install ot-daemon $(DESTDIR)/usr/bin/ot-daemon-iwxxx-spi && \
	$(call fbprint_d,"openthread_iwxxx_spi") \
