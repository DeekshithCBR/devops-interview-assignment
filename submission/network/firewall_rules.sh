#!/usr/bin/env bash
#
# firewall_rules.sh — Edge device firewall configuration
#
# TASK: Implement iptables rules for the edge device.
# Reference data/site_spec.json for network details.
#
# Requirements:
#   - Default DROP policy on INPUT and FORWARD chains
#   - Allow RTSP (554/tcp, 554/udp) from camera VLAN only
#   - Allow HTTPS (443/tcp) outbound for S3 uploads and API calls
#   - Allow SSH (22/tcp) from management VLAN only
#   - Camera VLAN must not be able to reach management or corporate VLANs
#   - Allow established/related connections
#   - Allow loopback traffic
#   - Allow ICMP for diagnostics
#
# Hints:
#   - Camera VLAN: (define based on your site_plan.md)
#   - Management VLAN: 10.50.1.0/24
#   - Edge device interfaces: eno1 (mgmt/WAN), eno2 (camera VLAN)

set -euo pipefail

# --- Flush existing rules ---
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# --- Default policies ---
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# --- Loopback ---
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# --- Established/Related ---
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# network subnets from plan
CAMERA_VLAN="10.50.2.0/24"
MGMT_VLAN="10.50.1.0/24"

# --- SSH from management VLAN only ---
iptables -A INPUT -i eno1 -p tcp --dport 22 -s ${MGMT_VLAN} -m conntrack --ctstate NEW -j ACCEPT

# --- RTSP from camera VLAN only ---
iptables -A INPUT -i eno2 -p tcp --dport 554 -s ${CAMERA_VLAN} -j ACCEPT
iptables -A INPUT -i eno2 -p udp --dport 554 -s ${CAMERA_VLAN} -j ACCEPT

# --- HTTPS outbound ---
iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# --- Camera VLAN isolation (block camera-to-management/corporate) ---
iptables -A FORWARD -s ${CAMERA_VLAN} -d ${MGMT_VLAN} -j DROP
iptables -A FORWARD -s ${CAMERA_VLAN} -d 10.50.3.0/24 -j DROP

# --- ICMP ---
iptables -A INPUT -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# --- Logging for dropped packets (optional but recommended) ---
iptables -N LOGDROP
iptables -A LOGDROP -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
iptables -A LOGDROP -j DROP

# send remaining INPUT/ FORWARD to logdrop
iptables -A INPUT -j LOGDROP
iptables -A FORWARD -j LOGDROP

echo "Firewall rules applied successfully"

echo "Firewall rules applied successfully"
