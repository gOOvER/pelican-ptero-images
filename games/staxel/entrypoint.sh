#!/bin/bash
# Switch to the container's working directory
cd /home/container

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

mkdir -p /home/container/.steam/steam/steamapps/compatdata/${STEAM_APPID}
export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/container/.steam/steam"
export STEAM_COMPAT_DATA_PATH="/home/container/.steam/steam/steamapps/compatdata/${STEAM_APPID}"

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

## just in case someone removed the defaults.
if [ "${STEAM_USER:-}" == "" ]; then
    echo -e "steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

## if auto_update is not set or to 1 update
if [ -z "${AUTO_UPDATE:-}" ] || [ "${AUTO_UPDATE:-}" = "1" ]; then
    # Update Source Server
    if [ -n "${STEAM_APPID:-}" ]; then
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER:-} ${STEAM_PASS:-} ${STEAM_AUTH:-} +app_update ${STEAM_APPID:-} $( [[ -z ${STEAM_BETAID:-} ]] || printf "%s" "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS:-} ]] || printf "%s" "-betapassword ${STEAM_BETAPASS}" ) $( [[ -z ${HLDS_GAME:-} ]] || printf "%s" "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE:-} ]] || printf "%s" "validate" ) +quit
    else
        echo -e "No appid set. Starting Server"
    fi

else
    echo -e "Not updating game server as auto update was set to 0. Starting Server"
fi

Xvfb :0 -screen 0 1024x768x16 &

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "[1m[33mcontainer@gameservertech~ [0m%s
" "$MODIFIED_STARTUP"
# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi

