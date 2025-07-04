#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/cr4b5/ProxmoxVED/refs/heads/pangolin/misc/build.func)
# Copyright (c) 2021-2025
# Author: cr4b5
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fosrl/pangolin

# Default Values for LXC Container Creation (as per AppName.sh-Scripts wiki)
APP="Pangolin"
var_tags="${var_tags:-pangolin}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-25}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# Parse arguments passed from the install script
# These variables are critical for non-interactive installer automation
BASE_DOMAIN="$1"
DASHBOARD_DOMAIN="$2"
LETSENCRYPT_EMAIL="$3"
ADMIN_EMAIL="$4"
ADMIN_PASSWORD="$5"

# Display application header
header_info "$APP"

# Apply base settings and process variables
base_settings
variables
color
catch_errors

# Main installation logic
msg_info "Updating OS and installing dependencies"
update_os # Update OS
$STD apt-get install -y curl wget gnupg2 ca-certificates jq # jq for GitHub API parsing in update_script
msg_ok "OS updated and dependencies installed"

msg_info "Downloading Pangolin installer"
# Fetch the latest release URL dynamically
LATEST_RELEASE_URL=$(curl -s "https://api.github.com/repos/fosrl/pangolin/releases/latest" | jq -r '.assets | select(.name | contains("installer_linux_amd64")) |.browser_download_url')
LATEST_VERSION=$(curl -s "https://api.github.com/repos/fosrl/pangolin/releases/latest" | jq -r '.tag_name')

if]; then
    msg_error "Failed to retrieve latest Pangolin installer URL. Exiting."
    exit_script
fi

$STD wget -O /usr/local/bin/pangolin-installer "$LATEST_RELEASE_URL"
$STD chmod +x /usr/local/bin/pangolin-installer
msg_ok "Pangolin installer downloaded and made executable"

msg_info "Running Pangolin installer (non-interactive)"
# Simulate user input for the interactive installer using a here-document
# The installer expects inputs in a specific order.
# Gerbil default is 'yes', disable signup 'yes', disable org creation 'no'.
# Ensure these match the installer's expected defaults or provide explicit 'yes/no'
cat <<EOF | /usr/local/bin/pangolin-installer text &>/dev/null
$BASE_DOMAIN
$DASHBOARD_DOMAIN
$LETSENCRYPT_EMAIL
yes
$ADMIN_EMAIL
$ADMIN_PASSWORD
$ADMIN_PASSWORD
yes
no
EOF

if [[ $? -ne 0 ]]; then
    msg_error "Pangolin installer failed. Check logs for details."
    exit_script
fi
msg_ok "Pangolin installed successfully"

# Create version file for update script
echo "${LATEST_VERSION}" > /opt/${APP}_version.txt

# Ensure Pangolin service is running and enabled
msg_info "Ensuring Pangolin service is active"
$STD systemctl enable --now pangolin &>/dev/null
if systemctl is-active --quiet pangolin; then
    msg_ok "Pangolin service is active and enabled"
else
    msg_error "Pangolin service failed to start. Manual intervention may be required."
    exit_script
fi

# Display access information
motd_ssh
customize
msg_ok "Pangolin deployment completed successfully!"
echo -e "${TAB}${GATEWAY}${BGN}Access Pangolin Dashboard: https://${DASHBOARD_DOMAIN}${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Note: Ensure DNS records are configured and ports 80, 443, 51820 are forwarded to this container's IP.${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Initial admin login: Email: ${ADMIN_EMAIL}, Password: ${ADMIN_PASSWORD}${CL}"

# Cleanup
msg_info "Cleaning up installer"
$STD rm -f /usr/local/bin/pangolin-installer
$STD apt-get -y autoremove &>/dev/null
$STD apt-get -y autoclean &>/dev/null
msg_ok "Cleanup complete"

# End of script functions
start
build_container
description
msg_ok "Completed Successfully!\n"

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    msg_info "Checking for ${APP} installation"
    if [[! -d /etc/pangolin ]]; then # Pangolin installs to /etc/pangolin by default
        msg_error "No ${APP} Installation Found! Cannot update."
        exit_script
    fi
    msg_ok "${APP} installation found."

    msg_info "Checking for latest ${APP} version"
    local_version="$(cat /opt/${APP}_version.txt)"
    latest_release_tag=$(curl -s "https://api.github.com/repos/fosrl/pangolin/releases/latest" | jq -r '.tag_name')

    if [[ -z "$latest_release_tag" ]]; then
        msg_error "Failed to retrieve latest Pangolin release tag from GitHub. Cannot check for updates."
        exit_script
    fi

    if [[ "${latest_release_tag}" == "${local_version}" ]]; then
        msg_ok "No update required. ${APP} is already at v${local_version}."
        exit
    fi

    msg_info "Updating ${APP} from v${local_version} to v${latest_release_tag}"

    # Download the new installer
    LATEST_RELEASE_URL=$(curl -s "https://api.github.com/repos/fosrl/pangolin/releases/latest" | jq -r '.assets | select(.name | contains("installer_linux_amd64")) |.browser_download_url')
    if]; then
        msg_error "Failed to retrieve latest Pangolin installer URL for update. Exiting."
        exit_script
    fi

    $STD wget -O /usr/local/bin/pangolin-installer_new "$LATEST_RELEASE_URL"
    $STD chmod +x /usr/local/bin/pangolin-installer_new

    # Run the new installer. Pangolin's installer handles updates by re-running.
    # It should detect existing configuration.
    msg_info "Running new installer to update Pangolin"
    # Re-running the installer should handle update. It should pick up existing config.
    # We still need to provide the interactive inputs, even if they are defaults, to prevent it from hanging.
    cat <<EOF | /usr/local/bin/pangolin-installer_new text &>/dev/null
$BASE_DOMAIN
$DASHBOARD_DOMAIN
$LETSENCRYPT_EMAIL
yes
$ADMIN_EMAIL
$ADMIN_PASSWORD
$ADMIN_PASSWORD
yes
no
EOF

    if [[ $? -ne 0 ]]; then
        msg_error "Pangolin update failed. Check logs for details."
        exit_script
    fi
    msg_ok "${APP} updated to v${latest_release_tag}"

    # Update version file
    echo "${latest_release_tag}" > /opt/${APP}_version.txt

    # Cleanup new installer
    msg_info "Cleaning up new installer"
    $STD rm -f /usr/local/bin/pangolin-installer_new
    msg_ok "Cleanup complete"
}
