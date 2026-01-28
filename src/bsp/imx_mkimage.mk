# Copyright 2020-2024 NXP
#
# SPDX-License-Identifier: BSD-3-Clause

SOC_REV ?= "B0"

define imx_mkimage_target
    if [ ! -d $(BSPDIR)/imx_mkimage ]; then \
	$(call repo-mngr,fetch,imx_mkimage,bsp); \
    fi && \
    \
    if [ -n "$(IMX_MKIMAGE_PATCHES)" ] && [ ! -f $(BSPDIR)/imx_mkimage/.patchdone ]; then \
        cd $(BSPDIR)/imx_mkimage && \
        for patch in $(IMX_MKIMAGE_PATCHES); do \
            $(call fbprint_n,"Applying imx_mkimage patch $(FBDIR)/patch/imx_mkimage/$$patch for $(MACHINE)") && \
            git am $(FBDIR)/patch/imx_mkimage/$$patch; \
        done; \
        touch .patchdone; \
    fi; \
    \
    if [ ! -d $(BSPDIR)/firmware-imx ]; then \
	cd $(BSPDIR) && wget -q $(repo_firmware_imx_bin_url) -O firmware_imx.bin && chmod +x firmware_imx.bin && \
	./firmware_imx.bin --auto-accept && mv firmware-imx* firmware-imx && rm -f firmware_imx.bin; \
    fi && \
    if [ ! -d $(BSPDIR)/imx-seco/firmware/seco ]; then \
	cd $(BSPDIR) && wget -q $(repo_seco_bin_url) -O imx-seco.bin && chmod +x imx-seco.bin && \
	./imx-seco.bin --auto-accept && mv `basename -s .bin $(repo_seco_bin_url)` imx-seco && rm -f imx-seco.bin; \
    fi && \
    if [ ! -d $(BSPDIR)/oei/build/ ]; then \
	bld -m $(MACHINE) oei; \
    fi && \
    if [ ! -d $(BSPDIR)/fw_ele ]; then \
	cd $(BSPDIR) && wget -q $(repo_fw_ele_bin_url) -O fw_ele.bin && chmod +x fw_ele.bin && \
	./fw_ele.bin --auto-accept && mv `basename -s .bin $(repo_fw_ele_bin_url)` fw_ele && rm -f fw_ele.bin; \
    fi && \
    if [ ! -d $(BSPDIR)/fw_upower ]; then \
	cd $(BSPDIR) && wget -q $(repo_fw_upower_bin_url) -O fw_upower.bin && chmod +x fw_upower.bin && \
	./fw_upower.bin --auto-accept && mv `basename -s .bin $(repo_fw_upower_bin_url)` fw_upower && rm -f fw_upower.bin; \
    fi && \
    if [ ! -f $(BSPDIR)/imx-scfw/mx8qx-mek-scfw-tcm.bin ]; then \
	cd $(BSPDIR) && wget -q $(repo_scfw_bin_url) -O imx-scfw.bin && chmod +x imx-scfw.bin && \
	./imx-scfw.bin --auto-accept && mv `basename -s .bin $(repo_scfw_bin_url)` imx-scfw && rm -f imx-scfw.bin; \
    fi && \
    if [ ! -d $(BSPDIR)/imx_sc_firmware/ ]; then \
	bld imx_sc_firmware -r $(DISTROTYPE):$(DISTROVARIANT) -a $(DESTARCH); \
    fi && \
    if [ ! -d $(BSPDIR)/sm/build/ ]; then \
	bld -m $(MACHINE) sm; \
    fi && \
    if [ ! -d $(BSPDIR)/imx_mcore_demos ]; then \
	bld mcore_demo; \
    fi && \
    \
    if echo $1 | grep -qE ^imx8mp; then \
	SOC=iMX8MP; SOC_FAMILY=iMX8M; target=$${IMX_MKIMAGE_TARGET:-flash_evk}; \
    elif echo $1 | grep -qE ^imx8mm; then \
	SOC=iMX8MM; SOC_FAMILY=iMX8M; target=$${IMX_MKIMAGE_TARGET:-flash_evk}; \
    elif echo $1 | grep -qE ^imx8mn; then \
	SOC=iMX8MN; SOC_FAMILY=iMX8M; target=$${IMX_MKIMAGE_TARGET:-flash_evk}; \
    elif echo $1 | grep -qE ^imx8mq; then \
	SOC=iMX8M; SOC_FAMILY=iMX8M; target=$${IMX_MKIMAGE_TARGET:-flash_evk}; \
	cp -f $(BSPDIR)/firmware-imx/firmware/hdmi/cadence/signed_* $(BSPDIR)/imx_mkimage/$$SOC_FAMILY; \
    elif echo $1 | grep -qE ^imx8qm; then \
	SOC=iMX8QM; SOC_FAMILY=iMX8QM; target=$${IMX_MKIMAGE_TARGET:-flash_spl}; \
	cp -f $(BSPDIR)/imx-seco/firmware/seco/mx8qmb0-ahab-container.img $(BSPDIR)/imx_mkimage/iMX8QM; \
    elif echo $1 | grep -qE ^imx8qx; then \
	SOC=iMX8QX; SOC_FAMILY=iMX8QX; target=$${IMX_MKIMAGE_TARGET:-flash_spl}; \
	if [ $$SOC_REV = C0 ];  then \
		cp -f $(BSPDIR)/imx_sc_firmware/src/scfw_export_mx8qx_b0/build_mx8qx_b0/scfw_tcm.bin $(BSPDIR)/imx_mkimage/iMX8QX/scfw_tcm.bin; \
	else \
		cp -f $(BSPDIR)/imx-scfw/mx8qx-mek-scfw-tcm.bin $(BSPDIR)/imx_mkimage/iMX8QX/scfw_tcm.bin; \
	fi && \
	cp -f $(BSPDIR)/imx-seco/firmware/seco/mx8qx*-ahab-container.img $(BSPDIR)/imx_mkimage/iMX8QX; \
    elif echo $1 | grep -qE ^imx8ulp; then \
	SOC=iMX8ULP; SOC_FAMILY=iMX8ULP; target=$${IMX_MKIMAGE_TARGET:-flash_singleboot_m33}; \
	cp $(BSPDIR)/fw_ele/mx8ulpa2-ahab-container.img $(BSPDIR)/imx_mkimage/iMX8ULP; \
	cp $(BSPDIR)/fw_upower/upower_a1.bin $(BSPDIR)/imx_mkimage/iMX8ULP/upower.bin; \
	cp $(BSPDIR)/imx_mcore_demos/imx8ulp-m33-demo/imx8ulp_m33_TCM_rpmsg_lite_str_echo_rtos.bin $(BSPDIR)/imx_mkimage/iMX8ULP/m33_image.bin; \
    elif echo $1 | grep -qE ^imx91; then \
	SOC=iMX91; SOC_FAMILY=iMX91; target=$${IMX_MKIMAGE_TARGET:-flash_singleboot}; \
	cp $(BSPDIR)/fw_ele/mx91a*-ahab-container.img $(BSPDIR)/imx_mkimage/iMX91; \
	cp $(BSPDIR)/fw_upower/upower_a*.bin $(BSPDIR)/imx_mkimage/iMX91/; \
    elif echo $1 | grep -qE ^imx93; then \
	SOC=iMX93; SOC_FAMILY=iMX93; target=$${IMX_MKIMAGE_TARGET:-flash_singleboot}; \
	cp $(BSPDIR)/fw_ele/mx93a*-ahab-container.img $(BSPDIR)/imx_mkimage/iMX93; \
	cp $(BSPDIR)/fw_upower/upower_a*.bin $(BSPDIR)/imx_mkimage/iMX93/; \
	cp $(BSPDIR)/imx_mcore_demos/imx93-m33-demo/imx93-11x11-evk_m33_TCM_rpmsg_lite_str_echo_rtos.bin \
	   $(BSPDIR)/imx_mkimage/iMX93/m33_image.bin; \
    elif echo $1 | grep -qE ^imx95; then \
	SOC=iMX95; SOC_FAMILY=iMX95; target=$${IMX_MKIMAGE_TARGET:-flash_singleboot}; \
	cp $(BSPDIR)/fw_ele/mx95a0-ahab-container.img $(BSPDIR)/imx_mkimage/iMX95; \
	cp $(BSPDIR)/oei/build/mx95lp5/tcm/oei-m33-tcm.bin $(BSPDIR)/imx_mkimage/iMX95; \
	cp $(BSPDIR)/oei/build/mx95lp5/ddr/oei-m33-ddr.bin $(BSPDIR)/imx_mkimage/iMX95; \
	cp $(BSPDIR)/sm/build/mx95evk/m33_image.bin $(BSPDIR)/imx_mkimage/iMX95; \
    fi && \
    cp -f $(BSPDIR)/firmware-imx/firmware/ddr/synopsys/*.bin $(BSPDIR)/imx_mkimage/$$SOC_FAMILY; \
    \
    cd $(BSPDIR)/imx_mkimage && \
    $(MAKE) clean && $(MAKE) bin && \
    $(MAKE) SOC=$$SOC_FAMILY mkimage_imx8 && \
    \
    bl32=$(PKGDIR)/apps/security/optee_os/out/arm-plat-imx/core/tee_$$brd.bin && \
    if [ "$(CONFIG_OPTEE)" = y -a ! -f $$bl32 ]; then \
	CONFIG_OPTEE=y bld optee_os -m $$brd; \
    fi && \
    [ $${MACHINE:0:7} = imx8ulp ] && plat=$${MACHINE:0:7} || plat=$${MACHINE:0:6} && \
    [ $${MACHINE:0:4} = imx9 ] && plat=$${MACHINE:0:5} || true && \
    cp -t $(BSPDIR)/imx_mkimage/$$SOC_FAMILY \
	$(BSPDIR)/firmware-imx/firmware/hdmi/cadence/signed*_imx8m.bin \
	$$opdir/spl/u-boot-spl.bin $$opdir/u-boot.bin \
	$$opdir/arch/arm/dts/*$${plat}*.dtb \
	$$opdir/u-boot-nodtb.bin && \
    if [ "$(CONFIG_OPTEE)" = y -a -f $$bl32 ]; then \
	cp -f $$bl32 $(BSPDIR)/imx_mkimage/$$SOC_FAMILY/tee.bin; \
    fi && \
    cp -f $$opdir/tools/mkimage $(BSPDIR)/imx_mkimage/$$SOC_FAMILY/mkimage_uboot && \
    cp -f $(BSPDIR)/atf/build/$$plat/release/bl31.bin $(BSPDIR)/imx_mkimage/$$SOC_FAMILY/ && \
    \
    if [ $${MACHINE:0:6} = imx8qm ];  then \
	$(MAKE) SOC=iMX8QM -C iMX8QM -f soc.mak $$target; \
    elif [ $${MACHINE:0:6} = imx8qx ]; then \
	$(MAKE) SOC=iMX8QX REV=$$SOC_REV -C iMX8QX -f soc.mak $$target $${IMX_MKIMAGE_DTBS:+dtbs="$$IMX_MKIMAGE_DTBS"} ; \
    elif [ $${MACHINE:0:5} = imx91 ]; then \
        $(MAKE) SOC=iMX91 REV=A0 -C iMX91 -f soc.mak $$target; \
    elif [ $${MACHINE:0:5} = imx93 ]; then \
	$(MAKE) SOC=iMX93 REV=A1 -C iMX93 -f soc.mak $$target; \
    elif [ $${MACHINE:0:5} = imx95 ]; then \
	cd $(BSPDIR)/imx_mkimage/$$SOC_FAMILY/ && \
	$(MAKE) REV=A0 OEI=YES LPDDR_TYPE=lpddr5 LPDDR_FUNC=train -f soc.mak $$target && \
	cd $(BSPDIR)/imx_mkimage; \
    fi && \
    if [ $${MACHINE:0:5} = imx8m ]; then \
	$(MAKE) SOC=$$SOC $(REV_OPTION) $$target $${IMX_MKIMAGE_DTBS:+dtbs="$$IMX_MKIMAGE_DTBS"} ; \
    fi && \
    mkdir -p $(FBOUTDIR)/bsp/imx-mkimage/$$brd && \
    cp $$SOC_FAMILY/flash.bin $(FBOUTDIR)/bsp/imx-mkimage/$$brd/flash.bin;
endef
