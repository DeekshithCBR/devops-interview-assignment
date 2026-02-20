#!/usr/bin/env bash
#
# setup.sh — Edge device provisioning script
#
# TASK: Implement a provisioning script for a new edge device.
# Reference data/site_spec.json for hardware and requirements.
#
# Requirements:
#   - Error handling (set -euo pipefail, trap for cleanup)
#   - Docker installation and configuration
#   - NTP configuration for time synchronization
#   - Log rotation setup
#   - Systemd service for the video ingest container
#   - GPU driver setup (NVIDIA)
#   - Basic security hardening

set -euo pipefail

SITE_ID="${SITE_ID:-SITE-UNKNOWN}"
LOG_FILE="/var/log/edge-setup-${SITE_ID}.log"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $1" | tee -a "$LOG_FILE"
}

log "Starting edge device setup for site: $SITE_ID"

# ============================================
# SECTION 1: System Updates and Base Packages
# ============================================
log "Updating system packages and installing prerequisites"
apt-get update -y && apt-get upgrade -y
apt-get install -y curl gnupg2 software-properties-common apt-transport-https

# ============================================
# SECTION 2: Docker Installation
# ============================================
log "Installing Docker CE"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# configure daemon
cat <<'EOF' > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"},
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker
systemctl restart docker

# add service user
usermod -aG docker ubuntu || true

# ============================================
# SECTION 3: NVIDIA GPU Drivers and Container Toolkit
# ============================================
if lspci | grep -i nvidia >/dev/null 2>&1; then
  log "Installing NVIDIA drivers and container toolkit"
  apt-get install -y nvidia-driver-520
  distribution="$(. /etc/os-release && echo $ID$VERSION_ID)"
  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list |
    tee /etc/apt/sources.list.d/nvidia-docker.list
  apt-get update -y
  apt-get install -y nvidia-container-toolkit
  systemctl restart docker
fi

# ============================================
# SECTION 4: NTP Configuration
# ============================================
NTP_SERVER="$(jq -r '.ntp_server // "pool.ntp.org"' data/site_spec.json)"
log "Configuring NTP to use $NTP_SERVER"
apt-get install -y ntp
sed -i "s/^pool /#pool /" /etc/ntp.conf
cat <<EOF >> /etc/ntp.conf
server $NTP_SERVER iburst
EOF
systemctl enable ntp
systemctl restart ntp

# ============================================
# SECTION 5: Log Rotation
# ============================================
cat <<'EOF' > /etc/logrotate.d/video-analytics
/var/log/video-*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}

/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    missingok
    copytruncate
}
EOF

# ============================================
# SECTION 6: Systemd Service
# ============================================
log "Creating systemd service for video-ingest container"
cat <<'EOF' > /etc/systemd/system/video-ingest.service
[Unit]
Description=Video ingest container
After=docker.service
Requires=docker.service

[Service]
Restart=on-failure
RestartSec=10s
ExecStart=/usr/bin/docker run --rm \
  --gpus all \
  --name video-ingest \
  -v /var/lib/video-buffer:/data/buffer \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/video-ingest:latest
ExecStop=/usr/bin/docker stop video-ingest

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable video-ingest

# ============================================
# SECTION 7: Security Hardening
# ============================================
log "Applying basic security hardening"
# disable root SSH login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# configure UFW
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow from $MGMT_VLAN to any port 22 proto tcp
ufw allow from $CAMERA_VLAN to any port 554 proto tcp
ufw allow from $CAMERA_VLAN to any port 554 proto udp
ufw enable || true

log "Edge device setup complete for site: $SITE_ID"
log "Edge device setup complete for site: $SITE_ID"
