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

# ----------------------------
# System Info
# ----------------------------
LINUX=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo "Linux")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; elif [ -L /etc/localtime ]; then readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||'; else echo "${TZ:-UTC}"; fi)
JAVA_VER=$(if command -v java >/dev/null 2>&1; then java -version 2>&1 | head -n 1; else echo "Java not found"; fi)

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg RED "Wurm Unlimited Image by gOOvER - https://dsc.gg/goover"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "System Information:"
msg YELLOW "  • Linux Distribution: ${RED}$LINUX"
msg YELLOW "  • Current timezone:   ${RED}$TIMEZONE"
msg YELLOW "  • Java Version: ${RED}${JAVA_VER}"
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
if [ -z "${AUTO_UPDATE:-}" ] || [ "${AUTO_UPDATE:-}" = "1" ]; then
    # Update Source Server
    if [ -n "${STEAM_APPID:-}" ]; then
        if [ "${STEAM_USER:-}" = "anonymous" ]; then
            ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER:-} ${STEAM_PASS:-} ${STEAM_AUTH:-} $( [[ "${WINDOWS_INSTALL:-}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${STEAM_APPID:-} $( [[ -z ${STEAM_BETAID:-} ]] || printf "%s" "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS:-} ]] || printf "%s" "-betapassword ${STEAM_BETAPASS}" ) $( [[ -z ${HLDS_GAME:-} ]] || printf "%s" "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE:-} ]] || printf "%s" "validate" ) +quit
        else
            numactl --physcpubind=+0 ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER:-} ${STEAM_PASS:-} ${STEAM_AUTH:-} $( [[ "${WINDOWS_INSTALL:-}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${STEAM_APPID:-} $( [[ -z ${STEAM_BETAID:-} ]] || printf "%s" "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS:-} ]] || printf "%s" "-betapassword ${STEAM_BETAPASS}" ) $( [[ -z ${HLDS_GAME:-} ]] || printf "%s" "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE:-} ]] || printf "%s" "validate" ) +quit
        fi
    else
        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}No appid set. Starting Server${NC}"
        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    fi

else
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Not updating game server as auto update was set to 0. Starting Server${NC}"
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
fi

if [ "${XVFB:-}" = "1" ]; then
    Xvfb :0 -screen 0 ${DISPLAY_WIDTH:-1024}x${DISPLAY_HEIGHT:-768}x${DISPLAY_DEPTH:-16} &
fi

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
