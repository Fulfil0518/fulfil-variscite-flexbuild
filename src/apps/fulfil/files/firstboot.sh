#!/bin/bash
# This script is designed to run when a newly provisioned node first comes
# online. This script will setup networking, define the hostname, etc. which
# are unique to a given node.
set -x
# Kubernetes node configuration
CONF_NODE_LABELS="fulfil.ai/model=lfp fulfil.ai/location=tan"

sleep 10 # wait for NetworkManager to comeup (for some reason takes sec)
# Set up networking if it doesn't exist
cp /lib/systemd/network/80-wifi-station.network.example /etc/systemd/network/80-wifi-station.network

cat << EOL >> /etc/systemd/network/80-wifi-station.network
[DHCPv4]
RouteMetric=9
[IPv6AcceptRA]
RouteMetric=9 
EOL

cat << EOL >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
ctrl_interface=/var/run/wpa_supplicant
eapol_version=1
ap_scan=1
fast_reauth=1
EOL

WIFI_SECRETS_FILE="/opt/fulfil/wifi-secrets.env"
if [ -f "$WIFI_SECRETS_FILE" ]; then
	# shellcheck source=/opt/fulfil/wifi-secrets.env
	. "$WIFI_SECRETS_FILE"
else
	echo "Missing $WIFI_SECRETS_FILE; skipping WiFi provisioning"
fi

add_wifi_network() {
	local ssid="$1"
	local psk="$2"
	if [ -n "$ssid" ] && [ -n "$psk" ]; then
		wpa_passphrase "$ssid" "$psk" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
	fi
}

add_wifi_network "${WIFI_SSID_1:-}" "${WIFI_PSK_1:-}"
add_wifi_network "${WIFI_SSID_2:-}" "${WIFI_PSK_2:-}"
add_wifi_network "${WIFI_SSID_3:-}" "${WIFI_PSK_3:-}"

networkctl up wlan0

systemctl restart systemd-networkd.service
systemctl restart wpa_supplicant@wlan0.service

# Wait for network to come up
sleep 30

# ping something known and if no response then fail script
if ! ping -c 1 google.com
then
	echo "No network connection, exiting"
	exit 1
fi
# regenerate machine-id since the preflashed image id would be the same for all bots
rm /var/lib/dbus/machine-id && rm /etc/machine-id && systemd-machine-id-setup


if ! grep -q "LANG=en_US.UTF-8" /etc/locale.conf; then
	echo "LC_ALL=en_US.UTF-8" >> /etc/environment
	grep -qxF "en_US.UTF-8 UTF-8" /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
	locale-gen en_US.UTF-8
fi

apt update && apt dist-upgrade -y

chmod 1777 /tmp

rm /etc/bluetooth/variscite-bt

apt-get install -y apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
	wpasupplicant \
	sudo \
    nano \
	htop \
	net-tools \
	ntp \
	ccze \
	usbutils \
	rsync \
	rsyslog

touch /etc/rsyslog.d/excluderover.conf
echo "if \$programname contains \"rover-bag3-core\" then stop" > /etc/rsyslog.d/excluderover.conf

sysctl -p

systemctl stop ntp
ntpd -gq
systemctl start ntp

mkdir -p /etc/docker 
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

if [ ! -f /usr/bin/docker ]; then
	curl -fsSL https://get.docker.com | sh
fi


# if the environment variable BOT_NUMBER exists set hostname to that
if [[ -n "$BOT_NUMBER" ]]
then
	hostnamectl set-hostname "rover$BOT_NUMBER"
fi

# not quite idempotent, but it does fail out if the user already exists
adduser --disabled-password --gecos "" fulfil && \
	echo "fulfil:FreshEngr" > /tmp/passwords && \
	chpasswd < /tmp/passwords && \
	rm /tmp/passwords && \
	usermod -aG sudo fulfil && \
	usermod --shell /bin/bash fulfil && \
	echo 'export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /home/fulfil/.bashrc && \
	mkdir -p /home/usrFtp/code && \
	chmod u+rw /home/usrFtp/code/ && \
	chown -R fulfil: /home/usrFtp/code/
	
yes FreshEngr | passwd root

# set up dummy network so k3s can boot without networking
# see https://docs.k3s.io/installation/airgap
ip link add dummy0 type dummy
ip link set dummy0 up
ip addr add 203.0.113.254/31 dev dummy0
ip route add default via 203.0.113.255 dev dummy0 metric 1000

# Set k3s cert expiration to 10 years
echo "CATTLE_NEW_SIGNED_CERT_EXPIRATION_DAYS=3650" > /etc/systemd/system/k3s.service.env

# In today's things that make me very sad
# export INSTALL_K3S_VERSION=${INSTALL_K3S_VERSION:-"v1.22.2+k3s2"} for 3.1s
curl -sfL "https://get.k3s.io/" > /root/k3s.sh && \
	chmod +x /root/k3s.sh && \
	/root/k3s.sh --docker \
        --disable-cloud-controller \
        --disable traefik \
		--tls-san 10.43.0.1 \
        --kubelet-arg cgroup-driver=systemd 

# Add node labels to k3s
for label in ${CONF_NODE_LABELS}; do
	label=$(echo "${label}" | sed 's/\//\\\//g')
	echo "Setting node label '${label}'..."
	sed -i "s/--docker' \\\/--docker' \\\\\n\t'--node-label' ${label} \\\/g" /etc/systemd/system/k3s.service
done

FULFILDIR=/opt/fulfil/

# copy over necessary lfr files
mkdir -p ${MOUNTDIR}/home/usrFtp/code
cp ${FULFILDIR}/rpmsg_adc.elf /lib/firmware/
cp ${FULFILDIR}/main.py /root/
cp ${FULFILDIR}/upload_cam_code.sh /root/

# Copy the robot-controller kubernetes manifests for firmware management.
# This will automatically be applied when k3s starts.
# https://rancher.com/docs/k3s/latest/en/advanced/
mkdir -p /var/lib/rancher/k3s/server/manifests
cp ${FULFILDIR}/namespace.yaml /var/lib/rancher/k3s/server/manifests/0-namespace.yaml
cp ${FULFILDIR}/serviceaccount.yaml /var/lib/rancher/k3s/server/manifests/1-serviceaccount.yaml
cp ${FULFILDIR}/deployment.yaml /var/lib/rancher/k3s/server/manifests/3-deployment.yaml

# note these three lines require secrets which you'll have to create and put in the scripts/manifests directory
cp ${FULFILDIR}/rover-gcr-secret.yaml /var/lib/rancher/k3s/server/manifests/2-gcr-key.yaml
cp ${FULFILDIR}/rover-gcr-api-key.json /root/
cp ${FULFILDIR}/lfr-promtail-secret.yaml /var/lib/rancher/k3s/server/manifests/4-lfr-promtail-secret.yaml

# docker login to gcr.io so that k3s can pull images
cat /root/rover-gcr-api-key.json | docker login -u _json_key --password-stdin https://gcr.io

# set up a bunch of stuff for lfrs and ease of use for devs
echo "export currentlog=/home/usrFtp/code/log_\$(date "'+%Y-%m-%d'").txt" >> ~/.bashrc
echo 'imx_rpmsg_tty' >> /etc/modules
rm /etc/bluetooth/variscite-bt
fw_setenv fdt_file imx8mn-var-som-fulfil-lfp.dtb 

# Remove firstboot bootstrap script
echo "Removing firstboot script..."
rm /opt/fulfil/firstboot.sh
rm /etc/systemd/system/default.target.wants/firstboot.service
systemctl disable k3s.service # disable k3s to be re-enabled later by us once at TAN

# Shutdown
echo "Shutting down..."
sleep 10
shutdown now
