#!/bin/bash
cd /home/container

# Information output
echo "echo -e "${YELLOW}Linux Distribution: ${RED} $(. /etc/os-release ; echo $PRETTY_NAME)${NC}" $(cat /etc/debian_version)"
echo "Current timezone: $([ -f /etc/timezone ] && cat /etc/timezone || echo "${TZ:-UTC}")"
wine --version

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

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
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER:-} ${STEAM_PASS:-} ${STEAM_AUTH:-} $( [[ "${WINDOWS_INSTALL:-}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${STEAM_APPID:-} $( [[ -z ${STEAM_BETAID:-} ]] || printf "%s" "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS:-} ]] || printf "%s" "-betapassword ${STEAM_BETAPASS}" ) $( [[ -z ${HLDS_GAME:-} ]] || printf "%s" "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE:-} ]] || printf "%s" "validate" ) +quit
    else
        echo -e "No appid set. Starting Server"
    fi
else
    echo -e "Not updating game server as auto update was set to 0. Starting Server"
fi

if [ "${XVFB:-}" = "1" ]; then
    Xvfb :0 -screen 0 ${DISPLAY_WIDTH:-1024}x${DISPLAY_HEIGHT:-768}x${DISPLAY_DEPTH:-16} &
fi

# Install necessary to run packages
echo "First launch will throw some errors. Ignore them"

mkdir -p $WINEPREFIX

# Check if wine-gecko required and install it if so
if [[ $WINETRICKS_RUN =~ gecko ]]; then
        echo "Installing Gecko"
        WINETRICKS_RUN=${WINETRICKS_RUN/gecko}

        if [ ! -f "$WINEPREFIX/gecko_x86.msi" ]; then
                wget -q -O $WINEPREFIX/gecko_x86.msi http://dl.winehq.org/wine/wine-gecko/2.47.2/wine_gecko-2.47.2-x86.msi
        fi

        if [ ! -f "$WINEPREFIX/gecko_x86_64.msi" ]; then
                wget -q -O $WINEPREFIX/gecko_x86_64.msi http://dl.winehq.org/wine/wine-gecko/2.47.2/wine_gecko-2.47.2-x86_64.msi
        fi

        wine msiexec /i $WINEPREFIX/gecko_x86.msi /qn /quiet /norestart /log $WINEPREFIX/gecko_x86_install.log
        wine msiexec /i $WINEPREFIX/gecko_x86_64.msi /qn /quiet /norestart /log $WINEPREFIX/gecko_x86_64_install.log
fi

# Check if wine-mono required and install it if so
if [[ $WINETRICKS_RUN =~ mono ]]; then
        echo "Installing mono"
        WINETRICKS_RUN=${WINETRICKS_RUN/mono}

        if [ ! -f "$WINEPREFIX/mono.msi" ]; then
                wget -q -O $WINEPREFIX/mono.msi https://dl.winehq.org/wine/wine-mono/10.0.0/wine-mono-10.0.0-x86.msi
        fi

        wine msiexec /i $WINEPREFIX/mono.msi /qn /quiet /norestart /log $WINEPREFIX/mono_install.log
fi

# List and install other packages
for trick in $WINETRICKS_RUN; do
        echo "Installing $trick"
        winetricks -q --force $trick
done

winetricks sound=disabled

# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi

