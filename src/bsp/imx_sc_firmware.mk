# Copyright 2016 Freescale Semiconductor
# Copyright 2017-2024 NXP
# Copyright 2019-2025 Variscite
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Variscite SCFW

imx_sc_firmware:
	@[ $(SOCFAMILY) != IMX -o $${MACHINE:0:5} != imx8q -o \
	   $(DISTROVARIANT) = base -o $(DISTROVARIANT) = tiny ] && exit || \
	$(call fbprint_b,"imx_sc_firmware") && \
	$(call repo-mngr,fetch,imx_sc_firmware,bsp) && \
	$(call repo-mngr,fetch,meta_variscite_bsp_imx) && \
	export TOOLS=$(PKGDIR)/apps/utils/scfw_toolchain && \
	if [ ! -d $(PKGDIR)/$$TOOLS/bin/arm-none-eabi-gcc ]; then \
		bld scfw_toolchain -r $(DISTROTYPE):$(DISTROVARIANT) -a $(DESTARCH); \
	fi && \
	mkdir -p $(PKGDIR)/bsp/imx_sc_firmware && \
	cd $(PKGDIR)/bsp/imx_sc_firmware && \
	cd $(PKGDIR)/bsp/imx_sc_firmware/src/scfw_export_mx8$${MACHINE:4:2}_b0 && \
	$(MAKE) clean-$${MACHINE:4:2} && \
	$(MAKE) $${MACHINE:4:2} R=B0 B=var_som V=1 && \
	mkdir -p $(FBOUTDIR)/bsp/imx_sc_firmware/$(MACHINE) && \
	cp -f $(PKGDIR)/bsp/imx_sc_firmware/src/scfw_export_mx8$${MACHINE:4:2}_b0/build_mx8$${MACHINE:4:2}_b0/scfw_tcm.bin \
		$(BSPDIR)/imx_mkimage/iMX8QM && \
	$(call fbprint_d,"imx_sc_firmware")
