# Variables like $(RFSDIR) and $(CURDIR) are provided by the Flexbuild environment
APP_NAME = fulfil

$(APP_NAME): app-$(APP_NAME)

app-$(APP_NAME):
	@echo "Building $(APP_NAME) app..."
	# 1. Create target directories in the staging RFS
	install -d $(RFSDIR)/opt/fulfil/lfp
	install -d $(RFSDIR)/usr/local/sbin
	install -d $(RFSDIR)/etc/systemd/system/multi-user.target.wants

	# 2. Copy assets
	@find "$(CURDIR)/fulfil/files" -mindepth 1 -print
	cp -a $(CURDIR)/fulfil/files/* $(RFSDIR)/opt/fulfil/lfp/
	
	# 3. Install OpenMV camera udev ignorelist (prevents FAT corruption on camera reset)
	install -d $(RFSDIR)/etc/udev/mount.ignorelist.d
	echo "/dev/sda" > $(RFSDIR)/etc/udev/mount.ignorelist.d/openmv-camera
