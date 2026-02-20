# Debug & Ops Approach

The debugging module uses real incident data to demonstrate operational
awareness:

* **Root Cause Analysis** (RCA) reconstructs the timeline and identifies
  that an MTU misconfiguration on the management interface caused VPN
  instability and upload failures.  Logs, metrics, and syslogs are all
  referenced.
* **Remediation script** automates the fix by resetting the MTU, patching
  netplan, and verifying VPN connectivity.  It's idempotent and safe.

In a full deployment, additional runbooks would cover:

* Monitoring for MTU mismatch and ICMP fragmentation events.
* Automated rollback of configuration changes via a configuration
  management system (e.g. Ansible, Salt).
* Postmortem documentation and customer communication templates.

The emphasis is on clear communication, evidence-backed conclusions, and
providing operational tooling rather than just a narrative.