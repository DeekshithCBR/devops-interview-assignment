# Golden Image Strategy

## Overview

We maintain a single, hardened base image that contains all common
packages and runtime components required by the video‑analytics edge
software.  Site‑specific configuration (networking, NTP server, site ID)
is applied at first boot via a provisioning script (see `setup.sh`).
Images are rebuilt monthly or whenever critical security updates are
needed.

## Base Image

The base image is built from Ubuntu LTS and includes:

* Docker CE with NVIDIA container runtime
* Video ingest & analytics containers pre‑pulled
* Systemd service definitions
* Monitoring/metrics agent
* Firewall/ufw configuration templates
* Minimal set of utilities (curl, jq, awscli, etc.)

No site credentials or sensitive data are baked in; these are supplied
via a secure configuration service during provisioning.

## Image Creation Process

1. Start from clean Ubuntu LTS cloud image.
2. Apply OS hardening (CIS benchmarks) via automated script.
3. Install Docker, NVIDIA drivers, and common tools.
4. Pre‑pull required containers and test them in a local VM.
5. Run `packer` to create the image, validate by booting in a test
   environment.
6. Push image to the central artifact repository (e.g. AWS AMI).

## Configuration Management

Site-specific variables are stored in `data/site_spec.json` and
retrieved by the device during onboarding.  The provisioning script
decodes the JSON, configures network interfaces, NTP server, and
registers the device with the central dashboard.

For ongoing configuration we use `etcd` or AWS S3 parameter store that
the edge agent polls periodically; any change triggers a local reboot of
affected services.

## Patching and Updates

* **OS patches** – we build a new golden image weekly for critical
  updates; devices periodically check the update service and perform an
  in‑place upgrade if the image version differs.
* **Container updates** – containers are versioned; the agent pulls new
  tags from ECR and restarts the service with zero‑downtime rolling
  restarts.

All updates are first deployed to a canary group of 5 devices.  If no
issues are reported after 24h, we proceed to full fleet rollout.

## Rollback

Each device retains the previous image and container tags.  A
`rollback.sh` helper script switches back to the previous image and
restarts services; it can be triggered automatically if health checks
fail after an update.

In extreme cases, devices can be reflashed using the last known good
AMI via network boot or manual intervention.

