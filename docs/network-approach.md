# Network & Edge Approach

Designed to isolate camera traffic from management while allowing the
edge device to act as the only bridge to the cloud.

* **VLANs** defined for management, camera, and corporate networks.
* **IP plan** assigns static addresses to edge device and management
  hosts, with DHCP pool for cameras.
* **Firewall rules** (iptables) implement default DROP policies, allow
  only necessary ports (RTSP on camera VLAN, SSH on management, HTTPS
  outbound), and prevent camera VLAN from reaching management/corporate.
  Rules include logging and stateful allow for established connections.
* **Site plan** documents the topology and traffic flow.
* **Edge provisioning** (`setup.sh`) installs Docker, NVIDIA drivers,
  configures NTP, logrotate, systemd service, and applies basic hardening
  (disable root SSH, UFW rules).

This modular documentation enables repeatable deployment at new sites
and gives operations a clear runbook for network configuration.