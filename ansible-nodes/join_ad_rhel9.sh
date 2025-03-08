#!/bin/bash

# Script to join a RHEL 9 machine to an Active Directory domain with SSH enabled
# Usage: sudo ./join_ad_rhel9.sh

# Exit on any error
set -e

# Constants
LOG_FILE="/var/log/ad_join.log"
CONFIG_DIR="/etc/ad_join"
SSSD_CONF="/etc/sssd/sssd.conf"
RESOLV_CONF="/etc/resolv.conf"
NETWORK_CONF="/etc/sysconfig/network-scripts/ifcfg-ens192"  # Adjust interface name if needed
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Fixed values from user input
DOMAIN="msp.local"
DC_IP="192.168.0.10"
GATEWAY_IP="192.168.0.1"
ADMIN_USER="Administrator"
HOSTNAME_BASE="rhel9-ws-rn"
IP_BASE="192.168.0."

# Variables to be set dynamically
HOSTNAME_SUFFIX=""
IP_SUFFIX=""
NEW_HOSTNAME=""
NEW_IP=""

# Functions
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.bak.$TIMESTAMP" || error_exit "Failed to backup $file"
        log "Backed up $file"
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root"
    fi
}

install_packages() {
    log "Installing required packages..."
    dnf update -y || error_exit "Failed to update package list"
    dnf install -y realmd sssd sssd-tools samba-common-tools krb5-workstation adcli oddjob oddjob-mkhomedir openssh-server || error_exit "Failed to install packages"
    log "Packages installed successfully"
}

prompt_hostname_suffix() {
    while true; do
        read -p "Enter hostname suffix (01-99): " HOSTNAME_SUFFIX
        if [[ "$HOSTNAME_SUFFIX" =~ ^[0-9]{2}$ && "$HOSTNAME_SUFFIX" -ge 01 && "$HOSTNAME_SUFFIX" -le 99 ]]; then
            NEW_HOSTNAME="${HOSTNAME_BASE}${HOSTNAME_SUFFIX}"
            log "Selected hostname: $NEW_HOSTNAME"
            break
        else
            echo "Invalid input. Please enter a two-digit number between 01 and 99."
        fi
    done
}

prompt_ip_suffix() {
    while true; do
        read -p "Enter IP suffix (30-90): " IP_SUFFIX
        if [[ "$IP_SUFFIX" =~ ^[0-9]{2}$ && "$IP_SUFFIX" -ge 30 && "$IP_SUFFIX" -le 90 ]]; then
            NEW_IP="${IP_BASE}${IP_SUFFIX}"
            log "Selected IP address: $NEW_IP"
            break
        else
            echo "Invalid input. Please enter a two-digit number between 30 and 90."
        fi
    done
}

configure_network() {
    log "Configuring network settings..."
    backup_file "$NETWORK_CONF"
    cat > "$NETWORK_CONF" << EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=ens192
DEVICE=ens192
ONBOOT=yes
IPADDR=$NEW_IP
NETMASK=255.255.255.0
GATEWAY=$GATEWAY_IP
DNS1=$DC_IP
DOMAIN=$DOMAIN
EOF
    [ $? -eq 0 ] || error_exit "Failed to configure network"
    nmcli con reload || error_exit "Failed to reload network config"
    nmcli con up ens192 || error_exit "Failed to apply network settings"
    log "Network configured successfully"
}

configure_dns() {
    log "Configuring DNS to use AD DC at $DC_IP..."
    backup_file "$RESOLV_CONF"
    cat > "$RESOLV_CONF" << EOF
nameserver $DC_IP
domain $DOMAIN
search $DOMAIN
EOF
    [ $? -eq 0 ] || error_exit "Failed to configure DNS"
    nslookup "$DOMAIN" >/dev/null 2>&1 || error_exit "DNS resolution failed for $DOMAIN"
    log "DNS configured and verified"
}

set_hostname() {
    log "Setting hostname to $NEW_HOSTNAME..."
    hostnamectl set-hostname "$NEW_HOSTNAME" || error_exit "Failed to set hostname"
    echo "$NEW_HOSTNAME" > /etc/hostname
    sed -i "/127.0.1.1/d" /etc/hosts
    echo "127.0.1.1 $NEW_HOSTNAME.$DOMAIN $NEW_HOSTNAME" >> /etc/hosts
    [ $? -eq 0 ] || error_exit "Failed to update /etc/hosts"
    log "Hostname set successfully"
}

join_domain() {
    log "Joining domain $DOMAIN..."
    echo -n "Enter password for $ADMIN_USER@$DOMAIN: "
    read -s PASSWORD
    echo
    echo "$PASSWORD" | realm join "$DOMAIN" -U "$ADMIN_USER" --verbose || error_exit "Failed to join domain"
    log "Successfully joined domain $DOMAIN"
}

configure_sssd() {
    log "Configuring SSSD..."
    backup_file "$SSSD_CONF"
    chmod 600 "$SSSD_CONF"
    systemctl enable sssd oddjobd --now || error_exit "Failed to enable SSSD and oddjobd"
    systemctl restart sssd oddjobd || error_exit "Failed to restart SSSD and oddjobd"
    log "SSSD and oddjobd configured and restarted"
}

enable_home_dirs() {
    log "Enabling automatic home directory creation..."
    authselect enable-feature with-mkhomedir || error_exit "Failed to enable mkhomedir"
    log "Home directory creation enabled"
}

configure_ssh() {
    log "Configuring SSH..."
    systemctl enable sshd --now || error_exit "Failed to enable and start sshd"
    firewall-cmd --permanent --add-service=ssh || error_exit "Failed to add SSH to firewall"
    firewall-cmd --reload || error_exit "Failed to reload firewall rules"
    log "SSH configured and enabled"
}

verify_join() {
    log "Verifying domain join..."
    realm list | grep "$DOMAIN" >/dev/null || error_exit "Domain join not detected"
    log "Domain join verified"
}

verify_ssh() {
    log "Verifying SSH service..."
    systemctl is-active sshd >/dev/null || error_exit "SSH service is not active"
    firewall-cmd --list-services | grep ssh >/dev/null || error_exit "SSH not allowed in firewall"
    log "SSH service verified"
}

# Main execution
check_root
log "Starting AD join process for $DOMAIN..."

prompt_hostname_suffix
prompt_ip_suffix
install_packages
configure_network
configure_dns
set_hostname
join_domain
configure_sssd
enable_home_dirs
configure_ssh
verify_join
verify_ssh

log "AD join and SSH setup completed successfully!"
echo "Machine joined as $NEW_HOSTNAME with IP $NEW_IP"
echo "SSH is enabled and accessible on port 22"
exit 0
