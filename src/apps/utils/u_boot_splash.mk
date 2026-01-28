# Copyright 2021-2025 Variscite
#
# SPDX-License-Identifier: BSD-3-Clause


# Copy U-Boot's splash.bmp to rootfs

u_boot_splash:
	@[ $(SOCFAMILY) != IMX -o $(DISTROVARIANT) = base -o $(DISTROVARIANT) = tiny ] && exit || \
	$(call fbprint_b,"u_boot_splash") && \
	$(call repo-mngr,fetch,meta_variscite_sdk_common) && \
	install -d $(DESTDIR)/boot && \
	install -m 0644 $(PKGDIR)/meta_variscite_sdk_common/recipes-bsp/u-boot/u-boot-splash/splash.bmp $(DESTDIR)/boot && \
	$(call fbprint_d,"u_boot_splash") \
