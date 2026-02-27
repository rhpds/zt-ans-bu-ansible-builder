#!/bin/bash
set -e

retry() {
    # $1 is the command string
    # $2 is the description for the echo (optional)
    local cmd="$1"
    for i in {1..3}; do
        echo "Attempt $i: ${2:-$cmd}"
        # Use eval to properly parse the command string and its arguments
        if eval "$cmd"; then
            return 0
        fi
        [ $i -lt 3 ] && sleep 5
    done
    echo "Failed after 3 attempts: ${2:-$cmd}"
    exit 1
}

# ... rest of your variables (SATELLITE_URL, etc.) ...

retry "subscription-manager clean"
retry "curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt"
retry "update-ca-trust"

# Check if Katello is installed
KATELLO_INSTALLED=$(rpm -qa | grep -c katello || true) 

if [ "$KATELLO_INSTALLED" -eq 0 ]; then
  # This will now work correctly with eval
  retry "rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm"
fi
subscription-manager status
if [ $? -ne 0 ]; then
    retry "subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}"
fi

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
