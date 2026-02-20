# Edge Device Approach

Edge devices are provisioned from a golden image and configured via a
bash script (`setup.sh`).  Key points:

* **Idempotent provisioning** with logging and error handling ensures
  devices can be reprovisioned if interrupted.
* **Docker & GPU support**: installs Docker CE and NVIDIA container
  toolkit; configures daemon with sane defaults (log rotation, storage
  driver).
* **NTP** pointed at site-specific server; encourages time sync for logs
  and VPN.
* **Security**: root SSH disabled, UFW applied consistent with firewall
  script, and only minimal packages installed.
* **Service management**: video-ingest container runs inside systemd,
  restarts on failure, mounts local buffer, and has GPU access.
* **Update strategy**: edges check for new images and can rollback
  quickly (see golden_image.md).  Logs are rotated and shipped to
  central monitoring.

This approach balances ease of deployment with security and reliability
requirements.