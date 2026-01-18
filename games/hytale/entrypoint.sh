#!/bin/bash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Simple colors via tput (fallback to no color if unavailable)
RED=$(tput setaf 1 2>/dev/null || echo '')
GREEN=$(tput setaf 2 2>/dev/null || echo '')
YELLOW=$(tput setaf 3 2>/dev/null || echo '')
BLUE=$(tput setaf 4 2>/dev/null || echo '')
CYAN=$(tput setaf 6 2>/dev/null || echo '')
NC=$(tput sgr0 2>/dev/null || echo '')

ERROR_LOG="/home/container/install_error.log"

# Message helpers
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
    msg "$color" "$sep"
}

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Refresh temporary directory to avoid stale downloads between restarts
rm -rf /home/container/.tmp
mkdir -p /home/container/.tmp



# Hytale Downloader Configuration
DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"
DOWNLOADER_BIN="${DOWNLOADER_BIN:-/home/container/hytale-downloader}"
AUTO_UPDATE=${AUTO_UPDATE:-0}
PATCHLINE=${PATCHLINE:-release}
CREDENTIALS_PATH="${CREDENTIALS_PATH:-/home/container/.hytale-downloader-credentials.json}"
DOWNLOADER_ARGS=()

# API Authentication (Device Code Flow) configuration
HYTALE_API_AUTH=${HYTALE_API_AUTH:-0}
HYTALE_PROFILE_UUID=${HYTALE_PROFILE_UUID:-}
HYTALE_AUTH_STATE_PATH="${HYTALE_AUTH_STATE_PATH:-/home/container/.hytale-auth.json}"
HYTALE_OAUTH_CLIENT_ID="hytale-server"
HYTALE_OAUTH_SCOPE="openid offline auth:server"
HYTALE_DEVICE_AUTH_URL="https://oauth.accounts.hytale.com/oauth2/device/auth"
HYTALE_TOKEN_URL="https://oauth.accounts.hytale.com/oauth2/token"
HYTALE_PROFILES_URL="https://account-data.hytale.com/my-account/get-profiles"
HYTALE_SESSION_URL="https://sessions.hytale.com/game-session/new"
HYTALE_SESSION_REFRESH_URL="https://sessions.hytale.com/game-session/refresh"
HYTALE_DEVICE_POLL_INTERVAL=5
HYTALE_TOKEN_EXPIRY_BUFFER=300

# Plugin Configuration
PSAVER=${PSAVER:-0}
PSAVER_RELEASES_URL="https://api.github.com/repos/nitrado/hytale-plugin-performance-saver/releases/latest"
PSAVER_PLUGINS_DIR="/home/container/mods"
PSAVER_JAR_NAME="Nitrado_PerformanceSaver"

# Version and filter patterns
VERSION_PATTERN='^[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[a-f0-9]+'
DOWNLOADER_OUTPUT_FILTER="Please visit|Path to credentials file|Authorization code:"

# Cleanup invalid version file (e.g., if it contains auth prompts)
if [ -f "/home/container/.version" ]; then
    if ! grep -qE "$VERSION_PATTERN" "/home/container/.version"; then
        msg YELLOW "Warning: Invalid .version content detected; removing file"
        rm -f "/home/container/.version"
    fi
fi

# Print Java version
msg BLUE "System Information"
line "CYAN"
msg CYAN "Runtime Information:"
java -version 2>&1 | sed "s/^/  /"

# Detect CPU architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_DISPLAY="AMD64 (x86_64)"
        ;;
    aarch64)
        ARCH_DISPLAY="ARM64 (aarch64)"
        ;;
    *)
        ARCH_DISPLAY="$ARCH (unknown)"
        ;;
esac
msg CYAN "System Architecture: $ARCH_DISPLAY"

# Check for downloader updates first thing
line "BLUE"
if [ -f "$DOWNLOADER_BIN" ]; then
    msg BLUE "[startup] Checking for downloader updates..."
    if "$DOWNLOADER_BIN" "${DOWNLOADER_ARGS[@]}" -check-update 2>&1 | sed "s/.*/  ${CYAN}&${NC}/"; then
        msg GREEN "  ✓ Downloader is up to date"
        if [ -f "$CREDENTIALS_PATH" ]; then
            msg GREEN "  ✓ Valid downloader auth file found"
        fi
    else
        msg YELLOW "  Note: Downloader update check completed"
    fi
fi

# Function to install Hytale Downloader
install_downloader() {
    msg BLUE "[installer] Downloader not found, installing..."

    local TEMP_DIR="/home/container/.tmp/hytale-downloader-install"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"

    # Download downloader
    msg BLUE "[installer] Downloading downloader package..."
    if ! wget -O "$TEMP_DIR/downloader.zip" "$DOWNLOADER_URL"; then
        msg RED "Error: Failed to download Hytale Downloader"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # Extract downloader
    msg BLUE "[installer] Extracting downloader..."
    if ! unzip -o "$TEMP_DIR/downloader.zip" -d "$TEMP_DIR"; then
        msg RED "Error: Failed to extract Hytale Downloader"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # Copy to target location
    if [ -f "$TEMP_DIR/hytale-downloader" ]; then
        cp "$TEMP_DIR/hytale-downloader" "$DOWNLOADER_BIN"
        chmod +x "$DOWNLOADER_BIN"
        msg GREEN "✓ Hytale Downloader installed successfully"
    else
        msg RED "Error: Downloader binary not found in archive"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # Cleanup
    rm -rf "$TEMP_DIR"
    return 0
}

# Function to initialize credentials file if needed
initialize_credentials() {
    # If credentials file does not exist yet, trigger an initial run without args
    # so the downloader can guide through device auth and create the file.
    if [ ! -f "$CREDENTIALS_PATH" ]; then
        msg BLUE "[auth] Initializing downloader to create credentials (one-time)..."
        "$DOWNLOADER_BIN" -print-version -skip-update-check 2>&1 | sed "s/.*/  ${CYAN}&${NC}/"
        if [ -f "$CREDENTIALS_PATH" ]; then
            msg GREEN "  ✓ Credentials file created"
            # Add credentials to downloader args if not already present
            if [[ ! " ${DOWNLOADER_ARGS[*]} " =~ " -credentials-path " ]]; then
                DOWNLOADER_ARGS+=("-credentials-path" "$CREDENTIALS_PATH")
            fi
        else
            msg YELLOW "  Note: Credentials file not created yet; continuing without it"
        fi
    fi
}

# Check for updates
check_for_updates() {
    msg BLUE "[update] Checking for Hytale server updates..."

    if [ ! -f "$DOWNLOADER_BIN" ]; then
        if ! install_downloader; then
            msg RED "Error: Failed to install Hytale Downloader"
            return 1
        fi
    fi

    # Initialize credentials if needed
    initialize_credentials

    # Get current game version
    CURRENT_VERSION=$(timeout 10 "$DOWNLOADER_BIN" "${DOWNLOADER_ARGS[@]}" -print-version -skip-update-check 2>/dev/null \
        | grep -v -i -E "$DOWNLOADER_OUTPUT_FILTER" \
        | head -1)

    if [ -z "$CURRENT_VERSION" ]; then
        msg YELLOW "Warning: Could not determine game version"
        return 1
    fi

    msg GREEN "Current game version: $CURRENT_VERSION"
    return 0
}

# Function to download and update Hytale
download_hytale() {
    msg BLUE "[update] Checking for Hytale updates..."

    if [ ! -f "$DOWNLOADER_BIN" ]; then
        if ! install_downloader; then
            msg RED "Error: Failed to install Hytale Downloader"
            return 1
        fi
    fi

    # Initialize credentials if needed
    initialize_credentials

    # Check local version
    LOCAL_VERSION=""
    if [ -f "/home/container/.version" ]; then
        # Read only a valid version line, ignore any accidental prompt leftovers
        LOCAL_VERSION=$(grep -E "$VERSION_PATTERN" -m1 \
            "/home/container/.version" 2>/dev/null)
    fi

    msg CYAN "  Local version: ${LOCAL_VERSION:-none installed}"

    # Get remote version without downloading
    msg BLUE "[update 1/3] Fetching remote version..."
    REMOTE_VERSION=$(timeout 10 "$DOWNLOADER_BIN" "${DOWNLOADER_ARGS[@]}" -patchline "$PATCHLINE" -print-version -skip-update-check 2>/dev/null \
        | grep -v -i -E "$DOWNLOADER_OUTPUT_FILTER" \
        | head -1)

    if [ -z "$REMOTE_VERSION" ]; then
        msg RED "Error: Could not determine remote version"
        return 1
    fi

    msg CYAN "  Remote version: $REMOTE_VERSION"

    # Compare versions - if same, skip everything
    if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ] && [ -f "/home/container/HytaleServer.jar" ]; then
        msg GREEN "✓ Already running version $REMOTE_VERSION - no update needed"
        return 0
    fi

    # Version is different, download and install
    msg BLUE "[update 2/3] Downloading Hytale build..."

    # Create temporary directory for download
    DOWNLOAD_DIR="/home/container/.tmp/hytale-download"
    rm -rf "$DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR"

    # Run downloader inside download dir so it names the zip itself
    if ! (cd "$DOWNLOAD_DIR" && "$DOWNLOADER_BIN" "${DOWNLOADER_ARGS[@]}" -patchline "$PATCHLINE" -skip-update-check 2>&1 | sed "s/.*/  ${CYAN}&${NC}/"); then
        msg RED "Error: Hytale Downloader failed"
        rm -rf "$DOWNLOAD_DIR"
        return 1
    fi

    # Locate downloaded zip (should be directly in DOWNLOAD_DIR)
    GAME_ZIP=$(find "$DOWNLOAD_DIR" -maxdepth 1 -name "*.zip" -type f | head -n 1)

    if [ -z "$GAME_ZIP" ] || [ ! -f "$GAME_ZIP" ]; then
        msg RED "Error: No zip file found in download directory"
        rm -rf "$DOWNLOAD_DIR"
        return 1
    fi

    # Extract downloaded files
    msg BLUE "[update 3/3] Extracting and installing..."
    if ! unzip -o "$GAME_ZIP" -d "$DOWNLOAD_DIR"; then
        msg RED "Error: Failed to extract Hytale server files"
        rm -rf "$DOWNLOAD_DIR"
        return 1
    fi

    # Copy Server folder contents and Assets.zip to container root
    if [ -d "$DOWNLOAD_DIR/Server" ]; then
        # Move all files from Server folder to /home/container
        cp -r "$DOWNLOAD_DIR/Server/"* /home/container/ || return 1
        msg GREEN "  ✓ Server files installed"
    else
        msg RED "Error: Server folder not found in downloaded files"
        rm -rf "$DOWNLOAD_DIR"
        return 1
    fi

    if [ -f "$DOWNLOAD_DIR/Assets.zip" ]; then
        cp "$DOWNLOAD_DIR/Assets.zip" /home/container/ || return 1
        msg GREEN "  ✓ Assets installed"
    else
        msg YELLOW "Warning: Assets.zip not found in downloaded files"
    fi

    # Save version
    echo "$REMOTE_VERSION" > "/home/container/.version"

    # Cleanup
    rm -rf "$DOWNLOAD_DIR"

    msg GREEN "✓ Hytale server updated to version $REMOTE_VERSION"

    # Clean up entire temp directory after successful installation
    rm -rf /home/container/.tmp

    return 0
}

# Check for game files and handle AUTO_UPDATE
line "BLUE"
if [ "$AUTO_UPDATE" = "1" ]; then
    msg CYAN "Auto-update enabled, downloading latest version..."
    if download_hytale; then
        msg GREEN "✓ Server ready to start"
    else
        msg RED "Error: Auto-update failed, server will not start"
        exit 1
    fi
else
    # Check for existing game files
    if [ ! -f "/home/container/HytaleServer.jar" ] && [ ! -d "/home/container/Server" ]; then
        msg YELLOW "No Hytale server files found"
        msg CYAN "Set AUTO_UPDATE=1 to automatically download files"

        # Try to check for updates anyway
        check_for_updates || true
    else
        # Check for updates in background when server exists
        check_for_updates || true
    fi
fi

# Function to manage Performance Saver plugin
line "BLUE"
manage_psaver() {
    # Create mods directory if it doesn't exist
    mkdir -p "$PSAVER_PLUGINS_DIR"

    if [ "$PSAVER" = "1" ]; then
        # PSAVER=1: Install and enable the plugin
        msg BLUE "[plugin] Checking Performance Saver plugin..."

        # Check if a jar matching the pattern exists (enabled)
        EXISTING_JAR=$(find "$PSAVER_PLUGINS_DIR" -maxdepth 1 -type f -name "${PSAVER_JAR_NAME}*.jar" ! -name "*.disabled" 2>/dev/null | head -n 1)

        if [ -n "$EXISTING_JAR" ]; then
            msg GREEN "  ✓ Performance Saver already installed and enabled"
            return 0
        fi

        # Check if a disabled version exists
        DISABLED_JAR=$(find "$PSAVER_PLUGINS_DIR" -maxdepth 1 -type f -name "${PSAVER_JAR_NAME}*.jar.disabled" 2>/dev/null | head -n 1)

        if [ -n "$DISABLED_JAR" ]; then
            msg BLUE "  Re-enabling Performance Saver..."
            mv "$DISABLED_JAR" "${DISABLED_JAR%.disabled}"
            msg GREEN "  ✓ Performance Saver re-enabled"
            return 0
        fi

        # Download and install the plugin
        msg BLUE "  Downloading Performance Saver plugin..."
        TEMP_PSAVER_DIR="/home/container/.tmp/psaver-install"
        rm -rf "$TEMP_PSAVER_DIR"
        mkdir -p "$TEMP_PSAVER_DIR"

        # Get latest release download URL
        DOWNLOAD_URL=$(wget -q -O - "$PSAVER_RELEASES_URL" 2>>"$ERROR_LOG" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\.jar\)".*/\1/p' | head -n 1)

        if [ -z "$DOWNLOAD_URL" ]; then
            msg RED "Error: Could not fetch Performance Saver plugin release"
            rm -rf "$TEMP_PSAVER_DIR"
            return 1
        fi

        # Extract filename from URL
        PLUGIN_FILENAME=$(basename "$DOWNLOAD_URL")

        if ! wget -O "$TEMP_PSAVER_DIR/$PLUGIN_FILENAME" "$DOWNLOAD_URL" --ca-certificate=/etc/ssl/certs/ca-certificates.crt 2>>"$ERROR_LOG"; then
            msg RED "Error: Failed to download Performance Saver plugin"
            rm -rf "$TEMP_PSAVER_DIR"
            return 1
        fi

        # Verify file integrity - ensure it's a valid JAR file
        if ! file "$TEMP_PSAVER_DIR/$PLUGIN_FILENAME" | grep -q "Java archive"; then
            msg RED "Error: Downloaded file is not a valid JAR archive"
            rm -rf "$TEMP_PSAVER_DIR"
            return 1
        fi

        # Copy to mods directory
        if ! cp "$TEMP_PSAVER_DIR/$PLUGIN_FILENAME" "$PSAVER_PLUGINS_DIR/"; then
            msg RED "Error: Failed to install Performance Saver plugin (copy failed)"
            rm -rf "$TEMP_PSAVER_DIR"
            return 1
        fi
        rm -rf "$TEMP_PSAVER_DIR"
        msg GREEN "  ✓ Performance Saver plugin installed ($PLUGIN_FILENAME)"
        return 0

    else
        # PSAVER=0: Disable the plugin if it exists
        EXISTING_JAR=$(find "$PSAVER_PLUGINS_DIR" -maxdepth 1 -type f -name "${PSAVER_JAR_NAME}*.jar" ! -name "*.disabled" 2>/dev/null | head -n 1)

        if [ -n "$EXISTING_JAR" ]; then
            msg BLUE "[plugin] Disabling Performance Saver..."
            JAR_NAME=$(basename "$EXISTING_JAR")
            mv "$EXISTING_JAR" "${EXISTING_JAR}.disabled"
            msg GREEN "  ✓ Performance Saver disabled ($JAR_NAME → $JAR_NAME.disabled)"
        fi
    fi
}

# --- Hytale API authentication helpers (Device Code Flow + session creation) ---
line "BLUE"

json_field_string() {
    local key="$1"
    sed -n 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*"\([^"\r\n]*\)".*/\1/p' | head -n1
}

json_field_number() {
    local key="$1"
    sed -n 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p' | head -n1
}

json_first_uuid() {
    sed -n 's/.*"uuid"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]\+\)".*/\1/p' | head -n1
}

iso_to_epoch() {
    local iso="$1"
    if [ -z "$iso" ]; then
        echo 0
        return
    fi
    # Requires GNU/busybox date with -d
    date -d "$iso" +%s 2>/dev/null || echo 0
}

format_expiry() {
    local ts="$1"
    if [ -z "$ts" ] || [ "$ts" -le 0 ] 2>/dev/null; then
        echo "unknown"
        return
    fi
    local now diff h m s
    now=$(date +%s)
    diff=$((ts - now))
    if [ "$diff" -lt 0 ]; then
        diff=0
    fi
    h=$((diff / 3600))
    m=$(((diff % 3600) / 60))
    s=$((diff % 60))
    local abs
    abs=$(date -u -d @"$ts" +"%Y-%m-%d %H:%M:%SZ" 2>/dev/null || echo "$ts")
    printf "%dh %dm %ds (until %s)" "$h" "$m" "$s" "$abs"
}

load_auth_state() {
    if [ ! -f "$HYTALE_AUTH_STATE_PATH" ]; then
        return 0
    fi
    # shellcheck source=/dev/null
    . "$HYTALE_AUTH_STATE_PATH"
}

write_auth_state() {
    cat > "$HYTALE_AUTH_STATE_PATH" <<EOF
HYTALE_REFRESH_TOKEN="${HYTALE_REFRESH_TOKEN:-}"
HYTALE_ACCESS_TOKEN="${HYTALE_ACCESS_TOKEN:-}"
HYTALE_ACCESS_EXPIRES=${HYTALE_ACCESS_EXPIRES:-0}
HYTALE_PROFILE_UUID="${HYTALE_PROFILE_UUID:-}"
HYTALE_SESSION_TOKEN="${HYTALE_SESSION_TOKEN:-}"
HYTALE_IDENTITY_TOKEN="${HYTALE_IDENTITY_TOKEN:-}"
HYTALE_SESSION_EXPIRES=${HYTALE_SESSION_EXPIRES:-0}
EOF
}

request_device_code() {
    local resp
    resp=$(curl -s -X POST "$HYTALE_DEVICE_AUTH_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=$HYTALE_OAUTH_CLIENT_ID" \
        -d "scope=$HYTALE_OAUTH_SCOPE")

    DEVICE_CODE=$(printf '%s' "$resp" | json_field_string "device_code")
    USER_CODE=$(printf '%s' "$resp" | json_field_string "user_code")
    VERIFY_URL=$(printf '%s' "$resp" | json_field_string "verification_uri_complete")
    POLL_INTERVAL=$(printf '%s' "$resp" | json_field_number "interval")
    if [ -z "$POLL_INTERVAL" ]; then
        POLL_INTERVAL=$HYTALE_DEVICE_POLL_INTERVAL
    fi

    if [ -z "$DEVICE_CODE" ] || [ -z "$USER_CODE" ] || [ -z "$VERIFY_URL" ]; then
        msg RED "[auth] Failed to request device code"
        return 1
    fi

    msg BLUE "[auth] Device authorization required"
    msg CYAN "  Visit: $VERIFY_URL"
    msg CYAN "  Code : $USER_CODE"
    return 0
}

poll_for_tokens() {
    local poll_resp
    while true; do
        poll_resp=$(curl -s -X POST "$HYTALE_TOKEN_URL" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "client_id=$HYTALE_OAUTH_CLIENT_ID" \
            -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
            -d "device_code=$DEVICE_CODE")

        local error
        error=$(printf '%s' "$poll_resp" | json_field_string "error")
        if [ -n "$error" ]; then
            if [ "$error" = "authorization_pending" ]; then
                sleep "$POLL_INTERVAL"
                continue
            fi
            if [ "$error" = "slow_down" ]; then
                sleep $((POLL_INTERVAL + 5))
                continue
            fi
            msg RED "[auth] Token polling failed: $error"
            return 1
        fi

        HYTALE_ACCESS_TOKEN=$(printf '%s' "$poll_resp" | json_field_string "access_token")
        HYTALE_REFRESH_TOKEN=$(printf '%s' "$poll_resp" | json_field_string "refresh_token")
        local expires_in
        expires_in=$(printf '%s' "$poll_resp" | json_field_number "expires_in")
        local now
        now=$(date +%s)
        HYTALE_ACCESS_EXPIRES=$((now + expires_in))
        return 0
    done
}

refresh_access_token() {
    local resp
    resp=$(curl -s -X POST "$HYTALE_TOKEN_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=$HYTALE_OAUTH_CLIENT_ID" \
        -d "grant_type=refresh_token" \
        -d "refresh_token=$HYTALE_REFRESH_TOKEN")

    local new_access
    new_access=$(printf '%s' "$resp" | json_field_string "access_token")
    if [ -z "$new_access" ]; then
        msg RED "[auth] Failed to refresh OAuth token"
        return 1
    fi

    HYTALE_ACCESS_TOKEN="$new_access"
    HYTALE_REFRESH_TOKEN=$(printf '%s' "$resp" | json_field_string "refresh_token")
    local expires_in now
    expires_in=$(printf '%s' "$resp" | json_field_number "expires_in")
    now=$(date +%s)
    HYTALE_ACCESS_EXPIRES=$((now + expires_in))
    msg GREEN "[auth] OAuth token refreshed"
    return 0
}

fetch_profile_uuid() {
    local profiles_resp
    profiles_resp=$(curl -s -X GET "$HYTALE_PROFILES_URL" \
        -H "Authorization: Bearer $HYTALE_ACCESS_TOKEN")

    if [ -z "$profiles_resp" ]; then
        msg RED "[auth] Failed to fetch profiles"
        return 1
    fi

    if [ -n "$HYTALE_PROFILE_UUID" ]; then
        return 0
    fi

    HYTALE_PROFILE_UUID=$(printf '%s' "$profiles_resp" | json_first_uuid)

    if [ -z "$HYTALE_PROFILE_UUID" ]; then
        msg RED "[auth] No profile UUID found"
        return 1
    fi
    return 0
}

create_game_session() {
    local session_resp
    session_resp=$(curl -s -X POST "$HYTALE_SESSION_URL" \
        -H "Authorization: Bearer $HYTALE_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"uuid":"'"$HYTALE_PROFILE_UUID"'"}')

    HYTALE_SESSION_TOKEN=$(printf '%s' "$session_resp" | json_field_string "sessionToken")
    HYTALE_IDENTITY_TOKEN=$(printf '%s' "$session_resp" | json_field_string "identityToken")
    local expires_at
    expires_at=$(printf '%s' "$session_resp" | json_field_string "expiresAt")
    HYTALE_SESSION_EXPIRES=$(iso_to_epoch "$expires_at")

    if [ -z "$HYTALE_SESSION_TOKEN" ] || [ -z "$HYTALE_IDENTITY_TOKEN" ]; then
        msg RED "[auth] Failed to create game session"
        return 1
    fi

    msg GREEN "[auth] Game session created (expires at $expires_at)"
    return 0

}


refresh_game_session() {
    if [ -z "$HYTALE_SESSION_TOKEN" ]; then
        return 1
    fi

    local resp
    resp=$(curl -s -X POST "$HYTALE_SESSION_REFRESH_URL" \
        -H "Authorization: Bearer $HYTALE_SESSION_TOKEN")

    local new_session
    new_session=$(printf '%s' "$resp" | json_field_string "sessionToken")
    if [ -n "$new_session" ]; then
        HYTALE_SESSION_TOKEN="$new_session"
    fi
    local new_identity
    new_identity=$(printf '%s' "$resp" | json_field_string "identityToken")
    if [ -n "$new_identity" ]; then
        HYTALE_IDENTITY_TOKEN="$new_identity"
    fi
    local expires_at
    expires_at=$(printf '%s' "$resp" | json_field_string "expiresAt")
    HYTALE_SESSION_EXPIRES=$(iso_to_epoch "$expires_at")

    if [ -z "$HYTALE_SESSION_TOKEN" ] || [ -z "$HYTALE_IDENTITY_TOKEN" ]; then
        msg RED "[auth] Failed to refresh game session"
        return 1
    fi

    msg GREEN "[auth] Game session refreshed (expires at $expires_at)"
    return 0
}

ensure_oauth_tokens() {
    local now
    now=$(date +%s)

    if [ -n "$HYTALE_ACCESS_TOKEN" ] && [ -n "$HYTALE_ACCESS_EXPIRES" ] && [ $((HYTALE_ACCESS_EXPIRES - HYTALE_TOKEN_EXPIRY_BUFFER)) -gt "$now" ]; then
        return 0
    fi

    if [ -n "$HYTALE_REFRESH_TOKEN" ]; then
        if refresh_access_token; then
            return 0
        fi
        msg YELLOW "[auth] Refresh token invalid, starting new device flow"
    fi

    if ! request_device_code; then
        return 1
    fi
    if ! poll_for_tokens; then
        return 1
    fi
    return 0
}

ensure_session_tokens() {
    local now
    now=$(date +%s)

    if [ -n "$HYTALE_SESSION_TOKEN" ] && [ -n "$HYTALE_SESSION_EXPIRES" ] && [ $((HYTALE_SESSION_EXPIRES - HYTALE_TOKEN_EXPIRY_BUFFER)) -gt "$now" ]; then
        return 0
    fi

    if [ -n "$HYTALE_SESSION_TOKEN" ] && [ $((HYTALE_SESSION_EXPIRES - HYTALE_TOKEN_EXPIRY_BUFFER)) -le "$now" ]; then
        if refresh_game_session; then
            return 0
        fi
        msg YELLOW "[auth] Session refresh failed, creating new session"
    fi

    if ! fetch_profile_uuid; then
        return 1
    fi

    if ! create_game_session; then
        return 1
    fi

    return 0
}

run_hytale_api_auth() {
    if [ "$HYTALE_API_AUTH" != "1" ]; then
        return 0
    fi

    msg BLUE "[auth] Hytale API authentication enabled"

    load_auth_state

    if ! ensure_oauth_tokens; then
        msg RED "[auth] OAuth acquisition failed"
        return 1
    fi

    if ! ensure_session_tokens; then
        msg RED "[auth] Session acquisition failed"
        return 1
    fi

    export HYTALE_REFRESH_TOKEN
    export HYTALE_ACCESS_TOKEN
    export HYTALE_ACCESS_EXPIRES
    export HYTALE_SESSION_TOKEN
    export HYTALE_IDENTITY_TOKEN
    export HYTALE_SESSION_EXPIRES
    export HYTALE_PROFILE_UUID

    # Also set server-expected env names
    export HYTALE_SERVER_SESSION_TOKEN="$HYTALE_SESSION_TOKEN"
    export HYTALE_SERVER_IDENTITY_TOKEN="$HYTALE_IDENTITY_TOKEN"

    write_auth_state

    msg GREEN "[auth] Tokens ready and exported"
    msg CYAN "  Access token valid: $(format_expiry "$HYTALE_ACCESS_EXPIRES")"
    msg CYAN "  Session token valid: $(format_expiry "$HYTALE_SESSION_EXPIRES")"
    msg BLUE "Server Ready for Startup"
    line "CYAN"
    return 0
}
# Manage Performance Saver plugin
if [ "$PSAVER" = "1" ] || [ -n "$(find "$PSAVER_PLUGINS_DIR" -maxdepth 1 -name "${PSAVER_JAR_NAME}*.jar*" -type f 2>/dev/null | head -1)" ]; then
    manage_psaver || true
fi

# Acquire Hytale API tokens (device flow) and export to env if enabled
if ! run_hytale_api_auth; then
    msg YELLOW "[auth] Continuing without API-acquired tokens"
fi

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the output, and then execute it with eval
printf "\033[1m\033[33mcontainer~ \033[0m"
echo "$PARSED"
# shellcheck disable=SC2086
exec env ${PARSED}
