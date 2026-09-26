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

    case "$color" in
        RED) COLOR="$RED";;
        GREEN) COLOR="$GREEN";;
        YELLOW) COLOR="$YELLOW";;
        BLUE) COLOR="$BLUE";;
        CYAN) COLOR="$CYAN";;
        *) COLOR="$NC";;
    esac
    printf "%b\n" "${COLOR}${sep}${NC}"
}

# ----------------------------
# Error trap for uncaught errors
# ----------------------------
trap 'echo "$(date +%Y-%m-%d\ %H:%M:%S) - Unexpected error at line $LINENO" | tee -a "$ERROR_LOG" >&2' ERR

# ----------------------------
# Initialisierung & Banner
# ----------------------------
clear
sleep 1

export TZ=${TZ:-UTC}
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}' 2>/dev/null || echo "127.0.0.1")
export INTERNAL_IP

line BLUE
msg RED "Quake Live QLX Image by gOOvER - https://dsc.gg/goover"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "System Information:"
msg YELLOW "  • Linux Distribution: ${RED}$(. /etc/os-release ; echo $PRETTY_NAME)"
msg YELLOW "  • Current timezone:   ${RED}$([ -f /etc/timezone ] && cat /etc/timezone || echo "${TZ:-UTC}")"
msg YELLOW "  • Python Version:     ${RED}$(python3 --version 2>&1 | head -n 1)"
line BLUE

cd /home/container || { msg RED "Failed to change directory to /home/container."; exit 1; }

line BLUE
msg GREEN "Starting Server.... Please wait..."
line BLUE

if [ -z "${STEAM_USER:-}" ]; then
    line BLUE
    msg YELLOW "Steam user is not set."
    msg YELLOW "Using anonymous user."
    line BLUE
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    line BLUE
    msg YELLOW "user set to ${STEAM_USER}"
    line BLUE
fi

line BLUE
msg YELLOW "Using SteamCMD for updates"
line BLUE

: "${STEAM_USER:=anonymous}"
: "${STEAM_PASS:=}"
: "${STEAM_AUTH:=}"

msg YELLOW "Steam user: ${GREEN}$STEAM_USER"

# Falls STEAM_APPID nicht gesetzt ist, auf SRCDS_APPID zurückfallen
if [ -z "${STEAM_APPID:-}" ] && [ -n "${SRCDS_APPID:-}" ]; then
    STEAM_APPID="$SRCDS_APPID"
    msg YELLOW "STEAM_APPID not set, using SRCDS_APPID=${GREEN}$SRCDS_APPID"
fi

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
if [ "${VALIDATE:-0}" = "1" ]; then
    sc_args+=( validate )
fi
sc_args+=( +quit )
if [ ! -x ./steamcmd/steamcmd.sh ]; then
    msg RED "steamcmd binary ./steamcmd/steamcmd.sh not found or not executable"
else
    if ! ./steamcmd/steamcmd.sh "${sc_args[@]}"; then
        msg RED "SteamCMD returned non-zero exit code"
    fi
fi

# Replace Startup Variables
if [ -z "${STARTUP:-}" ]; then
    msg RED "No STARTUP command configured. Exiting."
    exit 1
fi

# Safely expand template variables like {{ENV}} -> ${ENV}
MODIFIED_STARTUP=$(printf '%s' "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ ${MODIFIED_STARTUP}"

# Use bash -lc to ensure complex startup commands (pipes, redirects) work correctly
exec bash -lc "$MODIFIED_STARTUP"

