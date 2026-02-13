# Copyright 2025 Variscite
#
# SPDX-License-Identifier: BSD-3-Clause


# Variscite Openthread


openthread:
	@[ $(SOCFAMILY) != IMX -o $(DISTROVARIANT) = base -o $(DISTROVARIANT) = tiny ] && exit || \
	$(call fbprint_b,"openthread") && \
	$(call repo-mngr,fetch,openthread,apps/connectivity) && \
	SOURCE="$(PKGDIR)/apps/connectivity/openthread" && \
	mkdir -p $$SOURCE && \
	cd $$SOURCE && \
	export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && \
	export CXX="$(CROSS_COMPILE)g++ --sysroot=$(RFSDIR)" && \
	OT_OPT=" \
			-GNinja \
			-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
			-DOT_COMPILE_WARNING_AS_ERROR=OFF \
			-DOT_PLATFORM=posix \
			-DOT_SLAAC=ON \
			-DOT_BORDER_AGENT=ON \
			-DOT_BORDER_ROUTER=ON \
			-DOT_COAP=ON \
			-DOT_COAP_BLOCK=ON \
			-DOT_COAP_OBSERVE=ON \
			-DOT_COAPS=ON \
			-DOT_COMMISSIONER=ON \
			-DOT_CHANNEL_MANAGER=ON \
			-DOT_CHANNEL_MONITOR=ON \
			-DOT_CHILD_SUPERVISION=ON \
			-DOT_DATASET_UPDATER=ON \
			-DOT_DHCP6_CLIENT=ON \
			-DOT_DHCP6_SERVER=ON \
			-DOT_DIAGNOSTIC=ON \
			-DOT_DNS_CLIENT=ON \
			-DOT_ECDSA=ON \
			-DOT_IP6_FRAGM=ON \
			-DOT_JAM_DETECTION=ON \
			-DOT_JOINER=ON \
			-DOT_LEGACY=ON \
			-DOT_MAC_FILTER=ON \
			-DOT_NETDIAG_CLIENT=ON \
			-DOT_NEIGHBOR_DISCOVERY_AGENT=ON \
			-DOT_PING_SENDER=ON \
			-DOT_REFERENCE_DEVICE=ON \
			-DOT_SERVICE=ON \
			-DOT_SNTP_CLIENT=ON \
			-DOT_SRP_CLIENT=ON \
			-DOT_COVERAGE=OFF \
			-DOT_LOG_LEVEL_DYNAMIC=ON \
			-DOT_LOG_OUTPUT=PLATFORM_DEFINED \
			-DOT_POSIX_MAX_POWER_TABLE=ON \
			-DOT_DAEMON=ON \
			-DOT_THREAD_VERSION=1.3 \
			-DCMAKE_BUILD_TYPE=Release \
			-DOT_RCP_RESTORATION_MAX_COUNT=10 \
			-DOT_POSIX_RCP_HDLC_BUS=ON \
	" && \
	mkdir -p $$SOURCE/build_$(DISTROTYPE)_$(ARCH) && \
	cmake $$OT_OPT . -B build_$(DISTROTYPE)_$(ARCH) && \
	ninja -j$(JOBS) -C build_$(DISTROTYPE)_$(ARCH) && \
	cd $$SOURCE/build_$(DISTROTYPE)_$(ARCH)/src/posix/ && \
	install ot-daemon $(DESTDIR)/usr/bin/ && \
	install ot-ctl $(DESTDIR)/usr/bin/ot-client-ctl && \
	$(call fbprint_d,"openthread") \
