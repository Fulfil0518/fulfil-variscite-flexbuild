# Copyright 2025 Variscite Ltd.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Target: scfw_toolchain
#
# Description:
#   Download and install the ARM GCC 8-2018-q4-major toolchain
#   (arm-none-eabi), required to build the System Controller
#   Firmware (SCFW) for NXP i.MX8 platforms.
#
# Variables:
#   SCFW_SUPPORT - If set to "false", this rule will exit without running.
#
# Notes:
#   The SCFW requires this specific compiler version. Using a
#   different arm-none-eabi release may lead to build errors or
#   unexpected runtime issues.

SCFW_SUPPORT ?= true

scfw_toolchain:
	@[ $(SCFW_SUPPORT) = false ] && exit || \
	$(call fbprint_b,"scfw_toolchain") && \
	set -x && \
	if [ ! -d $(PKGDIR)/apps/utils/scfw_toolchain ]; then \
		mkdir -p $(PKGDIR)/apps/utils/scfw_toolchain; \
	fi && \
	cd $(PKGDIR)/apps/utils/scfw_toolchain && \
	if [ ! -f gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz ]; then \
		wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/8-2018q4/gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz && \
		tar -xf gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz; \
	fi && \
	$(call fbprint_d,"scfw_toolchain")
