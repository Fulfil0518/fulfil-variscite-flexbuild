# Copyright 2025 Variscite Ltd.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Target: cortexm_toolchain_cross
#
# Description:
#   Download and install the GCC toolchain for Cortex-M (arm-none-eabi),
#   required for building FreeRTOS and other embedded components.
#
# Variables:
#   CM_GCC - Toolchain version to be used (e.g., "12.3.rel1").
#            If it contains "rel", the binary release is downloaded
#            from the ARM Keil repository.
#            Otherwise, the gnu-rm package is downloaded from
#            developer.arm.com.
#   CORTEXM_TOOLCHAIN_SUPPORT - If set to "false", this rule will exit without running.

CM_GCC ?= "12.3.rel1"

CORTEXM_TOOLCHAIN_SUPPORT ?= true

cortexm_toolchain_cross:
	@[ $(CORTEXM_TOOLCHAIN_SUPPORT) = false ] && exit || \
	$(call fbprint_b,"cortexm_toolchain_cross") && \
	set -x && \
	if [ ! -d $(PKGDIR)/apps/utils/cortexm_toolchain_cross ]; then \
		mkdir -p $(PKGDIR)/apps/utils/cortexm_toolchain_cross; \
	fi && \
	cd $(PKGDIR)/apps/utils/cortexm_toolchain_cross && \
	if [ "$${CM_GCC#*rel}" != "${CM_GCC}" ]; then \
		if [ ! -f arm-gnu-toolchain-${CM_GCC}-x86_64-arm-none-eabi.tar.xz ]; then \
			wget https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/${CM_GCC}/binrel/arm-gnu-toolchain-${CM_GCC}-x86_64-arm-none-eabi.tar.xz && \
			tar -xf arm-gnu-toolchain-${CM_GCC}-x86_64-arm-none-eabi.tar.xz --strip-components=1; \
		fi \
	elif [ ! -f gcc-arm-none-eabi-${CM_GCC}-x86_64-linux.tar.bz2 ]; then \
		if [ "$${CM_GCC#*q}" != "${CM_GCC}" ]; then \
			wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/$${CM_GCC:0:6}$${CM_GCC:7:2}/gcc-arm-none-eabi-${CM_GCC}-x86_64-linux.tar.bz2; \
		else \
			wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/${CM_GCC}/gcc-arm-none-eabi-${CM_GCC}-x86_64-linux.tar.bz2; \
		fi && \
		tar -xf gcc-arm-none-eabi-${CM_GCC}-x86_64-linux.tar.bz2 --strip-components=1; \
	fi && \
	$(call fbprint_d,"cortexm_toolchain_cross")
