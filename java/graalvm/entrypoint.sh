#!/bin/bash
set -e

ERROR_LOG="entrypoint_error.log"
: > "$ERROR_LOG"  # Clear old log file

# ----------------------------
# Colors via tput (with fallback for non-interactive terminals)
# ----------------------------
if [ -t 1 ] && command -v tput &>/dev/null; then
    RED=$(tput setaf 1 2>/dev/null || echo "")
    GREEN=$(tput setaf 2 2>/dev/null || echo "")
    YELLOW=$(tput setaf 3 2>/dev/null || echo "")
    BLUE=$(tput setaf 4 2>/dev/null || echo "")
    CYAN=$(tput setaf 6 2>/dev/null || echo "")
    NC=$(tput sgr0 2>/dev/null || echo "")
else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" NC=""
fi

# ----------------------------
# Functions
# ----------------------------
msg() {
    local color="$1"
    shift
    # If RED, also write the message to entrypoint_error.log
    if [ "$color" = "RED" ]; then
        printf "%b\n" "${RED}$*${NC}" | tee -a "$ERROR_LOG" >&2
    else
        printf "%b\n" "${!color}$*${NC}"
    fi
}

line() {
    local color="${1:-BLUE}"
    local term_width
    local sep
    local line_color

    term_width=$(tput cols 2>/dev/null || echo 70)
    sep=$(printf '%*s' "$term_width" '' | tr ' ' '-')

    case "$color" in
        RED) line_color="$RED";;
        GREEN) line_color="$GREEN";;
        YELLOW) line_color="$YELLOW";;
        BLUE) line_color="$BLUE";;
        CYAN) line_color="$CYAN";;
        *) line_color="$NC";;
    esac
    printf "%b\n" "${line_color}${sep}${NC}"
}

# ----------------------------
# Error trap for uncaught errors
# ----------------------------
trap 'echo "$(date +%Y-%m-%d\ %H:%M:%S) - Unexpected error at line $LINENO" | tee -a "$ERROR_LOG" >&2' ERR

# ----------------------------
# Environment
# ----------------------------
cd /home/container || { msg RED "Failed to change directory to /home/container."; exit 1; }

sleep 1

# Default the TZ environment variable to UTC
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# ----------------------------
# System Info
# ----------------------------
LINUX=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo "Unknown")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; elif [ -L /etc/localtime ]; then readlink /etc/localtime | sed 's|.*/zoneinfo/||'; else echo "$TZ"; fi)
JAVA_VER=$(java -version 2>&1 | head -n 1 || echo "Java not found")

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg RED "Java GraalVM Community Image by gOOvER - https://dsc.gg/goover"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "Linux Distribution: ${RED}$LINUX"
msg YELLOW "Current timezone: ${RED}$TIMEZONE"
msg YELLOW "Java Version: ${RED}$JAVA_VER"
line BLUE

# ----------------------------
# Startup command
# ----------------------------
# Replace {{VAR}} with ${VAR} syntax for variable expansion
# Using envsubst for safe variable substitution (prevents command injection)
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | envsubst)

msg CYAN ":/home/container$ ${PARSED}"

# Execute the startup command
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${PARSED}"
else
    exec sh -c "${PARSED}"
fi

