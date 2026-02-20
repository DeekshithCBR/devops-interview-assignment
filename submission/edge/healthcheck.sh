#!/usr/bin/env bash
#
# healthcheck.sh — Edge device health check script
#
# TASK: Implement a health check script that verifies edge device status.
#
# Requirements:
#   - Check Docker daemon is running
#   - Check video-ingest container is running and healthy
#   - Check GPU is accessible (nvidia-smi)
#   - Check disk usage is below threshold
#   - Check NTP synchronization
#   - Check VPN tunnel is up
#   - Check camera connectivity (ping camera subnet)
#   - Output JSON status report
#   - Exit code 0 if healthy, 1 if degraded, 2 if critical

set -euo pipefail

# threshold settings
DISK_THRESHOLD=90  # percent
CAMERA_SUBNET="10.50.2.0/24"

status=0
report={}

check_docker() {
    if systemctl is-active --quiet docker; then
        report+="\"docker\": \"running\",";
    else
        report+="\"docker\": \"stopped\",";
        status=1
    fi
}

check_container() {
    if docker ps --filter name=video-ingest --filter health=healthy --quiet | grep -q .; then
        report+="\"container\": \"healthy\",";
    else
        report+="\"container\": \"unhealthy\",";
        status=2
    fi
}

check_gpu() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        report+="\"gpu\": \"present\",";
    else
        report+="\"gpu\": \"absent\",";
    fi
}

check_disk() {
    usage=$(df /var/lib/video-buffer --output=pcent | tail -1 | tr -dc '0-9')
    report+="\"disk_usage\": $usage,";
    if [ "$usage" -gt $DISK_THRESHOLD ]; then
        status=2
    fi
}

check_ntp() {
    if timedatectl status | grep -q "synchronized: yes"; then
        report+="\"ntp\": \"sync\",";
    else
        report+="\"ntp\": \"unsynced\",";
        status=1
    fi
}

check_vpn() {
    if ipsec status | grep -q "ESTABLISHED"; then
        report+="\"vpn\": \"up\",";
    else
        report+="\"vpn\": \"down\",";
        status=2
    fi
}

check_camera() {
    if ping -c 1 -W 1 $(echo $CAMERA_SUBNET | cut -d. -f1-3).1 >/dev/null 2>&1; then
        report+="\"camera\": \"reachable\"";
    else
        report+="\"camera\": \"unreachable\"";
        status=1
    fi
}

# run all checks
check_docker
check_container
check_gpu
check_disk
check_ntp
check_vpn
check_camera

# output JSON
printf '{%s}' "$report"
exit $status
