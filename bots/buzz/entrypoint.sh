#!/bin/bash
set -e

ERROR_LOG="entrypoint_error.log"
> "$ERROR_LOG"

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
    if [ "$color" = "RED" ]; then
        printf "%b\n" "${RED}$*${NC}" | tee -a "$ERROR_LOG" >&2
    else
        printf "%b\n" "${!color}$*${NC}"
    fi
}

line() {
    local color="${1:-BLUE}"
    local term_width=$(tput cols 2>/dev/null || echo 70)
    local sep=$(printf '%*s' "$term_width" '' | tr ' ' '-')

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
# Error trap
# ----------------------------
trap 'echo "$(date +"%Y-%m-%d %H:%M:%S") - Unexpected error at line $LINENO" | tee -a "$ERROR_LOG" >&2' ERR

# ----------------------------
# Environment
# ----------------------------
cd /home/container || { msg RED "Failed to change directory to /home/container."; exit 1; }

export TZ=${TZ:-UTC}

INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# ----------------------------
# System Info
# ----------------------------
clear
line BLUE
msg RED "Buzz Products Image by gOOvER - https://discord.goover.dev"
msg RED "This Image is licensed under AGPLv3"
line BLUE
msg YELLOW "Running on: ${RED}$(. /etc/os-release ; echo $NAME $VERSION)"
msg YELLOW "Current timezone: ${RED}$(cat /etc/timezone 2>/dev/null || echo $TZ)"
line BLUE
msg YELLOW "Node.js Version: ${RED}$(node -v)"
msg YELLOW "npm Version:     ${RED}$(npm -v)"
msg YELLOW "pnpm Version:    ${RED}$(pnpm -v 2>/dev/null || echo 'n/a')"
msg YELLOW "yarn Version:    ${RED}$(yarn -v 2>/dev/null || echo 'n/a')"
line BLUE

# ----------------------------
# Start Application
# ----------------------------
line BLUE
msg YELLOW "Starting application..."
line BLUE

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"

eval "$MODIFIED_STARTUP"
