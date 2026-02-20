# Root Cause Analysis

Review all files in `data/debug_scenario/` to investigate the incident.

## Summary

On 2025‑11‑12 at 08:15 UTC a network change intended for the camera
VLAN accidentally raised the MTU on the management/WAN interface (eno1)
from 1500 to 9000.  The site's gateway does not support jumbo frames,
causing packets to be dropped and triggering ICMP fragmentation messages.
Once the VPN tunnel oscillated (08:21‑08:50) the video uploader saw severe
timeouts and throughput dropped to 1.8 Mbps, filling the local disk and
causing an EDGE_UPLOAD_FAILURE alert.  Restoring MTU to 1500 immediately
resolved the issue.

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 08:00       | Systems normal, upload 42‑44 Mbps. |
| 08:15       | Netplan applied; eno1 MTU changed to 9000 (ticket NET‑4521). |
| 08:18       | ICMP "fragmentation needed" from 10.50.1.1; uploads begin timing out. |
| 08:20       | Upload error rate spikes; VPN tunnel drops briefly. |
| 08:21       | Tunnel re‑established; retries fail at low throughput 1.8 Mbps. |
| 08:25       | Second tunnel flap. |
| 08:30       | Disk 85%, backlog 22 chunks; NOC alert generated. |
| 08:35–08:50  | Multiple tunnel flaps occur. |
| 09:00       | MTU reverted to 1500; uploads recover, tunnel stabilizes.

## Root Cause

The root cause was a mis‑applied network configuration: jumbo MTU set on
the wrong interface (eno1) which carried the IPsec VPN.  The site gateway's
MTU was 1500; large packets flowed into the router, were dropped, and
triggered fragmentation ICMP, which in turn caused the strongSwan tunnel to
flap.  The application logs explicitly note the MTU issue at 08:22:

```
2025-11-12T08:22:16Z WARN  [uploader] VideoUploader - Possible MTU/fragmentation issue: large packets timing out, small health checks succeed
```

## Contributing Factors

* The change ticket NET‑4521 lacked verification steps to ensure the
  correct interface (`eno2`) was targeted.
* No monitoring existed for MTU mismatches or ICMP "fragmentation needed"
  messages on the edge device.
* VPN tunnel flapping amplified the impact by interrupting retries.
* Disk and queue back‑pressure were not surfaced until after the problem
  had persisted for 15+ minutes.

## Evidence

* `edge_syslog.txt` shows the MTU change at 08:15 and subsequent
  ICMP errors starting 08:18.
* `app_logs.txt` captures repeated socket timeouts and an explicit
  MTU warning at 08:22.
* `cloudwatch_metrics.json` shows upload error spikes beginning 08:15
  and correlates with VPN outages.
* `timeline.md` reconstructs the ticket and network change event.

Each of these files corroborates that the network configuration change
triggered a fragmentation issue, not an application bug.
