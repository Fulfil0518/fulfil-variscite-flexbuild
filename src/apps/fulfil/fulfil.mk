# Variables like $(RFSDIR) and $(CURDIR) are provided by the Flexbuild environment
APP_NAME = fulfil

app-$(APP_NAME):
    # 1. Create target directories in the staging RFS
    install -d $(RFSDIR)/opt/fulfil
    install -d $(RFSDIR)/usr/local/sbin
    install -d $(RFSDIR)/etc/systemd/system/multi-user.target.wants

    # 2. Copy assets
    cp -a $(CURDIR)/files/* $(RFSDIR)/opt/fulfil/
    
    # 3. Install the firstboot script with executable permissions
    install -m 0755 $(CURDIR)/files/firstboot.sh \
        $(RFSDIR)/usr/local/sbin/firstboot.sh

    # 4. Install and enable the systemd service
    install -m 0644 $(CURDIR)/files/fulfil-firstboot.service \
        $(RFSDIR)/etc/systemd/system/fulfil-firstboot.service
    
    ln -sf /etc/systemd/system/fulfil-firstboot.service \
        $(RFSDIR)/etc/systemd/system/multi-user.target.wants/fulfil-firstboot.service

    # 4. Install and enable the systemd service
    install -m 0644 $(CURDIR)/files/fulfil-camera-install.service \
        $(RFSDIR)/etc/systemd/system/fulfil-camera-install.service
	ln -sf /etc/systemd/system/fulfil-camera-install.service \
        $(RFSDIR)/etc/systemd/system/multi-user.target.wants/fulfil-camera-install.service

app: app-$(APP_NAME)