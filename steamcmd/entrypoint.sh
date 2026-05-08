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

# ----------------------------
# System Info
# ----------------------------
LINUX=$(. /etc/os-release; echo "$PRETTY_NAME")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; else readlink /etc/localtime | sed 's|.*/zoneinfo/||'; fi)
# Kernel information from the host (name, release, architecture). Fallback to uname -r or 'unknown'.
KERNEL_INFO=$(uname -srm 2>/dev/null || uname -r 2>/dev/null || echo 'unknown')

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg YELLOW "SteamCMD Image from gOOvER"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "Docker Linux Distribution: ${RED}$LINUX"
msg YELLOW "Kernel: ${RED}$KERNEL_INFO"
msg YELLOW "Current timezone: ${RED}$TIMEZONE"
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
        ./steamcmd/steamcmd.sh "${sc_args[@]}"
        STEAMCMD_EXIT=$?
        if [ $STEAMCMD_EXIT -ne 0 ]; then
            msg RED "SteamCMD failed with exit code $STEAMCMD_EXIT"
            exit $STEAMCMD_EXIT
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

