#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: YourUserName # Replace with your GitHub username
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fosrl/pangolin

# Import common functions from the main install.sh script (passed via stdin)
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Default LXC values (can be overridden by user prompts)
DEFAULT_CTID="auto"
DEFAULT_HOSTNAME="pangolin"
DEFAULT_BASE_DOMAIN="example.com" # Placeholder, user must change
DEFAULT_DASHBOARD_DOMAIN="pangolin.example.com" # Placeholder, user must change
DEFAULT_LETSENCRYPT_EMAIL="your-email@example.com" # Placeholder, user must change
DEFAULT_ADMIN_EMAIL="admin@example.com" # Placeholder, user must change
DEFAULT_ADMIN_PASSWORD="changeme" # Placeholder, user must change

# Display application header
header_info "Pangolin"

# Initial Checks
network_check # Check network connectivity [2]

# Prompt for LXC Container ID
read -r -p "Enter the Container ID (e.g., 101): " CTID
CTID="${CTID:-$DEFAULT_CTID}"

# Prompt for LXC Hostname
read -r -p "Enter the Hostname for the container: " HOSTNAME
HOSTNAME="${HOSTNAME:-$DEFAULT_HOSTNAME}"

# Prompt for Pangolin specific inputs
msg_info "Pangolin requires specific domain and email configurations for setup:"
read -r -p "Enter your Base Domain (e.g., example.com): " BASE_DOMAIN
BASE_DOMAIN="${BASE_DOMAIN:-$DEFAULT_BASE_DOMAIN}"

read -r -p "Enter the Dashboard Domain (e.g., pangolin.example.com): " DASHBOARD_DOMAIN
DASHBOARD_DOMAIN="${DASHBOARD_DOMAIN:-$DEFAULT_DASHBOARD_DOMAIN}"

read -r -p "Enter your Let's Encrypt Email (for SSL certificates): " LETSENCRYPT_EMAIL
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-$DEFAULT_LETSENCRYPT_EMAIL}"

read -r -p "Enter the Pangolin Admin User Email: " ADMIN_EMAIL
ADMIN_EMAIL="${ADMIN_EMAIL:-$DEFAULT_ADMIN_EMAIL}"

read -s -p "Enter the Pangolin Admin User Password: " ADMIN_PASSWORD
echo # Newline after password input
if]; then
    msg_error "Admin password cannot be empty. Exiting."
    exit_script
fi

# Confirm inputs
echo -e "\n${BLU}--- Review Your Inputs ---${CL}"
echo -e "${CYN}Container ID:${CL} ${CTID}"
echo -e "${CYN}Hostname:${CL} ${HOSTNAME}"
echo -e "${CYN}Base Domain:${CL} ${BASE_DOMAIN}"
echo -e "${CYN}Dashboard Domain:${CL} ${DASHBOARD_DOMAIN}"
echo -e "${CYN}Let's Encrypt Email:${CL} ${LETSENCRYPT_EMAIL}"
echo -e "${CYN}Admin Email:${CL} ${ADMIN_EMAIL}"
echo -e "${CYN}Admin Password:${CL} (hidden)"
echo -e "${BLU}------------------------${CL}\n"

read -r -p "Proceed with installation? <y/N> " prompt
if [[ ${prompt,,}!= "y" && ${prompt,,}!= "yes" ]]; then
    msg_error "Installation aborted by user."
    exit_script
fi

# Create LXC Container
msg_info "Creating LXC Container for Pangolin"
# Use common function for setting up container, passing necessary variables
# The setting_up_container function is expected to be provided by FUNCTIONS_FILE_PATH
setting_up_container "$CTID" "$HOSTNAME" "$var_cpu" "$var_ram" "$var_disk" "$var_os" "$var_version" "$var_unprivileged"
msg_ok "LXC Container ${CTID} created."

# Copy ct/Pangolin.sh into the new container
msg_info "Copying ct/Pangolin.sh to container ${CTID}"
LXC_SCRIPT_PATH="/tmp/Pangolin.sh"
$STD pct push "$CTID" "ct/Pangolin.sh" "$LXC_SCRIPT_PATH"
$STD pct exec "$CTID" chmod +x "$LXC_SCRIPT_PATH"
msg_ok "ct/Pangolin.sh copied and made executable inside container."

# Execute ct/Pangolin.sh inside the container, passing inputs
msg_info "Executing Pangolin installation script inside container ${CTID}"
$STD pct exec "$CTID" bash "$LXC_SCRIPT_PATH" \
    "$BASE_DOMAIN" \
    "$DASHBOARD_DOMAIN" \
    "$LETSENCRYPT_EMAIL" \
    "$ADMIN_EMAIL" \
    "$ADMIN_PASSWORD"

if [[ $? -ne 0 ]]; then
    msg_error "Pangolin installation inside container failed. Check container logs."
    exit_script
fi
msg_ok "Pangolin installation inside container ${CTID} completed."

# Post-LXC Creation Steps (on Proxmox host)
msg_info "IMPORTANT: Manual Post-Installation Steps Required!"
echo -e "${TAB}${BGN}1. DNS Configuration:${CL}"
echo -e "${TAB}${TAB}Ensure your domain's DNS records (e.g., A record for ${DASHBOARD_DOMAIN}) point to your Proxmox host's public IP address."
echo -e "${TAB}${BGN}2. Router Port Forwarding:${CL}"
echo -e "${TAB}${TAB}Forward external ports 80 (HTTP), 443 (HTTPS), and 51820 (WireGuard) from your router to the IP address of LXC ${CTID}."
echo -e "${TAB}${BGN}3. Initial Dashboard Setup:${CL}"
echo -e "${TAB}${TAB}Access the Pangolin dashboard at https://${DASHBOARD_DOMAIN} and complete the initial organization, site, and resource configurations."
echo -e "${TAB}${TAB}Use the admin email: ${ADMIN_EMAIL} and the password you provided."
msg_ok "Pangolin deployment initiated. Please complete the manual steps."

# Cleanup on Proxmox host
msg_info "Cleaning up temporary files on Proxmox host"
# No specific temporary files created by this install script on host, beyond the script itself if downloaded.
# Standard apt cleanup is for the CT.
msg_ok "Host cleanup complete."

# Final success message for the install script
msg_ok "Pangolin Helper Script Finished Successfully!\n"
