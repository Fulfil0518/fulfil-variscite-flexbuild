# Variables like $(RFSDIR) and $(CURDIR) are provided by the Flexbuild environment
APP_NAME = fulfil

$(APP_NAME): app-$(APP_NAME)

app-$(APP_NAME):
	@echo "Building $(APP_NAME) app..."
	# 1. Create target directories in the staging RFS
	install -d $(RFSDIR)/opt/fulfil
	install -d $(RFSDIR)/usr/local/sbin
	install -d $(RFSDIR)/etc/systemd/system/multi-user.target.wants

	# 2. Copy assets
	cp -a $(CURDIR)/fulfil/files/* $(RFSDIR)/opt/fulfil/
	
	# 3. Install the firstboot script with executable permissions
	install -m 0755 $(CURDIR)/fulfil/files/firstboot.sh \
		$(RFSDIR)/usr/local/sbin/firstboot.sh

	# 4. Install and enable the firstboot service
	install -m 0644 $(CURDIR)/fulfil/files/fulfil-firstboot.service \
		$(RFSDIR)/etc/systemd/system/fulfil-firstboot.service
	
	ln -sf /etc/systemd/system/fulfil-firstboot.service \
		$(RFSDIR)/etc/systemd/system/multi-user.target.wants/fulfil-firstboot.service

	# 5. Install and enable the camera service
	install -m 0755 $(CURDIR)/fulfil/files/upload_cam_code.sh \
		$(RFSDIR)/opt/fulfil/upload_cam_code.sh

	install -m 0644 $(CURDIR)/fulfil/files/fulfil-camera-install.service \
		$(RFSDIR)/etc/systemd/system/fulfil-camera-install.service

	ln -sf /etc/systemd/system/fulfil-camera-install.service \
		$(RFSDIR)/etc/systemd/system/multi-user.target.wants/fulfil-camera-install.service

	# 6. Install the lfp-core service
	install -m 0644 $(CURDIR)/fulfil/files/lfp-core.service \
		$(RFSDIR)/etc/systemd/system/lfp-core.service
	ln -sf /etc/systemd/system/lfp-core.service \
		$(RFSDIR)/etc/systemd/system/multi-user.target.wants/lfp-core.service
