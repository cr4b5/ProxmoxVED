#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/cr4b5/ProxmoxVED/refs/heads/pangolin/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Cr4b5
# License: AGPL-3.0 | https://github.com/fosrl/pangolin?tab=AGPL-3.0-1-ov-file#readme
# Source: https://github.com/fosrl/pangolin

# App Default Values
# Name of the app (e.g. Google, Adventurelog, Apache-Guacamole"
APP="[Pangolin]"
# Tags for Proxmox VE, maximum 2 pcs., no spaces allowed, separated by a semicolon ; (e.g. database | adblock;dhcp)
var_tags="${var_tags:-rproxy;iam}"
# Number of cores (1-X) (e.g. 4) - default are 2
var_cpu="${var_cpu:-2}"
# Amount of used RAM in MB (e.g. 2048 or 4096)
var_ram="${var_ram:-2048}"
# Amount of used disk space in GB (e.g. 4 or 10)
var_disk="${var_disk:-8}"
# Default OS (e.g. debian, ubuntu, alpine)
var_os="${var_os:-ubuntu}"
# Default OS version (e.g. 12 for debian, 24.04 for ubuntu, 3.20 for alpine)
var_version="${var_version:-24.10}"
# 1 = unprivileged container, 0 = privileged container
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /var ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP} LXC"
    $STD apt-get update
    $STD apt-get -y upgrade
    msg_ok "Updated ${APP} LXC"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
