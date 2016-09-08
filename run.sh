#!/usr/bin/sh
#!/usr/bin/bash -e

# Set color of logo
tput setaf 3

cat << EOF
Raspberry Pi 3 

EOF

# Reset color
tput sgr 0


read -p "Do you still want to continue? (y/N)" -n 1 -r -s INSTALL
if [ "$INSTALL" != 'y' ]; then
  echo
  exit 1
fi

echo
echo "UPDATE"
sudo apt-get update

sudo apt-get install -y hostapd dnsmasq

sudo echo "auto lo

iface lo inet loopback
iface eth0 inet manual
allow-hotplug wlan0

iface wlan0 inet static
address 10.0.20.201
netmask 255.255.0.0
network 10.0.20.200
broadcast 10.0.20.255
#wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

allow-hotplug wlan1
iface wlan1 inet manual
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" > /etc/network/interfaces

sudo service dhcpcd restart
sudo systemctl daemon-reload
sudo ifdown wlan0
sudo ifup wlan0

sudo echo "
interface=wlan0
driver=nl80211
ssid=Pi3-AP
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=raspberry
rsn_pairwise=CCMP" > /etc/hostapd/hostapd.conf

sudo echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
touch /etc/dnsmasq.conf
sudo echo "
interface=wlan0
listen-address=10.0.20.201
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=10.0.20.210,10.0.20.220,12h" > /etc/dnsmasq.conf



sudo echo  "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

sudo cp /etc/rc.local /etc/rc.local.back
sudo sed -i '/fi/a iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local
sudo service hostapd start
sudo service dnsmasq start
echo "done"
sudo reboot
