#!/bin/bash
set -euo pipefail

ERROR_LOG="install_error.log"
: > "$ERROR_LOG"

# ----------------------------
# Colors via tput (with fallback to basic ANSI if tput not available)
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
	local COLOR

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
# Print timestamp, failing command and line number
# ----------------------------
rc=0
trap 'rc=$?; echo "$(date "+%Y-%m-%d %H:%M:%S") - Unexpected error (exit $rc) at line $LINENO: \"${BASH_COMMAND}\"" | tee -a "$ERROR_LOG" >&2; exit $rc' ERR

# System initialization
clear

# Switch to the container's working directory
cd /home/container || exit 1

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || true)
if [ -z "$INTERNAL_IP" ]; then
	# Fallback: try hostname -I or 127.0.0.1
	INTERNAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
fi
INTERNAL_IP=${INTERNAL_IP:-127.0.0.1}
export INTERNAL_IP

# system informations
line BLUE
msg RED "NodeJS Image by gOOvER - https://dsc.gg/goover"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "Linux Distribution: $(. /etc/os-release ; echo $PRETTY_NAME)"
## Determine and display current timezone robustly
TZ_DISPLAY=""
if [ -f /etc/timezone ]; then
	TZ_DISPLAY=$(cat /etc/timezone 2>/dev/null || true)
elif [ -L /etc/localtime ]; then
	# If /etc/localtime is a symlink into /usr/share/zoneinfo, extract the zone name
	LINK=$(readlink -f /etc/localtime 2>/dev/null || true)
	case "$LINK" in
		*/usr/share/zoneinfo/*)
			TZ_DISPLAY=${LINK#/usr/share/zoneinfo/}
			;;
	esac
fi
if [ -z "$TZ_DISPLAY" ]; then
	# Fallback to TZ env or UTC
	TZ_DISPLAY=${TZ:-UTC}
	msg YELLOW "Current timezone: (zone file missing) defaulting to ${TZ_DISPLAY}"
else
	msg YELLOW "Current timezone: ${TZ_DISPLAY}"
fi
line BLUE
if command -v node >/dev/null 2>&1; then
	msg YELLOW "NodeJS Version: $(node -v)"
else
	msg RED "Node not found in PATH"
fi
if command -v npm >/dev/null 2>&1; then
	msg YELLOW "npm Version: $(npm -v)"
else
	msg RED "npm not found in PATH"
fi
line BLUE

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server — replace this shell with the server process (safer than eval)
exec bash -lc "${MODIFIED_STARTUP}"

