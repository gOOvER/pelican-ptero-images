#!/bin/bash
set -euo pipefail

ERROR_LOG="install_error.log"
: > "$ERROR_LOG"  # Clear old log file (no-op)

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
# Enable Proton logging for debugging
export PROTON_LOG=1
export PROTON_LOG_DIR="${PROTON_LOG_DIR:-/home/container/logs}"
mkdir -p "$PROTON_LOG_DIR"

# Create separate log directories for organization
mkdir -p "$PROTON_LOG_DIR/proton"
mkdir -p "$PROTON_LOG_DIR/server"

# Enhanced Proton logging (logs will be in $PROTON_LOG_DIR/proton/)
export PROTON_LOG_DIR="$PROTON_LOG_DIR/proton"

# Enable verbose Wine logging for crash diagnosis
export WINEDEBUG="${WINEDEBUG:-warn+all}"

# Track crashes and errors
export PROTON_CRASH_REPORT_DIR="$PROTON_LOG_DIR"

# Disable Steam client integration for dedicated servers (faster, less resources)
export PROTON_NO_STEAM=1

# Optional: Enable NTSync for improved synchronization (requires kernel >= 6.14 with CONFIG_NTSYNC)
# Auto-detect kernel version - enable by default if >= 6.14
KERNEL_VERSION=$(uname -r)
KERNEL_MAJOR=$(echo "$KERNEL_VERSION" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL_VERSION" | cut -d. -f2)

if [ "$KERNEL_MAJOR" -gt 6 ] || ([ "$KERNEL_MAJOR" -eq 6 ] && [ "$KERNEL_MINOR" -ge 14 ]); then
    # Auto-enable NTSync if kernel >= 6.14 (unless explicitly disabled)
    if [ "${PROTON_ENABLE_NTSYNC:-1}" != "0" ]; then
        export PROTON_ENABLE_NTSYNC=1
        success "Kernel $KERNEL_VERSION (>= 6.14) - NTSync automatically enabled"
    else
        warning "NTSync disabled by user (PROTON_ENABLE_NTSYNC=0)"
    fi
else
    warning "Kernel $KERNEL_VERSION (< 6.14) - NTSync not available"
fi

# Enable Proton-GE's protonfixes system for automatic game-specific fixes (enabled by default)
# Set PROTON_USE_PROTONFIXES=0 in your container configuration to disable
if [ "${PROTON_USE_PROTONFIXES:-1}" != "0" ]; then
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
    # Prevent Wine from suppressing GDI output which can affect console rendering
    export WINE_NO_GDI="${WINE_NO_GDI:-0}"
    export WINE_NO_COLOR_BITMAP="${WINE_NO_COLOR_BITMAP:-0}"

    # Enable more verbose Proton logging to ensure console output
    if [ "${PROTON_VERBOSITY:-}" = "" ]; then
        export PROTON_VERBOSITY=2
        info "Proton verbosity enabled (PROTON_VERBOSITY=2)"
    fi
fi

# Allow override for console debugging (less common, for advanced users)
# Set WINE_NOCRASHDIALOG=1 and WINE_MONO_TRACE=all if crashes need capturing
: # Placeholder for potential advanced debugging options

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
# Fix relative asset paths when working dir is /home/container/bin
# ----------------------------
# Prevent missing gui/locale.kvp if the game expects bin/gui, bin/packs, etc.
for d in gui packs data; do
    if [[ -d "/home/container/$d" && ! -e "/home/container/bin/$d" ]]; then
        ln -s "../$d" "/home/container/bin/$d" 2>/dev/null || true
    fi
done

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

is_valid_steam_dir() {
    # Simplified Steam dir validation
    local dir="$1"
    [ -d "$dir/steamapps" ] || [ -d "$dir/SteamApps" ] || [ -d "$dir/compatibilitytools.d" ]
}

# ----------------------------
# Winetricks runtime installation (into the per-app WINEPREFIX)
# ----------------------------
# Use `WINETRICKS_RUN` to install runtimes or verbs into the WINEPREFIX.
# Example: WINETRICKS_RUN="vcrun2022 corefonts" and optional
# `WINETRICKS_OPTS` for winetricks flags (e.g. --no-isolate --force).
if [ -n "${WINETRICKS_RUN:-}" ]; then
    # Default location for winetricks binary (can be overridden by env)
    WINETRICKS=${WINETRICKS:-/usr/sbin/winetricks}
    WINETRICKS_LOG_DIR="${PROTON_LOG_DIR}/winetricks"
    mkdir -p "$WINETRICKS_LOG_DIR"
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

            # Check if packages are already installed to avoid re-installation errors
            info "Checking for already installed packages..."
            INSTALLED_PACKAGES=$(env WINEPREFIX="$WINEPREFIX" "$WINETRICKS" list-installed 2>/dev/null || true)
            PACKAGES_TO_INSTALL=""

            for pkg in $WINETRICKS_RUN; do
                if echo "$INSTALLED_PACKAGES" | grep -q "^${pkg}$"; then
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
            fi

            if [ $WINETRICKS_EXIT -eq 0 ]; then
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
SERVER_LOG="/home/container/logs/server/startup_$(date +%s).log"
mkdir -p "$(dirname "$SERVER_LOG")"

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"
info "Server output log: $SERVER_LOG"
info "Proton logs directory: $PROTON_LOG_DIR"

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
eval "$MODIFIED_STARTUP" 2>&1 | tee -a "$SERVER_LOG" &
SERVER_PID=$!

# Validate that the process was actually started
if ! kill -0 $SERVER_PID 2>/dev/null; then
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
sleep 2
if ! kill -0 $SERVER_PID 2>/dev/null; then
    error "Server crashed within 2 seconds of startup!"
    line RED
    msg RED "Crash Diagnosis:"

    # Show last lines of server log
    if [ -f "$SERVER_LOG" ]; then
        msg YELLOW "Last 20 lines of server output:"
        tail -n 20 "$SERVER_LOG" | while IFS= read -r line; do
            printf "  %s\n" "$line"
        done
    fi

    # Show Proton logs if they exist
    if [ -d "$PROTON_LOG_DIR" ]; then
        msg YELLOW "Proton logs available in: $PROTON_LOG_DIR"
        latest_proton_log=$(find "$PROTON_LOG_DIR" -type f -name "*.log" -o -name "steam-*" | sort -r | head -n1)
        if [ -n "$latest_proton_log" ]; then
            msg YELLOW "Latest Proton log: $latest_proton_log"
            msg YELLOW "Last 15 lines:"
            tail -n 15 "$latest_proton_log" 2>/dev/null | while IFS= read -r line; do
                printf "  %s\n" "$line"
            done
        fi
    fi

    # Check for Wine crashes
    if [ -f "${WINEPREFIX:-}/drive_c/windows/system32/crashdump.txt" ]; then
        msg YELLOW "Wine crash dump found:"
        cat "${WINEPREFIX}/drive_c/windows/system32/crashdump.txt" | while IFS= read -r line; do
            printf "  %s\n" "$line"
        done
    fi

    line RED
    info "Full logs: $SERVER_LOG"
    info "Proton logs: $PROTON_LOG_DIR"
    exit 1
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
        tail -n 30 "$SERVER_LOG" 2>/dev/null | while IFS= read -r line; do
            printf "  %s\n" "$line"
        done
        line RED
        info "Full logs: $SERVER_LOG"
        info "Proton logs: $PROTON_LOG_DIR"
    fi
fi

# Cleanup log streaming if active
if [ -n "${LOG_PID:-}" ]; then
    kill $LOG_PID 2>/dev/null || true
fi

exit $SERVER_EXIT
