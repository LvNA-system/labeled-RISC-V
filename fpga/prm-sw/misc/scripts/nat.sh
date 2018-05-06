ifconfig eth1 up
ifconfig eth1 192.168.1.1
sysctl net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 6379 -j DNAT --to-destination 192.168.1.2:6379
