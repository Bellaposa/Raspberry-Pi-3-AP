# Raspberry PI 3 AP
-

- We need to install dnsmasq and hostapd

```bash
sudo apt-get install dnsmasq hostapd
```

- Now edit the dhcpcd.conf file with

```bash
sudo nano /etc/dhcpcd.conf
```

and add the following line to the bottom of the file:

```bash 

denyinterfaces wlan0

```

- Edit /etc/network/interfaces adding your own configuration

```bash 
sudo nano /etc/network/interfaces
```


```bash
	allow-hotplug wlan0
	iface wlan0 inet static 
   address 10.0.20.201
    netmask 255.255.0.0
    network 10.0.20.200
    broadcast 10.0.20.255
    #wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
```

- restart service 


```bash
sudo service dhcpcd restart
sudo ifdown wlan0 
sudo ifup wlan0
```

- edit the hostapd configuration file

```bash
sudo nano /etc/hostapd/hostapd.conf
```

- adding the following configuration

```bash
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
rsn_pairwise=CCMP
```

- check the configuration, a wifi network will be available

```bash
sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf
```

- press CTRL+C to exit, now edit the hostapd file with
 
```bash 
sudo nano /etc/default/hostapd`

DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

- Modify dnsmasq dns server

```bash
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo nano /etc/dnsmasq.conf
```

- add the following configuration ( you have to modify according to your /etc/network/interfaces configuration

```bash
interface=wlan0      # Use interface wlan0  
listen-address=10.0.20.201 # Explicitly specify the address to listen on  
bind-interfaces      # Bind to the interface to make sure we aren't sending things elsewhere  
server=8.8.8.8       # Forward DNS requests to Google DNS  
domain-needed        # Don't forward short names  
bogus-priv           # Never forward addresses in the non-routed address spaces.  
dhcp-range=10.0.20.210,10.0.20.220,12h # Assign IP addresses between 10.0.20.210 and 10.0.20.220 with a 12 hour lease time  
```
- you can edit or remove dhcp-range ip lease time

- edit 

```bash
sudo nano /etc/sysctl.conf
```

- remove the # from the beginning of the line containing net.ipv4.ip_forward=1

- add the following command 

```bash
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```

- modify /etc/rc.local


```bash
sudo nano /etc/rc.local
``` 
- and just above the line exit 0, add the following line:



```bash
iptables-restore < /etc/iptables.ipv4.nat
```
```bash
sudo service hostapd start 
sudo service dnsmasq start  
```
- reboot your device 

#enjoy :P
