# Variables like $(RFSDIR) and $(CURDIR) are provided by the Flexbuild environment
APP_NAME = fulfil

$(APP_NAME): app-$(APP_NAME)

app-$(APP_NAME):
	@echo "Building $(APP_NAME) app..."
	# 1. Create target directories in the staging RFS
	install -d $(RFSDIR)/opt/fulfil/lfp
	install -d $(RFSDIR)/usr/local/sbin
	install -d $(RFSDIR)/etc/systemd/system/multi-user.target.wants

	# 2. Install SSH public key for dev team access
	install -d -m 0700 -o 0 -g 0 $(RFSDIR)/root/.ssh
	install -m 0600 -o 0 -g 0 \
		$(CURDIR)/fulfil/files/common/authorized_keys \
		$(RFSDIR)/root/.ssh/authorized_keys

	# 3. Set root password
	printf 'root:%s\n' "$$(cat "$(CURDIR)/fulfil/files/common/root-password")" \
		| chpasswd --root "$(abspath $(RFSDIR))"

	# 4. Copy assets
	@find "$(CURDIR)/fulfil/files/lfp" -mindepth 1 -print
	cp -a $(CURDIR)/fulfil/files/lfp/* $(RFSDIR)/opt/fulfil/lfp/
	
	# 5. Install OpenMV camera udev ignorelist (prevents FAT corruption on camera reset)
	install -d $(RFSDIR)/etc/udev/mount.ignorelist.d
	echo "/dev/sda" > $(RFSDIR)/etc/udev/mount.ignorelist.d/openmv-camera
