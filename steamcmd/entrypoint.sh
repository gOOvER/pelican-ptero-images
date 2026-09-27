#!/bin/bash
set -e

ERROR_LOG="install_error.log"
: > "$ERROR_LOG"  # Clear old log file (no-op)

# ----------------------------
# Colors via tput
# ----------------------------
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)

# ----------------------------
# Functions
# ----------------------------
msg() {
    local color="$1"
    shift
    # If RED, also write the message to install_error.log
    if [ "$color" = "RED" ]; then
        printf "%b\n" "${RED}$*${NC}" | tee -a "$ERROR_LOG" >&2
    else
        printf "%b\n" "${!color}$*${NC}"
    fi
}

line() {
    local color="${1:-BLUE}"
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 70)
    local sep
    sep=$(printf '%*s' "$term_width" '' | tr ' ' '-')

    # Use msg helper to print the separator with the requested color
    msg "$color" "$sep"
}

# ----------------------------
# Error trap for uncaught errors
# ----------------------------
trap 'echo "$(date +%Y-%m-%d\ %H:%M:%S) - Unexpected error at line $LINENO" | tee -a "$ERROR_LOG" >&2' ERR

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
LINUX=$(. /etc/os-release; echo "$PRETTY_NAME")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; else readlink /etc/localtime | sed 's|.*/zoneinfo/||'; fi)
# Kernel information from the host (name, release, architecture). Fallback to uname -r or 'unknown'.

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg RED "SteamCMD Image by gOOvER - https://dsc.gg/goover"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "Host System:"
msg YELLOW "  • Kernel:             ${RED}$KERNEL"
msg YELLOW "  • Virtualization:     ${RED}$VIRT"
line BLUE
msg YELLOW "Container System:"
msg YELLOW "  • Linux Distribution: ${RED}$LINUX"
msg YELLOW "  • Current timezone:   ${RED}$TIMEZONE"
line BLUE

# ----------------------------
# Environment
# ----------------------------
export TZ=${TZ:-UTC}
internal_ip=$(ip route get 1 | awk '{print $(NF-2);exit}' 2>/dev/null || echo "127.0.0.1")
export INTERNAL_IP="$internal_ip"
export XDG_RUNTIME_DIR="/home/container/.config/xdg"
mkdir -p "$XDG_RUNTIME_DIR"

# ----------------------------
# SteamCMD / DepotDownloader Update
# ----------------------------
: "${STEAM_USER:=anonymous}"
: "${STEAM_PASS:=}"
: "${STEAM_AUTH:=}"
: "${AUTO_UPDATE:=1}"

if [ -f ./DepotDownloader ]; then
    line BLUE
    msg YELLOW "Using DepotDownloader for updates"
    line BLUE

    msg YELLOW "Steam user: ${GREEN}$STEAM_USER"

    if [ "${AUTO_UPDATE}" = "1" ]; then
        dd_args=( -dir . -username "$STEAM_USER" -password "$STEAM_PASS" -remember-password )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            dd_args+=( -os windows )
        fi
        dd_args+=( -app "$STEAM_APPID" )
        if [ -n "${STEAM_BETAID:-}" ]; then
            dd_args+=( -branch "$STEAM_BETAID" )
        fi
        if [ -n "${STEAM_BETAPASS:-}" ]; then
            dd_args+=( -branchpassword "$STEAM_BETAPASS" )
        fi
        ./DepotDownloader "${dd_args[@]}" || { msg RED "DepotDownloader failed (exit $?)"; exit 1; }

        mkdir -p .steam/sdk64
        dd_sdk_args=( -dir .steam/sdk64 -app 1007 )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            dd_sdk_args+=( -os windows )
        fi
        ./DepotDownloader "${dd_sdk_args[@]}" || true  # SDK update failure is non-fatal

        # Only make actual executables executable, not all files
        find "$HOME" -maxdepth 1 -type f -executable -o -name "*.sh" -o -name "*.x86_64" -o -name "*.so" 2>/dev/null | xargs -r chmod +x
    else
        msg YELLOW "AUTO_UPDATE disabled - skipping update"
    fi
else
    line BLUE
    msg YELLOW "Using SteamCMD for updates"
    line BLUE

    msg YELLOW "Steam user: ${GREEN}$STEAM_USER"

    if [ "${AUTO_UPDATE}" = "1" ]; then
        sc_args=( +force_install_dir /home/container +login "$STEAM_USER" "$STEAM_PASS" "$STEAM_AUTH" )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            sc_args+=( +@sSteamCmdForcePlatformType windows )
        fi
        if [ "${STEAM_SDK:-0}" = "1" ]; then
            sc_args+=( +app_update 1007 )
        fi
        sc_args+=( +app_update "$STEAM_APPID" )
        if [ -n "${STEAM_BETAID:-}" ]; then
            sc_args+=( -beta "$STEAM_BETAID" )
        fi
        if [ -n "${STEAM_BETAPASS:-}" ]; then
            sc_args+=( -betapassword "$STEAM_BETAPASS" )
        fi
        if [ -n "${INSTALL_FLAGS:-}" ]; then
            IFS=' ' read -r -a extra_flags <<<"$INSTALL_FLAGS"
            sc_args+=( "${extra_flags[@]}" )
        fi
        # Respect VALIDATE flag
        if [ "${VALIDATE:-0}" = "1" ]; then
            sc_args+=( validate )
        fi
        sc_args+=( +quit )
        ./steamcmd/steamcmd.sh "${sc_args[@]}" || STEAMCMD_EXIT=$?
        STEAMCMD_EXIT=${STEAMCMD_EXIT:-0}
        # SteamCMD exit code 5 = no connection but may still have succeeded,
        # exit code 8 = unknown, treat anything >=10 as a real failure
        if [ "$STEAMCMD_EXIT" -ge 10 ]; then
            msg RED "SteamCMD failed with exit code $STEAMCMD_EXIT"
            exit "$STEAMCMD_EXIT"
        elif [ "$STEAMCMD_EXIT" -ne 0 ]; then
            msg YELLOW "SteamCMD exited with code $STEAMCMD_EXIT (non-fatal)"
        fi
    else
        msg YELLOW "AUTO_UPDATE disabled - skipping update"
    fi
fi


# ----------------------------
# Startup command
# ----------------------------

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"

exec bash -c "$MODIFIED_STARTUP"

