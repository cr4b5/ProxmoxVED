#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Cr4b5
# License: AGPL-3.0 | https://github.com/fosrl/pangolin?tab=AGPL-3.0-1-ov-file#readme
# Source: https://github.com/fosrl/pangolin

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

get_latest_release() {
    curl -fsSL https://api.github.com/repos/"$1"/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

PANGOLIN_LATEST_VERSION=$(get_latest_release "fosrl/pangolin")

msg_info "Installing Pangolin $PANGOLIN_LATEST_VERSION"
#mkdir -p pangolin
$STD sh <(curl -fsSL -o installer "https://github.com/fosrl/pangolin/releases/download/"$PANGOLIN_LATEST_VERSION"/installer_linux_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" && chmod +x ./installer)
msg_ok "Installed Pangolin $PANGOLIN_LATEST_VERSION"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
