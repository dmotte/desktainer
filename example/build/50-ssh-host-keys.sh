#!/bin/bash

# Get host keys from the volume
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
cp /etc/ssh/host-keys/ssh_host_*_key /etc/ssh/ 2>/dev/null || true
cp /etc/ssh/host-keys/ssh_host_*_key.pub /etc/ssh/ 2>/dev/null || true

# Generate the missing host keys
ssh-keygen -A

# Set correct permissions on host keys
chown root:root /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# Copy the (previously missing) generated host keys to the volume
cp -n /etc/ssh/ssh_host_*_key /etc/ssh/host-keys/ 2>/dev/null || true
cp -n /etc/ssh/ssh_host_*_key.pub /etc/ssh/host-keys/ 2>/dev/null || true
