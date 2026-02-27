#!/bin/bash
set -euo pipefail

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


