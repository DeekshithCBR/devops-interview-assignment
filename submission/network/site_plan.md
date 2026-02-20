# Site Network Plan

Review `data/site_spec.json` for the customer site specification.

## VLAN Design

The site has three primary VLANs:

| VLAN ID | Name           | Subnet          | Purpose                                |
|---------|----------------|-----------------|----------------------------------------|
| 10      | Management     | 10.50.1.0/24    | Admin workstations, edge management    |
| 20      | Camera         | 10.50.2.0/24    | IP cameras and video ingest devices    |
| 30      | Corporate      | 10.50.3.0/24    | General corporate network & servers    |

Edge device has one interface on the management VLAN (eno1) and a
second on the camera VLAN (eno2).

## IP Addressing Scheme

- Edge device eno1 (management/WAN): 10.50.1.50/24
- Edge device eno2 (camera): DHCP from 10.50.2.0/24 range
- Camera DHCP pool: 10.50.2.100–10.50.2.199
- Management workstations static: 10.50.1.100–10.50.1.120

## Camera Network Isolation

Camera VLAN is air‑gapped from management and corporate networks.  No
routes are allowed from 10.50.2.0/24 to 10.50.1.0/24 or 10.50.3.0/24 at
the firewall/gateway.  Only the edge device can originate traffic into
management (for control) and the edge device is the sole gateway out to
the WAN.

## Edge Device Network Configuration

- eno1 attached to management VLAN with static IP 10.50.1.50.  This
  interface also carries the IPsec VPN tunnel to AWS.
- eno2 attached to camera VLAN.  Cameras obtain DHCP addresses from the
  local camera controller.
- Routing: default route via gateway 10.50.1.1 on eno1.  No gateway is
  defined on eno2; traffic in camera VLAN is switched locally.

## Traffic Flow

1. Cameras send video streams over RTSP to the edge device on eno2.
2. Edge device processes and batches video chunks, then uploads to S3
   over the IPsec VPN on eno1.
3. Management traffic (SSH, NTP, updates) uses eno1 and is allowed via
   the bastion/security group.
4. Camera VLAN cannot initiate connections to management or corporate
   VLANs; only the edge device proxies necessary control traffic.
