#!/bin/bash

# Basics first
sudo yum update -y
sudo yum upgrade -y

# Allow EC2 to function as a NAT instance and persist across reboots
sudo yum install -y iptables-services
sudo systemctl enable iptables
sudo systemctl start iptables

# Enable IP Forwarding
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/custom-ip-forwarding.conf
sudo sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf

# Set up IP forwarding and masquerading
sudo /sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
sudo /sbin/iptables -F FORWARD
sudo service iptables save

# Enable SELinux
#sudo yum -y install selinux-policy-minimum selinux-policy-mls policycoreutils setools
checkmodule -M -m -o /tmp/ssh_module.mod /tmp/ssh_module.te
semodule_package -o /tmp/ssh_module.pp -m /tmp/ssh_module.mod
sudo semodule -i /tmp/ssh_module.pp
rm /tmp/ssh_*
sudo sed 's/^SELINUX=.*$/SELINUX=enforcing/' /etc/selinux/config | sudo tee /etc/selinux/config
