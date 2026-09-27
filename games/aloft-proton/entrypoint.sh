#!/bin/bash

# ----------------------------
# Colors via tput (with fallback to basic ANSI)
# ----------------------------
if tput setaf 1 >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    NC=$(tput sgr0)
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

# ----------------------------
# Functions
# ----------------------------
msg() {
    local color="$1"
    shift
    local c
    case "$color" in
        RED) c="$RED";;
        GREEN) c="$GREEN";;
        YELLOW) c="$YELLOW";;
        BLUE) c="$BLUE";;
        CYAN) c="$CYAN";;
        *) c="$NC";;
    esac
    printf "%b\n" "${c}$*${NC}"
}

line() {
    local color="${1:-BLUE}"
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 70)
    [ "$term_width" -gt 100 ] && term_width=100
    [ "$term_width" -lt 40 ] && term_width=70
    local sep
    sep=$(printf '%*s' "$term_width" '' | tr ' ' '-')
    local c
    case "$color" in
        RED) c="$RED";;
        GREEN) c="$GREEN";;
        YELLOW) c="$YELLOW";;
        BLUE) c="$BLUE";;
        CYAN) c="$CYAN";;
        *) c="$NC";;
    esac
    printf "%b\n" "${c}${sep}${NC}"
}

detect_virt() {
    local vm=""

    if command -v systemd-detect-virt >/dev/null 2>&1; then
        local raw_vm
        raw_vm=$(systemd-detect-virt --vm 2>/dev/null || true)
        [ "$raw_vm" != "none" ] && [ -n "$raw_vm" ] && vm="$raw_vm"
    fi

    if [ -z "$vm" ] && grep -qi "microsoft" /proc/version 2>/dev/null; then
        vm="WSL2"
    fi

    if [ -z "$vm" ]; then
        local dmi_str=""
        for d in /sys/class/dmi/id /sys/devices/virtual/dmi/id; do
            if [ -d "$d" ]; then
                dmi_str="$(cat "$d/product_name" "$d/sys_vendor" "$d/bios_vendor" 2>/dev/null || true)"
                break
            fi
        done
        case "$dmi_str" in
            *KVM*|*Bochs*) vm="KVM";;
            *QEMU*) vm="QEMU";;
            *VMware*) vm="VMware";;
            *VirtualBox*|*innotek*) vm="VirtualBox";;
            *Hyper-V*|*Microsoft*) vm="Hyper-V";;
            *Xen*) vm="Xen";;
            *Amazon*|*EC2*) vm="KVM (AWS)";;
            *Google*) vm="KVM (GCP)";;
            *Proxmox*) vm="KVM (Proxmox)";;
        esac
    fi

    if [ -z "$vm" ] && [ -r /proc/device-tree/hypervisor/compatible ]; then
        local dt
        dt=$(cat /proc/device-tree/hypervisor/compatible 2>/dev/null || true)
        case "$dt" in
            *kvm*) vm="KVM";;
            *qemu*) vm="QEMU";;
            *xen*) vm="Xen";;
            *) [ -n "$dt" ] && vm="$dt";;
        esac
    fi

    if [ -z "$vm" ] && [ -r /proc/cpuinfo ]; then
        if grep -qi "QEMU Virtual CPU" /proc/cpuinfo 2>/dev/null; then
            vm="QEMU"
        elif grep -qi "Common KVM processor" /proc/cpuinfo 2>/dev/null; then
            vm="KVM"
        elif grep -qi "VMware" /proc/cpuinfo 2>/dev/null; then
            vm="VMware"
        elif grep -qE '^(flags|Features)[[:space:]]*:.*hypervisor' /proc/cpuinfo 2>/dev/null; then
            vm="Hypervisor"
        fi
    fi

    case "$vm" in
        kvm) vm="KVM";;
        qemu) vm="QEMU";;
        vmware) vm="VMware";;
        oracle) vm="VirtualBox";;
        microsoft) vm="Hyper-V";;
        xen) vm="Xen";;
        bochs) vm="Bochs";;
        parallels) vm="Parallels";;
        bhyve) vm="bhyve";;
        "") vm="Bare Metal";;
    esac

    echo "$vm"
}

# ----------------------------
# System Info
# ----------------------------
KERNEL=$(uname -r)
VIRT=$(detect_virt)
LINUX=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo "Linux")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; elif [ -L /etc/localtime ]; then readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||'; else echo "${TZ:-UTC}"; fi)
PROTON_VER=$(cat /usr/local/bin/version 2>/dev/null || cat /opt/ProtonGE/version 2>/dev/null || echo "Unknown")

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg RED "SteamCMD Proton-GE Image by gOOvER - https://dsc.gg/goover"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "Host System:"
msg YELLOW "  • Kernel:             ${RED}$KERNEL"
msg YELLOW "  • Virtualization:     ${RED}$VIRT"
line BLUE
msg YELLOW "Container System:"
msg YELLOW "  • Linux Distribution: ${RED}$LINUX"
msg YELLOW "  • Current timezone:   ${RED}$TIMEZONE"
msg YELLOW "  • Proton Version:     ${RED}${PROTON_VER}"
line BLUE

# ----------------------------
# Environment
# ----------------------------
cd /home/container || exit 1

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC
export TZ="${TZ:-UTC}"

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# Set environment for Steam Proton
if [ ! -z ${STEAM_APPID:-} ]; then
    mkdir -p /home/container/.steam/steam/steamapps/compatdata/${STEAM_APPID}
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/container/.steam/steam"
    export STEAM_COMPAT_DATA_PATH="/home/container/.steam/steam/steamapps/compatdata/${STEAM_APPID}"
    export WINETRICKS="/usr/sbin/winetricks"
    export STEAM_DIR="/home/container/.steam/steam/"

else
    echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
    echo -e "${RED}WARNING!!! Proton needs variable STEAM_APPID, else it will not work. Please add it${NC}"
    echo -e "${RED}Server stops now${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
    exit 0
fi

sleep 2

# Switch to the container's working directory
cd /home/container || exit 1

## just in case someone removed the defaults.
if [ "${STEAM_USER:-}" == "" ]; then
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Steam user is not set.\n ${NC}"
    echo -e "${YELLOW}Using anonymous user.\n ${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}user set to ${STEAM_USER} ${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
fi

## if auto_update is not set or to 1 update
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
	if [ -f /home/container/DepotDownloader ]; then
		./DepotDownloader -dir /home/container -username ${STEAM_USER} -password ${STEAM_PASS} -remember-password $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '-os windows' ) -app ${STEAM_APPID} $( [[ -z ${STEAM_BETAID} ]] || printf %s "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS} ]] || printf %s "-betapassword ${STEAM_BETAPASS}" )
		mkdir -p /home/container/.steam/sdk64
		./DepotDownloader -dir /home/container/.steam/sdk64 $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '-os windows' ) -app 1007
		chmod +x $HOME/*

	else
	   	./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) $( [[ "${STEAM_SDK}" == "1" ]] && printf %s '+app_update 1007' ) +app_update ${STEAM_APPID} $( [[ -z ${STEAM_BETAID} ]] || printf %s "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS} ]] || printf %s "-betapassword ${STEAM_BETAPASS}" ) ${INSTALL_FLAGS} $( [[ "${VALIDATE}" == "1" ]] && printf %s 'validate' ) +quit
	fi
else
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Not updating game server as auto update was set to 0. Starting Server${NC}"
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
fi

echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
echo -e "${GREEN}Starting Server.... Please wait...${NC}"
echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"

# List and install other packages
#for trick in $PROTONTRICKS_RUN; do
#        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
#        echo -e "${YELLOW}Installing: ${NC} ${GREEN} $trick ${NC}"
#        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
#        protontricks ${STEAM_APPID} $trick
#done

# ----------------------------
# Startup
# ----------------------------
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

msg CYAN ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi
