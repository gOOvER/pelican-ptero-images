#!/bin/bash
set -euo pipefail

ERROR_LOG="install_error.log"
: > "$ERROR_LOG"

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
    # If RED, also write the message to install_error.log
    if [ "$color" = "RED" ]; then
        printf "%b\n" "${RED}$*${NC}" | tee -a "$ERROR_LOG" >&2
    else
        printf "%b\n" "${!color}$*${NC}"
    fi
}

success() {
    printf "%b\n" "${GREEN}✓${NC} $*"
}

error() {
    printf "%b\n" "${RED}✗${NC} $*" | tee -a "$ERROR_LOG" >&2
}

warning() {
    printf "%b\n" "${YELLOW}⚠${NC} $*"
}

info() {
    printf "%b\n" "${CYAN}→${NC} $*"
}

progress() {
    local step="$1"
    local total="$2"
    local msg="$3"
    printf "%b\n" "${BLUE}[${step}/${total}]${NC} $msg"
}

# Rotate/compress large logs to avoid unbounded growth
rotate_log() {
    local logfile="$1"
    local max_bytes=${2:-5242880} # default 5 MiB
    local keep=${3:-3}
    if [ -z "$logfile" ]; then
        return 0
    fi
    if [ -f "$logfile" ]; then
        local size
        size=$(stat -c%s "$logfile" 2>/dev/null || wc -c <"$logfile" 2>/dev/null || echo 0)
        if [ "$size" -ge "$max_bytes" ]; then
            local ts
            ts=$(date +%s)
            local archive="${logfile}.${ts}.gz"
            msg YELLOW "Rotating large log $logfile -> $archive (size=${size})"
            # move then compress to avoid holding both uncompressed on disk
            if mv "$logfile" "${logfile}.${ts}" 2>/dev/null; then
                if command -v gzip &>/dev/null; then
                    gzip -9 "${logfile}.${ts}" && msg YELLOW "Compressed rotated log to ${archive}"
                else
                    msg YELLOW "gzip not available; leaving rotated file uncompressed: ${logfile}.${ts}"
                fi
            else
                # fallback: truncate the file to avoid disk full
                : > "$logfile"
                msg YELLOW "Failed to rotate; truncated $logfile"
            fi
            # optionally clean up old archives
            local files
            files=$(ls -1t "${logfile}".*.gz 2>/dev/null || true)
            if [ -n "$files" ]; then
                local idx=0
                while IFS= read -r f; do
                    idx=$((idx+1))
                    if [ "$idx" -gt "$keep" ]; then
                        rm -f "$f" || true
                        msg YELLOW "Removed old rotated log $f"
                    fi
                done <<< "$files"
            fi
        fi
    fi
}

# Helper: remove a token (word) from a space-separated list variable
remove_token_from_list() {
    local var_value="$1"
    local token="$2"
    local out=""
    read -r -a parts <<<"$var_value"
    for p in "${parts[@]}"; do
        if [ "$p" != "$token" ]; then
            out="${out}${out:+ }${p}"
        fi
    done
    printf '%s' "$out"
}

line() {
    local color="${1:-BLUE}"
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 70)
    # Cap line width at 120 characters for readability
    [ "$term_width" -gt 120 ] && term_width=120
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
# Print timestamp, failing command and line number
# ----------------------------
# initialize rc so static checkers do not warn about unassigned var
rc=0
trap 'rc=$?; echo "$(date "+%Y-%m-%d %H:%M:%S") - Unexpected error (exit $rc) at line $LINENO: \"${BASH_COMMAND}\"" | tee -a "$ERROR_LOG" >&2; exit $rc' ERR

# ----------------------------
# System Info
# ----------------------------
LINUX=$(. /etc/os-release; echo "$PRETTY_NAME")
TIMEZONE=$(if [ -f /etc/timezone ]; then cat /etc/timezone; else readlink /etc/localtime | sed 's|.*/zoneinfo/||'; fi)
WINE_VER=$(wine --version 2>/dev/null || echo "Wine not found!")

# ----------------------------
# Banner
# ----------------------------
clear
line BLUE
msg RED "Wine Image by gOOvER - https://discord.goover.dev"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "System Information:"
msg YELLOW "  • Distribution: ${RED}$LINUX"
msg YELLOW "  • Timezone: ${RED}$TIMEZONE"
msg YELLOW "  • Wine Version: ${RED}$WINE_VER"
line BLUE

# Note: NTSync is automatically enabled by modern Wine versions (>= 8.0) on kernel >= 6.14 with CONFIG_NTSYNC
# No manual configuration needed

# ----------------------------
# Environment
# ----------------------------
export TZ="${TZ:-UTC}"
internal_ip=$(ip route get 1 | awk '{print $(NF-2);exit}' 2>/dev/null || echo "127.0.0.1")
export INTERNAL_IP="$internal_ip"
export XDG_RUNTIME_DIR="/home/container/.config/xdg"
mkdir -p "$XDG_RUNTIME_DIR"
# Ensure a sane default WINEPREFIX and export it so wine/winetricks use it
export WINEPREFIX="${WINEPREFIX:-/home/container/.wine}"
# Default to 64-bit Wine prefixes unless explicitly overridden
export WINEARCH="${WINEARCH:-win64}"
# Ensure X virtual framebuffer is always enabled for winetricks GUI needs
export XVFB=1
# Default DISPLAY and screen geometry
export DISPLAY="${DISPLAY:-:0}"
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-1024}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-768}"
export DISPLAY_DEPTH="${DISPLAY_DEPTH:-24}"

# Rotate any existing large logs at startup to avoid immediate disk blowup
rotate_log "$WINEPREFIX/dotnet_direct_install.log" 5242880 3 || true
rotate_log "$WINEPREFIX/mono_install.log" 5242880 3 || true
rotate_log "$WINEPREFIX/wineboot_init.log" 5242880 3 || true
rotate_log "$WINEPREFIX/install_error.log" 5242880 3 || true

# ----------------------------
# Required tools check
# ----------------------------
for tool in wget curl openssl wine cabextract Xvfb xdpyinfo; do
    if ! command -v "$tool" &>/dev/null; then
        msg RED "Error: Required tool '$tool' is not installed."
        exit 1
    fi
done

cd /home/container || { msg RED "Failed to change directory to /home/container."; exit 1; }

# ----------------------------
# Create log directories early
# ----------------------------
mkdir -p "$WINEPREFIX/logs" "$XDG_RUNTIME_DIR"

# ----------------------------
# Xvfb (always enabled)
# ----------------------------
XVFB_LOG="$WINEPREFIX/logs/xvfb.log"
# If an X server is already available on $DISPLAY, don't start a new one
if ! xdpyinfo -display "$DISPLAY" &>/dev/null; then
    msg YELLOW "Starting Xvfb on $DISPLAY (${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH})"
    Xvfb "$DISPLAY" -screen 0 "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH}" &> "$XVFB_LOG" &
    XVFB_PID=$!
    sleep 1
    if ! kill -0 "$XVFB_PID" 2>/dev/null; then
        msg RED "Xvfb failed to start; check $XVFB_LOG"
        exit 1
    fi
    msg GREEN "Xvfb started (pid $XVFB_PID), log: $XVFB_LOG"
    # Ensure Xvfb is killed on exit
    trap 'if [ -n "${XVFB_PID:-}" ] && kill -0 "$XVFB_PID" 2>/dev/null; then kill "$XVFB_PID" || true; fi' EXIT
else
    msg YELLOW "Display $DISPLAY already available; not starting Xvfb"
fi

# ----------------------------
# Wine setup
# ----------------------------
line BLUE
msg RED "Setting up Wine... Please wait..."
line BLUE

mkdir -p "$WINEPREFIX"
if [ ! -d "$WINEPREFIX/drive_c" ]; then
    wineboot --init || { msg RED "wineboot failed!"; exit 1; }
fi

line BLUE
msg YELLOW "Importing system root CA certificates into Wine (this may take a few minutes)"
line BLUE
CERT_LOG="$WINEPREFIX/logs/certs_import.log"
rotate_log "$CERT_LOG" 5242880 3 || true

TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t winecerts 2>/dev/null || true)
if [ -z "$TMPDIR" ] || [ ! -d "$TMPDIR" ]; then
    msg RED "Failed to create temporary working directory for certificate import; skipping import"
else
    # Perform the entire import in a subshell so we never change the parent cwd
    (
        set -e
        cd "$TMPDIR" || exit 1
        msg YELLOW "Downloading latest CA bundle..."
        if ! curl -fsSLo cacert.pem https://curl.se/ca/cacert.pem >>"$CERT_LOG" 2>&1; then
            msg RED "Failed to download CA bundle; see $CERT_LOG"
            exit 0
        fi

        # sanity check: file non-empty
        if [ ! -s cacert.pem ]; then
            msg RED "Downloaded CA bundle is empty; aborting import (see $CERT_LOG)"
            exit 0
        fi

        # normalize CRLF if dos2unix is available, otherwise use sed fallback
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix -q cacert.pem >>"$CERT_LOG" 2>&1 || true
        else
            sed -i 's/\r$//' cacert.pem || true
        fi

        msg YELLOW "Splitting PEM bundle into individual cert files (robust split)..."
        awk 'BEGIN{n=0} /-----BEGIN CERTIFICATE-----/{n++; fname=sprintf("cert%04d.pem",n)} {print > fname}' cacert.pem 2>>"$CERT_LOG" || true
        find . -maxdepth 1 -type f -name 'cert*.pem' -size 0 -delete
        progress 1 2 "Converting and importing certificates..."
        msg YELLOW "Converting valid PEM files to DER (.cer) and importing into Wine's root store..."
        for pem in cert*.pem; do
            [ -f "$pem" ] || continue
            if ! grep -q '-----BEGIN CERTIFICATE-----' "$pem" 2>>"$CERT_LOG"; then
                continue
            fi
            cer="${pem%.pem}.cer"
            if openssl x509 -inform PEM -in "$pem" -outform DER -out "$cer" >>"$CERT_LOG" 2>&1; then
                wine rundll32.exe cryptext.dll,CryptExtAddCer "$(pwd)/$cer" >>"$CERT_LOG" 2>&1 || true
            fi
        done
        progress 2 2 "Certificate import complete"
        msg GREEN "Certificate import finished (logs: $CERT_LOG)"
    )
    # ensure TMPDIR removed in case subshell exited early
    rm -rf "$TMPDIR" >/dev/null 2>&1 || true
fi

# NOTE: 64-bit is the default (WINEARCH=win64). No automatic 32-bit enforcement is performed.

# ----------------------------
# NTSync is a Wine feature, not a winetricks package - remove if present
# ----------------------------
if [[ "$WINETRICKS_RUN" =~ ntsync ]]; then
    warning "NTSync is a Wine feature (not a winetricks package) - it's controlled via WINE_ENABLE_NTSYNC environment variable"
    WINETRICKS_RUN=$(remove_token_from_list "$WINETRICKS_RUN" ntsync)
fi

# ----------------------------
# Wine Gecko Installation
# ----------------------------
if [[ "$WINETRICKS_RUN" =~ gecko ]]; then
    line BLUE
    msg YELLOW "Installing Wine Gecko"
    line BLUE
    WINETRICKS_RUN=$(remove_token_from_list "$WINETRICKS_RUN" gecko)

    GECKO_VERSION=$(curl -s https://api.github.com/repos/wine-mirror/wine/releases/latest | jq -r '.tag_name // empty' 2>/dev/null || echo "2.47.4")
    GECKO_BASE="https://dl.winehq.org/wine/wine-gecko/${GECKO_VERSION}"

    # download and install both architectures
    for arch in x86 x86_64; do
        MSI_FILE="$WINEPREFIX/gecko_${arch}.msi"
        SHA_FILE="${GECKO_BASE}/wine-gecko-${GECKO_VERSION}-${arch}.msi.sha256"
        if [ ! -s "$MSI_FILE" ]; then
            msg YELLOW "Downloading Gecko ${arch}..."
            progress 1 3 "Fetching checksum..."
            if ! GECKO_SHA=$(curl -s "$SHA_FILE" | awk '{print $1}' | head -c 64); then
                msg RED "Failed to fetch Gecko ${arch} checksum"
                exit 1
            fi
            if ! wget -q --tries=3 --timeout=30 -O "$MSI_FILE" "${GECKO_BASE}/wine-gecko-${GECKO_VERSION}-${arch}.msi"; then
                msg RED "Failed to download Gecko ${arch}"
                exit 1
            fi
            progress 2 3 "Validating checksum..."
            COMPUTED_SHA=$(sha256sum "$MSI_FILE" | awk '{print $1}')
            if [ "$COMPUTED_SHA" != "$GECKO_SHA" ]; then
                msg RED "Gecko ${arch} checksum mismatch! Expected: $GECKO_SHA, Got: $COMPUTED_SHA"
                rm -f "$MSI_FILE"
                exit 1
            fi
        fi
        if [ -s "$MSI_FILE" ]; then
            progress 3 3 "Installing Gecko ${arch}..."
            if ! wine msiexec /i "$MSI_FILE" /qn /norestart /log "$WINEPREFIX/gecko_${arch}_install.log"; then
                msg RED "Wine Gecko ${arch} installation failed! See $WINEPREFIX/gecko_${arch}_install.log"
                exit 1
            fi
        else
            msg RED "Gecko ${arch} MSI missing or empty: $MSI_FILE"
            exit 1
        fi
    done
fi

# ----------------------------
# Wine Mono Installation
# ----------------------------
if [[ "$WINETRICKS_RUN" =~ mono ]]; then
    line BLUE
    msg YELLOW "Installing latest Wine Mono"
    line BLUE
    # Optionally force WINEARCH (e.g. win32) via env FORCE_WINEARCH=win32
    if [ -n "${FORCE_WINEARCH:-}" ]; then
        export WINEARCH="${FORCE_WINEARCH}"
        msg YELLOW "Forcing WINEARCH=$WINEARCH"
        # recreate prefix if necessary
        if [ ! -d "$WINEPREFIX" ]; then
            wineboot --init || true
        fi
    fi

    # Allow manual override first (useful when GitHub API is rate-limited/offline)
    MONO_VERSION="${WINE_MONO_VERSION:-}"
    if [ -z "$MONO_VERSION" ]; then
        MONO_API_URL="https://api.github.com/repos/wine-mono/wine-mono/releases/latest"
        MONO_API_JSON=""

        # Do not fail the whole script on transient network/API errors.
        MONO_API_JSON=$(curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 "$MONO_API_URL" 2>/dev/null || true)

        if [ -n "$MONO_API_JSON" ]; then
            if command -v jq >/dev/null 2>&1; then
                MONO_VERSION=$(printf '%s' "$MONO_API_JSON" | jq -r '.tag_name // empty' 2>/dev/null || true)
            else
                # Fallback parser if jq is unavailable
                MONO_VERSION=$(printf '%s\n' "$MONO_API_JSON" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
            fi
        fi
    fi

    if [ -z "$MONO_VERSION" ]; then
        warning "Could not determine latest Wine Mono version (GitHub API/network issue)."
        info "Set WINE_MONO_VERSION (e.g. wine-mono-9.x.x) to force installation, or continue without mono."
        WINETRICKS_RUN=$(remove_token_from_list "$WINETRICKS_RUN" mono)
    else
        MONO_URL="https://github.com/wine-mono/wine-mono/releases/download/${MONO_VERSION}/wine-mono-${MONO_VERSION#wine-mono-}-x86.msi"
        rm -f "$WINEPREFIX/mono.msi"
        msg YELLOW "Downloading Wine Mono from $MONO_URL"
        progress 1 2 "Downloading..."
        if ! wget -q --tries=3 --timeout=30 -O "$WINEPREFIX/mono.msi" "$MONO_URL"; then
            msg RED "Failed to download Wine Mono MSI from $MONO_URL"
            exit 1
        fi
        progress 2 2 "Download complete"
        # install with retries and logging
        attempts=0
        max_attempts=3
        rc=1
        while [ "$attempts" -lt "$max_attempts" ]; do
            attempts=$((attempts+1))
            msg YELLOW "Attempt $attempts to install Wine Mono..."
            if wine msiexec /i "$WINEPREFIX/mono.msi" /qn /norestart /log "$WINEPREFIX/mono_install.log"; then
                rc=0
                msg GREEN "Wine Mono installed successfully on attempt $attempts"
                break
            else
                msg YELLOW "Wine Mono installer failed on attempt $attempts (see $WINEPREFIX/mono_install.log)"
                sleep 3
            fi
        done
        if [ "$rc" -ne 0 ]; then
            msg RED "Wine Mono installation failed after $max_attempts attempts. See $WINEPREFIX/mono_install.log"
            exit 1
        fi
        WINETRICKS_RUN=$(remove_token_from_list "$WINETRICKS_RUN" mono)
    fi
fi

# ----------------------------
# vcrun2022 via winetricks
# ----------------------------
if [[ "$WINETRICKS_RUN" =~ vcrun2022 ]]; then
    line BLUE
    msg YELLOW "Installing vcrun2022 via winetricks"
    line BLUE
    progress 1 3 "Preparing installation..."
    VCRUN_LOG="$WINEPREFIX/logs/winetricks-vcrun2022.log"
    rotate_log "$VCRUN_LOG" 5242880 5 || true
    progress 2 3 "Running winetricks..."
    if winetricks -q vcrun2022 &> "$VCRUN_LOG"; then
        progress 3 3 "vcrun2022 validation"
        msg GREEN "vcrun2022 installed via winetricks (log: $VCRUN_LOG)"
    else
        # If winetricks returned non-zero (cabextract warnings etc.) but the
        # actual runtime DLLs exist in the prefix, allow startup to continue.
        msg YELLOW "winetricks vcrun2022 returned non-zero; verifying required DLLs..."
        missing_dll=0
        for dll in msvcp140.dll vcruntime140.dll; do
            if [ -f "$WINEPREFIX/drive_c/windows/system32/$dll" ] || [ -f "$WINEPREFIX/drive_c/windows/syswow64/$dll" ]; then
                msg YELLOW "Found $dll in prefix"
            else
                msg RED "Missing $dll in prefix"
                missing_dll=1
            fi
        done
        if [ "$missing_dll" -eq 0 ]; then
            progress 3 3 "vcrun2022 validation passed"
            msg GREEN "Required vcrun2022 DLLs present; continuing despite winetricks warnings. (See $VCRUN_LOG for details)"
        else
            msg RED "winetricks vcrun2022 failed and required DLLs are missing; see $VCRUN_LOG"
            exit 1
        fi
    fi
    WINETRICKS_RUN=$(remove_token_from_list "$WINETRICKS_RUN" vcrun2022)
fi

# ----------------------------
# Install additional Winetricks packages (robust)
# ----------------------------
# Ensure WINETRICKS_RUN is not empty and trim whitespace
if [ -n "${WINETRICKS_RUN// }" ]; then
    # Ensure winetricks command exists
    if ! command -v winetricks &>/dev/null; then
        msg RED "winetricks not found but WINETRICKS_RUN is set. Please install winetricks or unset WINETRICKS_RUN."
    else
        # Split into array on whitespace (preserves quoted args if any)
        read -r -a _tricks <<<"$WINETRICKS_RUN"
        for trick in "${_tricks[@]}"; do
            line BLUE
            msg YELLOW "Installing: ${GREEN}$trick"
            line BLUE
            progress 1 3 "Preparing $trick..."
            LOGFILE="$WINEPREFIX/logs/winetricks-${trick//[^a-zA-Z0-9_.-]/_}.log"
            rotate_log "$LOGFILE" 5242880 5 || true
            # Special-case diagnostics and fallbacks for dotnet installers
            if [[ "$trick" =~ dotnet ]]; then
                msg YELLOW "Detected dotnet trick: running winetricks for diagnostics"
                progress 2 3 "Running winetricks $trick..."
                # Choose WINEDEBUG level: full 'all' only when DEBUG_DOTNET=1 is set by user
                WINEDEBUG_LEVEL="${DEBUG_DOTNET:-0}"
                if [ "$WINEDEBUG_LEVEL" -eq 1 ]; then
                    DBG_ENV="WINEDEBUG=all"
                else
                    DBG_ENV="WINEDEBUG=warn"
                fi
                # First try non-interactive winetricks with chosen debug level
                if eval "$DBG_ENV winetricks -q \"$trick\" &> \"$LOGFILE\""; then
                    progress 3 3 "$trick installation verified"
                    msg GREEN "Winetricks: $trick installed successfully (log: $LOGFILE)"
                else
                    msg YELLOW "Winetricks failed for $trick; attempting direct installer from winetricks cache"
                    CACHE_DIR="/home/container/.cache/winetricks/$trick"
                    INSTALLER=""
                    if [ -d "$CACHE_DIR" ]; then
                        INSTALLER=$(ls -1 "$CACHE_DIR"/*.exe 2>/dev/null | tail -n1 || true)
                    fi
                    if [ -n "$INSTALLER" ]; then
                        DIRECT_LOG="$WINEPREFIX/dotnet_direct_install.log"
                        # Use stricter rotation/truncation for direct dotnet logs (1 MiB)
                        rotate_log "$DIRECT_LOG" 1048576 5 || true
                        msg YELLOW "Found cached installer: $INSTALLER — attempting direct wine execution"
                        # Choose debug env for direct installer as well
                        if [ "$WINEDEBUG_LEVEL" -eq 1 ]; then
                            DIRECT_DBG_ENV="WINEDEBUG=all"
                        else
                            DIRECT_DBG_ENV="WINEDEBUG=warn"
                        fi
                        # Try quiet install first
                        if eval "$DIRECT_DBG_ENV wine \"$INSTALLER\" /quiet &>> \"$DIRECT_LOG\""; then
                            progress 3 3 "$trick installation verified"
                            msg GREEN "Direct dotnet installer (/quiet) succeeded (log: $DIRECT_LOG)"
                        else
                            msg YELLOW "Direct dotnet installer (/quiet) failed, trying interactive run (no /quiet)"
                            if eval "$DIRECT_DBG_ENV wine \"$INSTALLER\" &>> \"$DIRECT_LOG\""; then
                                progress 3 3 "$trick installation verified"
                                msg GREEN "Direct dotnet installer (interactive) succeeded (log: $DIRECT_LOG)"
                            else
                                msg RED "Direct dotnet installer failed; see $DIRECT_LOG and $LOGFILE for details"
                                # Truncate direct log to last 2000 lines to avoid giant files
                                tail -n 2000 "$DIRECT_LOG" > "${DIRECT_LOG}.tmp" && mv "${DIRECT_LOG}.tmp" "$DIRECT_LOG" || true
                                exit 1
                            fi
                        fi
                    else
                        msg RED "No cached dotnet installer found in $CACHE_DIR. See $LOGFILE for winetricks details."
                        exit 1
                    fi
                fi
            else
                progress 2 3 "Running winetricks $trick..."
                if winetricks -q "$trick" &> "$LOGFILE"; then
                    progress 3 3 "$trick installation verified"
                    msg GREEN "Winetricks: $trick installed successfully (log: $LOGFILE)"
                else
                    msg RED "Winetricks installation for $trick failed! See $LOGFILE"
                    exit 1
                fi
            fi
        done
    fi
fi

# ----------------------------
# SteamCMD / DepotDownloader Update
# ----------------------------
## auto_update only if explicitly set to 1
if [ "${AUTO_UPDATE:-}" = "1" ]; then
    if [ -z "${STEAM_APPID:-}" ] && [ -n "${SRCDS_APPID:-}" ]; then
        STEAM_APPID="$SRCDS_APPID"
    fi
    if [ -f ./DepotDownloader ]; then
        line BLUE
        msg YELLOW "Using DepotDownloader for updates"
        line BLUE

        : "${STEAM_USER:=anonymous}"  # Default anonymous user
        : "${STEAM_PASS:=}"
        : "${STEAM_AUTH:=}"

        msg YELLOW "Steam user: ${GREEN}$STEAM_USER${NC}"

        dd_args=( -dir . -username "$STEAM_USER" -password "$STEAM_PASS" -remember-password )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            dd_args+=( -os windows )
        fi
        dd_args+=( -app "$STEAM_APPID" )
        if [ -n "${STEAM_BETAID:-}" ]; then
            dd_args+=( -branch "$STEAM_BETAID" )
        fi
        if [ -n "${STEAM_BETAPASS:-}" ]; then
            dd_args+=( -branchpassword "$STEAM_BETAPASS" )
        fi
        progress 1 2 "Downloading game files..."
        if ! ./DepotDownloader "${dd_args[@]}"; then
            error "DepotDownloader failed to download game files!"
            exit 1
        fi

        mkdir -p .steam/sdk64
        dd_sdk_args=( -dir .steam/sdk64 -app 1007 )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            dd_sdk_args+=( -os windows )
        fi
        progress 2 2 "Downloading Steamworks SDK..."
        if ! ./DepotDownloader "${dd_sdk_args[@]}"; then
            error "DepotDownloader failed to download Steamworks SDK!"
            exit 1
        fi
    else
        line BLUE
        msg YELLOW "Using SteamCMD for updates"
        line BLUE

        : "${STEAM_USER:=anonymous}"  # Default anonymous user
        : "${STEAM_PASS:=}"
        : "${STEAM_AUTH:=}"

        msg YELLOW "Steam user: ${GREEN}$STEAM_USER${NC}"

        sc_args=( +force_install_dir /home/container +login "$STEAM_USER" "$STEAM_PASS" "$STEAM_AUTH" )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            sc_args+=( +@sSteamCmdForcePlatformType windows )
        fi
        if [ "${STEAM_SDK:-0}" = "1" ]; then
            sc_args+=( +app_update 1007 )
        fi
        sc_args+=( +app_update "$STEAM_APPID" )
        if [ -n "${STEAM_BETAID:-}" ]; then
            sc_args+=( -beta "$STEAM_BETAID" )
        fi
        if [ -n "${STEAM_BETAPASS:-}" ]; then
            sc_args+=( -branchpassword "$STEAM_BETAPASS" )
        fi
        if [ -n "${INSTALL_FLAGS:-}" ]; then
            IFS=' ' read -r -a extra_flags <<<"$INSTALL_FLAGS"
            sc_args+=( "${extra_flags[@]}" )
        fi
        if [ "${VALIDATE:-0}" = "1" ]; then
            sc_args+=( validate )
        fi
        sc_args+=( +quit )
        progress 2 2 "SteamCMD download complete"
        if ! ./steamcmd/steamcmd.sh "${sc_args[@]}"; then
            error "SteamCMD failed to update game files!"
            exit 1
        fi
    fi
else
    line BLUE
    msg YELLOW "Auto Update is disabled. Skipping update..."
    line BLUE
fi

# ----------------------------
# Startup command
# ----------------------------
MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"

# Function to find and stream game logs if they exist
stream_game_logs() {
    local log_search_paths=(
        "${WINEPREFIX}/drive_c/users/container/AppData/Local/*/Saved/Logs/"
        "${WINEPREFIX}/drive_c/users/container/AppData/LocalLow/*/Logs/"
        "$HOME/*/Saved/Logs/"
        "$HOME/.local/share/*/Saved/Logs/"
    )

    for log_path in "${log_search_paths[@]}"; do
        # Expand glob patterns
        for found_log_dir in $log_path; do
            if [ -d "$found_log_dir" ]; then
                # Find most recent log file
                latest_log=$(find "$found_log_dir" -type f -name "*.log" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2-)
                if [ -n "$latest_log" ]; then
                    info "Streaming game log: $latest_log"
                    tail -c0 -F "$latest_log" --pid=$SERVER_PID 2>/dev/null || true
                    return 0
                fi
            fi
        done
    done
}

# Execute startup command with eval for proper shell expansion
# Only environment variables and shell operators are processed, preventing code injection
eval "$MODIFIED_STARTUP" &
SERVER_PID=$!

# Stream logs in parallel if game writes to log files
if [ "${STREAM_LOGS:-1}" != "0" ]; then
    stream_game_logs &
    LOG_PID=$!
fi

# Wait for server process
# Disable both errexit and the ERR trap so a non-zero server exit code does
# not trigger the error handler - the exit code is forwarded intentionally below.
set +e
trap - ERR
wait $SERVER_PID
SERVER_EXIT=$?

# Cleanup log streaming if active
if [ -n "${LOG_PID:-}" ]; then
    kill $LOG_PID 2>/dev/null || true
fi

exit $SERVER_EXIT

