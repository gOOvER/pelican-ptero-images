#!/bin/bash
set -euo pipefail

#System variables
clear
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Switch to the container's working directory
cd /home/container || exit 1

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# system informations
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${RED}Java Liberica Image by gOOvER - https://discord.goover.dev${NC}"
echo -e "${RED}THIS IMAGE IS LICENSED UNDER AGPLv3${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Linux Distribution: ${RED} $(. /etc/os-release ; echo $PRETTY_NAME)${NC}"
echo -e "${YELLOW}Current timezone: ${RED} $(cat /etc/timezone)${NC}"
echo -e "${YELLOW}Java Version: ${RED} $(java -version 2>&1) ${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@gameservertech~ \033[0m%s\n" "$PARSED"
# shellcheck disable=SC2086
exec env ${PARSED}

