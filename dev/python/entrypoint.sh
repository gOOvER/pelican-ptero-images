#!/bin/bash
set -e

ERROR_LOG="install_error.log"
> "$ERROR_LOG" # Alte Logdatei leeren

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
    # Wenn ROT, zusätzlich in install_error.log schreiben
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
trap 'echo "$(date +%Y-%m-%d %H:%M:%S) - Unexpected error at line $LINENO" | tee -a "$ERROR_LOG" >&2' ERR

# stop cleanly on container shutdown
trap "echo 'Received stop signal, shutting down...'; exit" SIGINT SIGTERM

# ----------------------------
# System Info
# ----------------------------
LINUX=$(. /etc/os-release; echo "$PRETTY_NAME")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; else readlink /etc/localtime | sed 's|.*/zoneinfo/||'; fi)
PYTHON_VER=$(python --version 2>&1 || echo "Python not found!")

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg YELLOW "Python Image from gOOvER"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "Docker Linux Distribution: ${RED}$LINUX"
msg YELLOW "Current timezone: ${RED}$TIMEZONE"
msg YELLOW "Python Version: ${RED}$PYTHON_VER"
line BLUE

# ----------------------------
# Environment
# ----------------------------
export TZ=${TZ:-UTC}
export INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")

cd /home/container || { msg RED "Failed to change directory to /home/container."; exit 1; }

# ----------------------------
# Startup
# ----------------------------
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi

