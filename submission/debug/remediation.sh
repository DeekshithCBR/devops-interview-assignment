#!/usr/bin/env bash
#
# remediation.sh — Incident remediation script
#
# Purpose: undo the incorrect MTU change on the management interface and
# ensure VPN stability.  Designed to be run on an affected edge device.
#
# This script is idempotent and checks current state before applying
# changes.  It also verifies afterward that connectivity is restored.

set -euo pipefail

CURRENT_MTU=$(ip link show eno1 | awk '/mtu/ {print $5}')
if [ "$CURRENT_MTU" -eq 1500 ]; then
    echo "eno1 already at MTU 1500, nothing to do."
    exit 0
fi

echo "Current MTU on eno1 is $CURRENT_MTU; setting to 1500"
ip link set dev eno1 mtu 1500

# update permanent config if netplan exists
if [ -f /etc/netplan/01-netcfg.yaml ]; then
    echo "Patching netplan to remove jumbo frames from eno1"
    sed -i '/eno1:/,/mtu:/s/mtu:.*$/mtu: 1500/' /etc/netplan/01-netcfg.yaml || true
    netplan apply || true
fi

# verify VPN tunnel is up
echo "Checking VPN status"
if ipsec status | grep -q UP; then
    echo "VPN tunnel is up"
else
    echo "VPN tunnel not up; forcing restart"
    systemctl restart strongswan
    sleep 5
fi

# simple connectivity test
echo "Testing connectivity to gateway"
ping -c 3 10.50.1.1

echo "Remediation complete; network should be stable."