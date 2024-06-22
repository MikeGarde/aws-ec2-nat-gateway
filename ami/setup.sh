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
