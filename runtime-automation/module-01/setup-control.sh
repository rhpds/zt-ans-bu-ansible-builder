#!/bin/bash
set -euo pipefail

# Enable standard RHEL repos if available
sudo dnf config-manager --set-enabled rhel-9-baseos-rpms rhel-9-appstream-rpms || true

# Install EPEL if Satellite not available
if ! sudo dnf repolist | grep -q epel; then
  sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm || true
fi

# Allow passwordless sudo
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers

# Install Certbot
sudo dnf install -y certbot jq

# --- START all Pulp services ---
echo "Starting Pulp services..."
sudo systemctl start pulpcore-* || true

# --- Define or auto-detect hostname ---
# Change this if you have a specific FQDN for your private hub
PRIVATE_HUB_FQDN=${PRIVATE_HUB_FQDN:-$(hostname -f)}

echo "Using hostname: $PRIVATE_HUB_FQDN"

# --- Update settings.py to use the hostname instead of IP ---
SETTINGS_FILE="/etc/pulp/settings.py"

if [ -f "$SETTINGS_FILE" ]; then
  echo "Updating $SETTINGS_FILE to use $PRIVATE_HUB_FQDN..."
  # Replace any IPv4 address with the hostname
  sudo sed -i -r "s/([0-9]{1,3}\.){3}[0-9]{1,3}/${PRIVATE_HUB_FQDN}/g" "$SETTINGS_FILE"
else
  echo "Warning: $SETTINGS_FILE not found!"
fi

# --- Restart services to apply changes ---
echo "Restarting Pulp and Nginx..."
sudo systemctl restart pulpcore-api || true
sudo systemctl restart nginx || true

echo "✅ Pulp configuration updated successfully."


