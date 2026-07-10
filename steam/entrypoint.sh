#!/bin/bash
set -euo pipefail

ERROR_LOG="install_error.log"
: > "$ERROR_LOG"  # Clear old log file (no-op)

# ----------------------------
# Colors via tput
# ----------------------------
RED=$(tput setaf 1 2>/dev/null || printf '\033[0;31m')
GREEN=$(tput setaf 2 2>/dev/null || printf '\033[0;32m')
YELLOW=$(tput setaf 3 2>/dev/null || printf '\033[0;33m')
BLUE=$(tput setaf 4 2>/dev/null || printf '\033[0;34m')
CYAN=$(tput setaf 6 2>/dev/null || printf '\033[0;36m')
NC=$(tput sgr0 2>/dev/null || printf '\033[0m')

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

# Robust Proton version detection - try multiple locations
PROTON_VER="Unknown"
if [ -f /opt/ProtonGE/version ]; then
    PROTON_VER=$(cat /opt/ProtonGE/version 2>/dev/null || echo "Unknown")
fi
if [ "$PROTON_VER" = "Unknown" ] && [ -f /usr/local/share/steam/compatibilitytools.d/ProtonGE/version ]; then
    PROTON_VER=$(cat /usr/local/share/steam/compatibilitytools.d/ProtonGE/version 2>/dev/null || echo "Unknown")
fi
if [ "$PROTON_VER" = "Unknown" ] && command -v proton >/dev/null 2>&1; then
    PROTON_VER=$(proton --version 2>/dev/null | head -n1 || echo "Unknown")
fi
if [ "$PROTON_VER" = "Unknown" ]; then
    DIRNAME=$(find /opt /usr/local/share/steam/compatibilitytools.d -maxdepth 1 -type d -name 'GE-Proton*' 2>/dev/null | head -n1 || true)
    [ -n "$DIRNAME" ] && PROTON_VER="${DIRNAME##*/}"
fi

# ----------------------------
# Banner
# ----------------------------
clear
# Prevent Wine/Proton output wrapping badly
stty columns 250 || true
line BLUE
msg RED "SteamCMD Proton-GE Image by gOOvER - https://discord.goover.dev"
msg RED "THIS IMAGE IS LICENSED UNDER AGPLv3"
line BLUE
msg YELLOW "System Information:"
msg YELLOW "  • Distribution: ${RED}$LINUX"
msg YELLOW "  • Kernel: ${RED}$(uname -r)"
msg YELLOW "  • Timezone: ${RED}$TIMEZONE"
msg YELLOW "  • Proton Version: ${RED}$PROTON_VER"
if command -v proton >/dev/null 2>&1; then
    success "Proton CLI available: $(command -v proton)"
else
    warning "Proton CLI not found in PATH"
fi
line BLUE

# ----------------------------------------------------------
# Set environment for Steam Proton
# ----------------------------------------------------------
# Base log directory (don't override PROTON_LOG_DIR, use separate var)
export BASE_LOG_DIR="/home/container/logs"
mkdir -p "$BASE_LOG_DIR"

# Create separate log directories for organization
export PROTON_LOG_DIR="$BASE_LOG_DIR/proton"
export SERVER_LOG_DIR="$BASE_LOG_DIR/server"
export WINETRICKS_LOG_DIR="$BASE_LOG_DIR/winetricks"
mkdir -p "$PROTON_LOG_DIR" "$SERVER_LOG_DIR" "$WINETRICKS_LOG_DIR"

# Enable Proton logging for debugging
export PROTON_LOG=1

# Enable verbose Wine logging for crash diagnosis (can be overridden).
# err-dxgi + -dxgi suppresses both err: and warn: EDID/display-metadata noise
# on headless servers without a monitor. Set WINEDEBUG=+all to restore full output.
export WINEDEBUG="${WINEDEBUG:-warn+all,err-dxgi,-dxgi}"

# Track crashes and errors
export PROTON_CRASH_REPORT_DIR="$PROTON_LOG_DIR"

# Disable Steam client integration for dedicated servers (faster, less resources)
export PROTON_NO_STEAM=1

# ----------------------------
# Detect Unity headless / batchmode server
# ----------------------------
# Unity dedicated server builds use -batchmode -nographics and require NO display.
# Running with SDL_VIDEODRIVER=x11 or Xvfb causes Wine/SDL to block waiting for
# an X11 connection that is never needed. Auto-detect and disable display subsystems.
# Override by setting UNITY_BATCHMODE=0 or UNITY_BATCHMODE=1 explicitly.
if [ -z "${UNITY_BATCHMODE:-}" ]; then
    if echo "${STARTUP:-}" | grep -qi -- '-batchmode'; then
        UNITY_BATCHMODE=1
    else
        UNITY_BATCHMODE=0
    fi
fi

if [ "$UNITY_BATCHMODE" = "1" ]; then
    info "Unity batchmode detected (-batchmode in STARTUP) - display subsystem disabled"
fi

# ----------------------------
# Virtual display (Xvfb) for headless servers (no GPU/monitor)
# ----------------------------
# Xvfb provides a virtual framebuffer so SDL/Wine/DXVK can initialize
# without a physical display. This is required on bare-metal game servers.
# Skipped for Unity batchmode servers which need no display at all.
DISPLAY="${DISPLAY:-:99}"
export DISPLAY
DISPLAY_WIDTH="${DISPLAY_WIDTH:-1024}"
DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-768}"
DISPLAY_DEPTH="${DISPLAY_DEPTH:-24}"

if [ "${UNITY_BATCHMODE:-0}" != "1" ]; then
    # Ensure the X11 socket directory exists
    mkdir -p /tmp/.X11-unix 2>/dev/null || true
    if ! xrandr --display "$DISPLAY" &>/dev/null 2>&1; then
        DISPLAY_STARTED=0

        # Prefer Xorg with dummy driver: it registers a connected RandR output
        # so SDL3 can enumerate displays. Xvfb only creates a screen without
        # any RandR output, causing SDL3 to return 0 displays and making apps
        # like Xalia throw "No displays available" on initialisation.
        # Xwrapper.config (needs_root_rights=no) allows the non-root container
        # user to start Xorg since the dummy driver needs no hardware access.
        if command -v Xorg >/dev/null 2>&1 && [ -f /etc/X11/xorg.conf.d/20-virtual-display.conf ]; then
            info "Starting Xorg (dummy driver) on display $DISPLAY..."
            Xorg -nolisten tcp -noreset -novtswitch -ac "$DISPLAY" \
                2>"$BASE_LOG_DIR/xorg.log" &
            XVFB_PID=$!
            sleep 2
            if kill -0 "$XVFB_PID" 2>/dev/null && xrandr --display "$DISPLAY" &>/dev/null 2>&1; then
                success "Xorg dummy display started (PID: $XVFB_PID)"
                DISPLAY_STARTED=1
            else
                warning "Xorg dummy failed to start — falling back to Xvfb"
                kill "$XVFB_PID" 2>/dev/null || true
                wait "$XVFB_PID" 2>/dev/null || true
                XVFB_PID=""
            fi
        fi

        # Fall back to Xvfb (SDL2/Wine work without RandR outputs)
        if [ "$DISPLAY_STARTED" = "0" ] && command -v Xvfb >/dev/null 2>&1; then
            info "Starting Xvfb on display $DISPLAY (${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH})"
            # -ac disables access control so Wine/SDL can connect without Xauthority
            Xvfb "$DISPLAY" -screen 0 "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH}" \
                -nolisten tcp -ac \
                2>"$BASE_LOG_DIR/xvfb.log" &
            XVFB_PID=$!
            sleep 1
            if kill -0 "$XVFB_PID" 2>/dev/null; then
                success "Xvfb started (PID: $XVFB_PID)"
                DISPLAY_STARTED=1
            else
                warning "Xvfb failed to start — continuing anyway"
            fi
        fi

        [ "$DISPLAY_STARTED" = "0" ] && warning "No virtual display server available — headless SDL/Wine apps may fail"
    else
        info "Virtual display $DISPLAY already available"
    fi
elif [ "${UNITY_BATCHMODE:-0}" != "1" ]; then
    warning "Xvfb not found - headless SDL/Wine apps may fail"
fi

# Force software Vulkan (lavapipe) and software OpenGL on headless servers.
# These are no-ops when a real GPU is present; safe to set unconditionally.
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
export GALLIUM_DRIVER="${GALLIUM_DRIVER:-llvmpipe}"
# Point DXVK/Vulkan loader to the lavapipe software ICD (ships with mesa-vulkan-drivers).
# Prefer existing VK_ICD_FILENAMES if the user has set them (e.g. real GPU passthrough).
if [ -z "${VK_ICD_FILENAMES:-}" ]; then
    LVP_ICD=""
    for f in \
        /usr/share/vulkan/icd.d/lvp_icd.x86_64.json \
        /usr/share/vulkan/icd.d/lvp_icd.i686.json; do
        [ -f "$f" ] && LVP_ICD="${LVP_ICD:+${LVP_ICD}:}${f}"
    done
    [ -n "$LVP_ICD" ] && export VK_ICD_FILENAMES="$LVP_ICD" && info "Software Vulkan ICD: $VK_ICD_FILENAMES"
fi

# SDL2 video driver selection:
# - x11:   required for Xalia (xalia.exe uses SDL's X11 backend for windowing).
#          Without x11, Xalia throws PlatformNotSupportedException.
# - dummy: correct for Unity dedicated server builds and any server that does not
#          use SDL windowing. Proton itself uses SDL internally; forcing x11 makes
#          Proton's SDL block until X11 is fully ready - causing hangs on servers
#          that never need a display (e.g. Unity headless builds run via
#          "proton run ./Server.exe -log").
# Auto-select: use x11 only when xalia is detected in STARTUP; otherwise dummy.
# Override with SDL_VIDEODRIVER=x11 or SDL_VIDEODRIVER=dummy in your server config.
if [ -z "${SDL_VIDEODRIVER:-}" ]; then
    if echo "${STARTUP:-}" | grep -qi 'xalia'; then
        export SDL_VIDEODRIVER="x11"
        info "SDL_VIDEODRIVER=x11 (xalia detected in STARTUP)"
    else
        export SDL_VIDEODRIVER="dummy"
        info "SDL_VIDEODRIVER=dummy (no xalia in STARTUP; use SDL_VIDEODRIVER=x11 to override)"
    fi
else
    export SDL_VIDEODRIVER
fi

# Suppress ALSA errors on headless servers without physical sound hardware.
# SDL_AUDIODRIVER=dummy prevents SDL from attempting ALSA/PulseAudio initialization.
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-dummy}"
export AUDIODEV="${AUDIODEV:-null}"

# Suppress expected headless DXVK noise (OpenVR not installed, OpenXR not installed, no EDID).
# Keep level at "error" so real DXVK errors are still visible.
# Set DXVK_LOG_LEVEL=info to restore full DXVK output for debugging.
export DXVK_LOG_LEVEL="${DXVK_LOG_LEVEL:-error}"

# Suppress VKD3D-Proton log noise on headless servers.
# Common false-positive: "Adapter with luid X not found" when a previously used
# GPU's LUID is stored in the Wine prefix but doesn't match lavapipe's adapter.
# Set VKD3D_DEBUG=err or VKD3D_DEBUG=warn to restore error/warning output.
export VKD3D_DEBUG="${VKD3D_DEBUG:-none}"

# Suppress OpenVR/OpenXR init attempts - not needed for dedicated servers.
export PROTON_ENABLE_NVAPI="${PROTON_ENABLE_NVAPI:-0}"
export DXVK_ENABLE_NVAPI="${DXVK_ENABLE_NVAPI:-0}"

# Note: NTSync is automatically enabled by modern Wine versions (>= 8.0) on kernel >= 6.14 with CONFIG_NTSYNC
# No manual configuration needed

# Proton-GE's protonfixes applies per-game compatibility fixes.
# Disabled by default for dedicated servers: protonfixes checks for a running
# Steam client (STEAM_COMPAT_CLIENT_INSTALL_PATH) and when PROTON_NO_STEAM=1 is
# set it detects a "unit test" environment and spams harmless but noisy WARNs.
# Set PROTON_USE_PROTONFIXES=1 in your server config to enable it explicitly.
if [ "${PROTON_USE_PROTONFIXES:-0}" = "1" ]; then
    export PROTON_USE_PROTONFIXES=1

    # Protonfixes requires a home directory for its script cache and configuration
    export PROTONHOMEDIR="${PROTONHOMEDIR:-/home/container/.proton}"
    mkdir -p "$PROTONHOMEDIR"
    mkdir -p "$PROTONHOMEDIR/protonfixes"

    success "Proton protonfixes system enabled"
fi

# ----------------------------
# Console Output Fixes
# ----------------------------
# Modern Wine/Proton versions may suppress console output due to CPU topology detection.
# The following environment variables help ensure proper console output.

# Auto-detect CPU topology and enable console output (primary fix)
# Modern systems may require this fix for proper console output in Proton
if [ "${WINE_CPU_TOPOLOGY:-}" = "" ]; then
    # Get actual CPU count - try multiple methods for compatibility
    CPU_COUNT=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || nproc 2>/dev/null || echo 4)
    # Format: cores:threads (for most systems: count:1 or count:2)
    # Most common: physical cores count with 1-2 threads per core
    CORES=$(( CPU_COUNT > 4 ? CPU_COUNT / 2 : CPU_COUNT ))
    export WINE_CPU_TOPOLOGY="${CORES}:2"
    info "Wine CPU topology auto-detected: $WINE_CPU_TOPOLOGY"
fi

# Secondary console output fixes (optional, enable via environment variable)
if [ "${WINE_CONSOLE_OUTPUT_FIX:-1}" = "1" ]; then
    # Enable more verbose Proton logging to ensure console output
    if [ "${PROTON_VERBOSITY:-}" = "" ]; then
        export PROTON_VERBOSITY=2
        info "Proton verbosity enabled (PROTON_VERBOSITY=2)"
    fi
fi

# Allow override for console debugging (less common, for advanced users)
# Set WINE_NOCRASHDIALOG=1 and WINE_MONO_TRACE=all if crashes need capturing

# Ensure a sane XDG_RUNTIME_DIR for services that rely on it
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR="/tmp/xdg-runtime-dir"
    mkdir -p "$XDG_RUNTIME_DIR"
    chown 1000:1000 "$XDG_RUNTIME_DIR" 2>/dev/null || true
fi

# Ensure HOME is set
HOME=${HOME:-/home/container}

if [ -n "${STEAM_APPID:-}" ]; then
    # Ensure all Steam/Proton directories live under /home/container/Steam
    # Create canonical steam directory and compatdata path
    mkdir -p /home/container/Steam
    mkdir -p "/home/container/Steam/steamapps/compatdata/${STEAM_APPID}"
    mkdir -p /home/container/Steam/compatibilitytools.d

    export STEAM_DIR="/home/container/Steam"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_DIR"
    export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH/steamapps/compatdata/${STEAM_APPID}"
    export WINETRICKS="/usr/sbin/winetricks"

    # Set WINEPREFIX to the per-App compatibilityprefix derived from STEAM_DIR (non-destructive).
    if [ -z "${WINEPREFIX:-}" ]; then
        # Ensure XDG_CONFIG_HOME is defined first for Wine/Proton
        if [ -z "${XDG_CONFIG_HOME:-}" ]; then
            export XDG_CONFIG_HOME="$HOME/.config"
        fi

        WINEPREFIX="$STEAM_DIR/steamapps/compatdata/${STEAM_APPID}/pfx"
        mkdir -p "${WINEPREFIX%/pfx}" "${WINEPREFIX}" "$XDG_CONFIG_HOME" 2>/dev/null || true
        export WINEPREFIX
        msg GREEN "WINEPREFIX set to $WINEPREFIX"

        # Ensure directory permissions
        chmod 700 "$XDG_CONFIG_HOME" 2>/dev/null || true
    fi

    # If ProtonGE is installed system-wide under /opt/ProtonGE, create a
    # non-destructive symlink into the per-container compatibilitytools.d
    # so tools like protontricks can find it without duplicating content.
    if [ -d "/opt/ProtonGE" ]; then
        TARGET_DIR="$STEAM_COMPAT_CLIENT_INSTALL_PATH/compatibilitytools.d"
        TARGET_LINK="$TARGET_DIR/ProtonGE"
        if [ ! -e "$TARGET_LINK" ]; then
            mkdir -p "$TARGET_DIR"
            if ln -s /opt/ProtonGE "$TARGET_LINK" 2>/dev/null; then
                msg GREEN "Created symlink: $TARGET_LINK -> /opt/ProtonGE"
            else
                msg RED "Failed to create symlink $TARGET_LINK -> /opt/ProtonGE"
            fi
        else
            if [ -L "$TARGET_LINK" ]; then
                # If it's already a symlink, check whether it points to the same source.
                EXIST_SRC=$(readlink -f "$TARGET_LINK" || true)
                if [ "$EXIST_SRC" != "/opt/ProtonGE" ]; then
                    msg YELLOW "Existing symlink $TARGET_LINK points to $EXIST_SRC; not modifying."
                fi
            else
                # Target exists and is not a symlink (file/dir) — do not overwrite.
                msg YELLOW "Target $TARGET_LINK already exists and is not a symlink; skipping symlink creation to avoid data loss."
            fi
        fi
    fi
else
    line BLUE
    error "STEAM_APPID not set"
    warning "Proton requires the STEAM_APPID environment variable"
    info "Please add STEAM_APPID to your server configuration (Pelican Panel, Pterodactyl, etc.)"
    line BLUE
    exit 1
fi

sleep 2

# ----------------------------
# Switch to the container's working directory
# ----------------------------
cd /home/container || { msg RED "Cannot cd to /home/container"; exit 1; }

# ----------------------------
# Steam user check
# ----------------------------
if [ -z "${STEAM_USER:-}" ]; then
    line BLUE
    warning "Steam user not set"
    info "Using anonymous user"
    line BLUE
    STEAM_USER="anonymous"
    STEAM_PASS=""
    STEAM_AUTH=""
else
    line BLUE
    success "Steam user: $STEAM_USER"
    line BLUE
fi

# ----------------------------
# SteamCMD / DepotDownloader Update
# ----------------------------
## auto_update only if explicitly set to 1
if [ "${AUTO_UPDATE:-}" = "1" ]; then
    if [ -f ./DepotDownloader ]; then
        progress 1 2 "Using DepotDownloader for server files update"

        if ! command -v mono >/dev/null 2>&1 && file ./DepotDownloader | grep -qi 'PE32'; then
            msg YELLOW "DepotDownloader looks like a .NET app; ensure 'mono' is available or it is executable"
        fi

        # Build DepotDownloader arguments safely to avoid word-splitting
        dd_args=( -dir . -username "$STEAM_USER" -password "${STEAM_PASS:-}" -remember-password )
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

        ./DepotDownloader "${dd_args[@]}" || { msg RED "DepotDownloader failed"; exit 1; }

        mkdir -p .steam/sdk64
        dd_sdk_args=( -dir .steam/sdk64 -app 1007 )
        if [ "${WINDOWS_INSTALL:-0}" = "1" ]; then
            dd_sdk_args+=( -os windows )
        fi
        ./DepotDownloader "${dd_sdk_args[@]}" || { msg RED "DepotDownloader SDK download failed"; exit 1; }

        chmod +x "$HOME"/* 2>/dev/null || true
    else
        progress 1 2 "Using SteamCMD for server files update"
        printf "${YELLOW}Steam user: ${GREEN}%s${NC}\n" "$STEAM_USER"

        if [ ! -x ./steamcmd/steamcmd.sh ]; then
            msg RED "steamcmd not found or not executable at ./steamcmd/steamcmd.sh"
            exit 1
        else
            # Build steamcmd arguments safely
            sc_args=( +force_install_dir /home/container +login "$STEAM_USER" "${STEAM_PASS:-}" "${STEAM_AUTH:-}" )
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
                sc_args+=( -betapassword "$STEAM_BETAPASS" )
            fi
            # Split INSTALL_FLAGS into array if set (simple whitespace split)
            if [ -n "${INSTALL_FLAGS:-}" ]; then
                # shellcheck disable=SC2206
                IFS=' ' read -r -a extra_flags <<<"$INSTALL_FLAGS"
                sc_args+=( "${extra_flags[@]}" )
            fi
            if [ "${VALIDATE:-0}" = "1" ]; then
                sc_args+=( validate )
            fi
            sc_args+=( +quit )

            ./steamcmd/steamcmd.sh "${sc_args[@]}" || { msg RED "SteamCMD failed"; exit 1; }
        fi
    fi
else
    line BLUE
    info "Auto Update disabled - skipping server files update"
    line BLUE
fi

# ----------------------------
# NTSync is a Wine feature, not a winetricks package - remove if present
# ----------------------------
if [[ "${WINETRICKS_RUN:-}" =~ ntsync ]]; then
    warning "NTSync is a Wine feature (not a winetricks package) - it's controlled via PROTON_ENABLE_NTSYNC environment variable"
    WINETRICKS_RUN=$(remove_token_from_list "$WINETRICKS_RUN" ntsync)
fi

# ----------------------------
# Winetricks runtime installation (into the per-app WINEPREFIX)
# ----------------------------
# Use `WINETRICKS_RUN` to install runtimes or verbs into the WINEPREFIX.
# Example: WINETRICKS_RUN="vcrun2022 corefonts" and optional
# `WINETRICKS_OPTS` for winetricks flags (e.g. --no-isolate --force).
if [ -n "${WINETRICKS_RUN:-}" ]; then
    # Default location for winetricks binary (can be overridden by env)
    WINETRICKS=${WINETRICKS:-/usr/sbin/winetricks}
    WINETRICKS_LOGFILE="$WINETRICKS_LOG_DIR/install_$(date +%s).log"

    if [ -z "${WINEPREFIX:-}" ]; then
        error "WINETRICKS_RUN set but WINEPREFIX is empty"
        info "Cannot run winetricks without WINEPREFIX"
        exit 1
    else
        line BLUE
        progress 2 2 "Preparing Proton prefix and installing runtimes"
        line BLUE

        # Ensure prefix directories exist (non-destructive)
        mkdir -p "${WINEPREFIX%/pfx}" "${WINEPREFIX}" 2>/dev/null || true

        if command -v "$WINETRICKS" >/dev/null 2>&1; then
            # Show intended actions
            msg YELLOW "  Installing: ${GREEN}$WINETRICKS_RUN${NC}"
            info "Log file: $WINETRICKS_LOGFILE"

            # Find Proton installation first
            PROTON_PATH=""
            for proton_base in /opt/ProtonGE /opt/GE-Proton* /usr/local/share/steam/compatibilitytools.d/ProtonGE /usr/local/share/steam/compatibilitytools.d/GE-Proton*; do
                if [ -f "$proton_base/proton" ]; then
                    PROTON_PATH="$proton_base"
                    success "Found Proton: $PROTON_PATH"
                    break
                fi
            done

            if [ -z "$PROTON_PATH" ]; then
                error "Could not find Proton installation"
                info "Winetricks requires Proton to be installed"
                exit 1
            fi

            # Initialize Wine prefix with Proton FIRST (critical step!)
            info "Initializing Wine prefix with Proton..."
            if "$PROTON_PATH/proton" run wineboot -u 2>&1 | tee -a "$WINETRICKS_LOGFILE"; then
                success "Wine prefix initialized"
            else
                warning "Prefix initialization returned non-zero, but continuing..."
            fi

            # Now find and export Proton's Wine binaries for winetricks
            # Proton stores wine64/wineserver in dist/bin or files/bin
            if [ -z "${WINE:-}" ]; then
                # Try dist/bin first (newer Proton-GE versions)
                if [ -f "$PROTON_PATH/dist/bin/wine64" ]; then
                    export WINE="$PROTON_PATH/dist/bin/wine64"
                    export WINESERVER="$PROTON_PATH/dist/bin/wineserver"
                    export WINELOADER="$PROTON_PATH/dist/bin/wine64"
                    export PATH="$PROTON_PATH/dist/bin:$PATH"
                    export LD_LIBRARY_PATH="$PROTON_PATH/dist/lib64:$PROTON_PATH/dist/lib:${LD_LIBRARY_PATH:-}"
                    success "Using Proton Wine from dist/bin: $WINE"
                # Try files/bin (older versions)
                elif [ -f "$PROTON_PATH/files/bin/wine64" ]; then
                    export WINE="$PROTON_PATH/files/bin/wine64"
                    export WINESERVER="$PROTON_PATH/files/bin/wineserver"
                    export WINELOADER="$PROTON_PATH/files/bin/wine64"
                    export PATH="$PROTON_PATH/files/bin:$PATH"
                    export LD_LIBRARY_PATH="$PROTON_PATH/files/lib64:$PROTON_PATH/files/lib:${LD_LIBRARY_PATH:-}"
                    success "Using Proton Wine from files/bin: $WINE"
                # Fallback: try dist/bin/wine (without 64 suffix)
                elif [ -f "$PROTON_PATH/dist/bin/wine" ]; then
                    export WINE="$PROTON_PATH/dist/bin/wine"
                    export WINESERVER="$PROTON_PATH/dist/bin/wineserver"
                    export WINELOADER="$PROTON_PATH/dist/bin/wine"
                    export PATH="$PROTON_PATH/dist/bin:$PATH"
                    export LD_LIBRARY_PATH="$PROTON_PATH/dist/lib64:$PROTON_PATH/dist/lib:${LD_LIBRARY_PATH:-}"
                    success "Using Proton Wine: $WINE"
                else
                    warning "Could not find Wine binaries in Proton"
                    info "Winetricks may fail without Wine"
                fi
            fi

            # Create marker directory for tracking installations
            WINETRICKS_MARKER_DIR="$WINEPREFIX/.winetricks_markers"
            mkdir -p "$WINETRICKS_MARKER_DIR"

            # Check if packages are already installed using markers
            info "Checking for already installed packages..."
            PACKAGES_TO_INSTALL=""

            for pkg in $WINETRICKS_RUN; do
                if [ -f "$WINETRICKS_MARKER_DIR/$pkg" ]; then
                    success "$pkg is already installed - skipping"
                else
                    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $pkg"
                fi
            done

            # Trim whitespace
            PACKAGES_TO_INSTALL=$(echo "$PACKAGES_TO_INSTALL" | xargs)

            if [ -z "$PACKAGES_TO_INSTALL" ]; then
                success "All requested packages already installed"
                WINETRICKS_EXIT=0
            else
                info "Installing packages: $PACKAGES_TO_INSTALL"

                # Run winetricks with optional options. We intentionally allow
                # the shell to split $WINETRICKS_RUN into separate verbs so
                # multiple verbs can be passed in one invocation.
                WINETRICKS_EXIT=0
                if [ -n "${WINETRICKS_OPTS:-}" ]; then
                    info "Running winetricks with options"
                    env WINEPREFIX="$WINEPREFIX" WINETRICKS_QUIET=0 "$WINETRICKS" $WINETRICKS_OPTS $PACKAGES_TO_INSTALL 2>&1 | tee "$WINETRICKS_LOGFILE" || WINETRICKS_EXIT=${PIPESTATUS[0]}
                else
                    env WINEPREFIX="$WINEPREFIX" WINETRICKS_QUIET=0 "$WINETRICKS" $PACKAGES_TO_INSTALL 2>&1 | tee "$WINETRICKS_LOGFILE" || WINETRICKS_EXIT=${PIPESTATUS[0]}
                fi

                # Check if exit code 203 (often means "already installed" for some installers)
                if [ $WINETRICKS_EXIT -eq 203 ]; then
                    warning "Installer returned exit code 203 (may indicate already installed)"
                    # Mark as installed anyway since exit 203 is often a false failure
                    for pkg in $PACKAGES_TO_INSTALL; do
                        touch "$WINETRICKS_MARKER_DIR/$pkg"
                        success "Marked $pkg as installed"
                    done
                    WINETRICKS_EXIT=0
                fi
            fi

            if [ $WINETRICKS_EXIT -eq 0 ]; then
                # Mark all successfully installed packages
                for pkg in $PACKAGES_TO_INSTALL; do
                    touch "$WINETRICKS_MARKER_DIR/$pkg"
                done
                success "Proton prefix setup complete"
            else
                error "winetricks failed with exit code $WINETRICKS_EXIT"
                warning "Full output saved to: $WINETRICKS_LOGFILE"
                # Check if WINETRICKS_IGNORE_ERRORS is explicitly set to 1 to continue anyway
                if [ "${WINETRICKS_IGNORE_ERRORS:-0}" != "1" ]; then
                    info "Set WINETRICKS_IGNORE_ERRORS=1 to continue despite winetricks failures"
                    info "View logs: cat '$WINETRICKS_LOGFILE'"
                    exit 1
                else
                    warning "Continuing despite winetricks failures (WINETRICKS_IGNORE_ERRORS=1)"
                fi
            fi
        else
            error "winetricks not found at ${WINETRICKS}"
            info "Cannot install runtimes without winetricks"
            exit 1
        fi
    fi
fi

# ----------------------------
# Startup command
# ----------------------------
if [ -z "${STARTUP:-}" ]; then
    error "STARTUP command not provided"
    info "Nothing to execute - server cannot start"
    exit 1
fi

line BLUE
progress 3 3 "Starting server"
line BLUE

# Prepare server startup logging
SERVER_LOG="$SERVER_LOG_DIR/startup_$(date +%s).log"

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"
line BLUE
info "📁 Log directories:"
info "  • Server output: $SERVER_LOG"
info "  • Proton logs: $PROTON_LOG_DIR"
info "  • Winetricks: $WINETRICKS_LOG_DIR"
line BLUE

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
                    tail -c0 -F "$latest_log" --pid="$SERVER_PID" 2>/dev/null || true
                    return 0
                fi
            fi
        done
    done
}

# Execute startup command - eval is required to handle quoted args and shell operators.
# STARTUP is set by the panel (trusted source), not directly by end-users.
# Process substitution (> >(...)) is used instead of a pipe so that $! captures
# the actual server PID rather than tee's PID. A pipe would cause $! to point at
# tee/grep, making kill/wait unreliable and potentially deadlocking when pipe
# buffers fill. Headless noise (ALSA, DXGI, Xalia) is already suppressed via
# WINEDEBUG, DXVK_LOG_LEVEL and /etc/asound.conf - no grep filter needed.
eval "$MODIFIED_STARTUP" > >(tee -a "$SERVER_LOG") 2>&1 &
SERVER_PID=$!

# Validate that the process was actually started
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    error "Failed to start server process - command may have failed immediately"
    warning "Check logs: $SERVER_LOG"
    exit 1
fi

success "Server process started (PID: $SERVER_PID)"

# Stream logs in parallel if game writes to log files
if [ "${STREAM_LOGS:-1}" != "0" ]; then
    stream_game_logs &
    LOG_PID=$!
fi

# Monitor for early crashes (first 5 seconds)
info "Monitoring for early crashes..."
sleep 3
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    line RED
    error "❌ Server crashed within 3 seconds of startup!"
    line RED

    # Function to show detailed crash analysis
    show_crash_analysis() {
        msg RED "🔍 Crash Diagnosis:"
        echo ""

        # 1. Show last lines of server log
        if [ -f "$SERVER_LOG" ] && [ -s "$SERVER_LOG" ]; then
            msg YELLOW "📋 Last 30 lines of server output:"
            tail -n 30 "$SERVER_LOG" 2>/dev/null | sed 's/^/    /' || echo "    (Could not read log)"
            echo ""
        else
            msg YELLOW "⚠ Server log is empty or missing: $SERVER_LOG"
            echo ""
        fi

        # 2. Show Proton logs
        if [ -d "$PROTON_LOG_DIR" ]; then
            latest_proton_log=$(find "$PROTON_LOG_DIR" -type f \( -name "*.log" -o -name "steam-*" \) 2>/dev/null | xargs ls -t 2>/dev/null | head -n1)
            if [ -n "$latest_proton_log" ] && [ -s "$latest_proton_log" ]; then
                msg YELLOW "🍷 Latest Proton/Wine log: $(basename "$latest_proton_log")"
                tail -n 20 "$latest_proton_log" 2>/dev/null | sed 's/^/    /' || echo "    (Could not read log)"
                echo ""
            else
                msg YELLOW "⚠ No Proton logs found in: $PROTON_LOG_DIR"
                echo ""
            fi
        fi

        # 3. Check for Wine crash dumps
        for crashfile in "${WINEPREFIX:-}/drive_c/windows/system32/crashdump.txt" "${WINEPREFIX:-}/*.crash" "${WINEPREFIX:-}/drive_c/*.crash"; do
            if [ -f "$crashfile" ] && [ -s "$crashfile" ]; then
                msg YELLOW "💥 Wine crash dump: $(basename "$crashfile")"
                head -n 30 "$crashfile" 2>/dev/null | sed 's/^/    /' || echo "    (Could not read)"
                echo ""
            fi
        done

        # 4. Check for missing DLLs or common errors in logs
        if [ -f "$SERVER_LOG" ]; then
            if grep -qi "could not find\|cannot find\|missing" "$SERVER_LOG" 2>/dev/null; then
                msg YELLOW "⚠ Possible missing dependencies detected:"
                grep -i "could not find\|cannot find\|missing" "$SERVER_LOG" 2>/dev/null | tail -n 5 | sed 's/^/    /' || true
                echo ""
            fi
            if grep -qi "error\|failed\|exception" "$SERVER_LOG" 2>/dev/null; then
                msg YELLOW "❗ Errors found in server log:"
                grep -i "error\|failed\|exception" "$SERVER_LOG" 2>/dev/null | tail -n 10 | sed 's/^/    /' || true
                echo ""
            fi
        fi

        # 5. System info that might help
        msg YELLOW "💻 System info:"
        echo "    WINEPREFIX: ${WINEPREFIX:-not set}"
        echo "    WINEARCH: ${WINEARCH:-not set}"
        echo "    PROTON_LOG: ${PROTON_LOG:-not set}"
        echo ""

        line RED
        msg CYAN "📁 Full logs available at:"
        info "  • Server: $SERVER_LOG"
        info "  • Proton: $PROTON_LOG_DIR"
        info "  • Winetricks: $WINETRICKS_LOG_DIR"
        line RED
    }

    show_crash_analysis
fi

success "Server survived initial startup checks"

# Wait for server process
if wait $SERVER_PID 2>/dev/null; then
    SERVER_EXIT=0
else
    SERVER_EXIT=$?

    # Server exited with error
    if [ $SERVER_EXIT -ne 0 ]; then
        line RED
        error "Server exited with code $SERVER_EXIT"
        msg YELLOW "Last 30 lines of output:"
        tail -n 30 "$SERVER_LOG" 2>/dev/null | while IFS= read -r log_line; do
            printf "  %s\n" "$log_line"
        done
        line RED
        info "Full logs: $SERVER_LOG"
        info "Proton logs: $PROTON_LOG_DIR"
    fi
fi

# Cleanup log streaming if active
if [ -n "${LOG_PID:-}" ]; then
    kill "$LOG_PID" 2>/dev/null || true
fi

exit $SERVER_EXIT
