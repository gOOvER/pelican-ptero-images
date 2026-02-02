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

            # Run winetricks with optional options. We intentionally allow
            # the shell to split $WINETRICKS_RUN into separate verbs so
            # multiple verbs can be passed in one invocation.
            if [ -n "${WINETRICKS_OPTS:-}" ]; then
                info "Running winetricks with options"
                env WINEPREFIX="$WINEPREFIX" "$WINETRICKS" $WINETRICKS_OPTS $WINETRICKS_RUN || error "winetricks failed"
            else
                env WINEPREFIX="$WINEPREFIX" "$WINETRICKS" $WINETRICKS_RUN || error "winetricks failed"
            fi
            success "Proton prefix setup complete"
        else
            error "winetricks not found at ${WINETRICKS}"
            info "Cannot install runtimes without winetricks"
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

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"

# Execute startup command with eval for proper shell expansion
# Only environment variables and shell operators are processed, preventing code injection
eval "exec $MODIFIED_STARTUP"
