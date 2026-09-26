#!/bin/bash

clear
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Default the IMAGE_PROMPT environment variable to something nice
IMAGE_PROMPT=${IMAGE_PROMPT:-$'\033[1m\033[33mcontainer@gameservertech~ \033[0m'}
export IMAGE_PROMPT

# Information output
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Alpine Image by gOOvER - https://dsc.gg/goover${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@gameservertech~ \033[0m%s\n" "$PARSED"
# shellcheck disable=SC2086
exec env ${PARSED}
