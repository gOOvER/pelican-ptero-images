#!/bin/bash
set -e

ERROR_LOG="entrypoint_error.log"
> "$ERROR_LOG"  # Alte Logdatei leeren

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
    if [ "$color" = "RED" ]; then
        printf "%b\n" "${RED}$*${NC}" | tee -a "$ERROR_LOG" >&2
    else
        printf "%b\n" "${!color}$*${NC}"
    fi
}

line() {
    local color="${1:-BLUE}"
    local term_width=$(tput cols 2>/dev/null || echo 70)
    local sep=$(printf '%*s' "$term_width" '' | tr ' ' '-')

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

cleanup() {
    msg YELLOW "Cleaning up..."
    # Simple cleanup - mongod --shutdown will handle MongoDB
}

find_free_port() {
    local port=${1:-27017}
    while nc -z 127.0.0.1 "$port" 2>/dev/null; do
        port=$((port + 1))
    done
    echo "$port"
}

# ----------------------------
# Error trap
# ----------------------------
trap 'echo "$(date +"%Y-%m-%d %H:%M:%S") - Unexpected error at line $LINENO" | tee -a "$ERROR_LOG" >&2' ERR
trap cleanup EXIT

# ----------------------------
# Environment
# ----------------------------
cd /home/container || { msg RED "Failed to change directory to /home/container."; exit 1; }

sleep 1

export TZ=${TZ:-UTC}
MONGO_PORT=$(find_free_port "${MONGO_PORT:-27017}")
export MONGO_PORT
export MONGO_DB=${MONGO_DB:-botdb}
export MONGO_URL=${MONGO_URL:-"mongodb://127.0.0.1:${MONGO_PORT}/${MONGO_DB}"}

# Get internal IP with better error handling
INTERNAL_IP=""
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# ----------------------------
# System Info
# ----------------------------
clear
line BLUE
msg RED "NodeJS & MongoDB Image by gOOvER - https://discord.goover.dev"
msg RED "This Image is licencend under AGPLv3"
line BLUE
msg YELLOW "Running on: ${RED}$(. /etc/os-release ; echo $NAME $VERSION)"
msg YELLOW "Current timezone: ${RED}$(cat /etc/timezone)"
line BLUE
msg YELLOW "NodeJS Version: ${RED}$(node -v)"
msg YELLOW "BUN Version: ${RED}$(bun --version)"
msg YELLOW "npm Version: ${RED}$(npm -v)"
msg YELLOW "MongoDB Version: ${RED}$(mongod --version | head -n 1)"
line BLUE

# ----------------------------
# Start MongoDB
# ----------------------------
line BLUE
msg YELLOW "Starting MongoDB..."
line BLUE

# Ensure MongoDB directory exists and has correct permissions
mkdir -p /home/container/mongodb
chown -R container:container /home/container/mongodb 2>/dev/null || true

# Detect MongoDB major.minor version (e.g. "8.0", "8.2", "8.3")
# Note: mongod --version may fail on Linux kernel 6.19+ without GLIBC_TUNABLES set.
# GLIBC_TUNABLES=glibc.pthread.rseq=1 is set via ENV in the Dockerfile as the workaround.
MONGO_VERSION=$(mongod --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | cut -d. -f1-2)
MONGO_VERSION=${MONGO_VERSION:-"8.3"}
MONGO_MAJOR=$(echo "$MONGO_VERSION" | cut -d. -f1)
MONGO_MINOR=$(echo "$MONGO_VERSION" | cut -d. -f2)
MONGO_MARKER="/home/container/mongodb/.mongodb${MONGO_VERSION//./_}_upgraded"

# Check for MongoDB version compatibility issues and clean if needed
# Only run compatibility check if we haven't already migrated (check for marker file)
if [ -f "/home/container/mongodb/_mdb_catalog.wt" ] || [ -f "/home/container/mongodb/WiredTiger.wt" ]; then
    line YELLOW
    msg YELLOW "Existing MongoDB data detected - checking compatibility..."

    # Check if we've already done a migration (marker file exists)
    if [ -f "$MONGO_MARKER" ]; then
        line GREEN
        msg GREEN "MongoDB $MONGO_VERSION upgrade already completed, skipping compatibility check..."
    else
        # MongoDB 8.0 supports direct upgrade from 7.x
        # MongoDB 8.2+ requires 7.x → 8.0 → 8.2 path
        line CYAN
        msg YELLOW "Testing MongoDB $MONGO_VERSION compatibility..."

        # Start mongod briefly to check for errors
        mongod --dbpath /home/container/mongodb/ --port $((MONGO_PORT + 1)) --logpath /tmp/mongo_test.log --fork 2>/dev/null || true
        sleep 2

        # Check if the test log contains version compatibility errors
        if grep -q "Wrong mongod version\|STORAGE_ENGINE_ERROR" /tmp/mongo_test.log 2>/dev/null; then
            line RED

            # Check if this is 8.2+ trying to upgrade from 7.x
            if [ "$MONGO_MINOR" -ge 2 ] && grep -q "featureCompatibilityVersion.*7\." /tmp/mongo_test.log 2>/dev/null; then
                msg RED "CRITICAL: MongoDB 8.2+ cannot upgrade directly from 7.x data!"
                line RED
                msg YELLOW "MongoDB 8.2+ requires upgrade path: 7.x → 8.0 → 8.2"
                msg YELLOW "Please use the 'nodemongo8' image (MongoDB 8.0) first to upgrade your data."
            else
                msg RED "CRITICAL: MongoDB data appears corrupted or incompatible!"
            fi

            line RED
            msg YELLOW "Creating backup of existing data for safety..."

            # Stop the test mongod
            mongod --shutdown --dbpath /home/container/mongodb/ 2>/dev/null || pkill -f "mongod.*$((MONGO_PORT + 1))" || true

            # Create backup directory with timestamp
            BACKUP_DIR="/home/container/mongodb_backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"

            # Move old data to backup
            mv /home/container/mongodb/* "$BACKUP_DIR/" 2>/dev/null || true

            line GREEN
            msg GREEN "✓ Data backed up to: $BACKUP_DIR"
            msg GREEN "✓ Starting fresh MongoDB $MONGO_VERSION instance"
            msg YELLOW "⚠ Restore your data using mongorestore if needed"
            line GREEN

            # Create marker file
            touch "$MONGO_MARKER"
        else
            # Stop the test mongod if it started successfully
            mongod --shutdown --dbpath /home/container/mongodb/ 2>/dev/null || pkill -f "mongod.*$((MONGO_PORT + 1))" || true
            line GREEN
            msg GREEN "✓ MongoDB $MONGO_VERSION can upgrade from existing data"

            # Create marker file to skip check on future restarts
            touch "$MONGO_MARKER"
        fi

        # Clean up test log
        rm -f /tmp/mongo_test.log
    fi
else
    # Fresh MongoDB data or already compatible
    line GREEN
    msg GREEN "MongoDB data directory ready..."
    # Create marker file for future restarts
    touch "$MONGO_MARKER"
fi

line BLUE
# MongoDB startup with latest features and optimizations
mongod --dbpath /home/container/mongodb/ \
       --port $MONGO_PORT \
       --bind_ip_all \
       --logpath /home/container/mongod.log \
       --logappend \
       --storageEngine wiredTiger \
       --wiredTigerCacheSizeGB 0.5 \
       --setParameter enableFlowControl=true \
       --setParameter flowControlTargetLagSeconds=10 > /dev/null 2>&1 &

sleep 2
until nc -z -w5 127.0.0.1 $MONGO_PORT; do
  echo 'Waiting for MongoDB connection...'
  sleep 3
done

line GREEN
msg GREEN "✓ MongoDB is ready"

# ----------------------------
# Set Feature Compatibility Version dynamically
# ----------------------------
line CYAN
# TARGET_FCV comes from the MONGO_VERSION detected at startup
TARGET_FCV="$MONGO_VERSION"

msg YELLOW "Checking MongoDB Feature Compatibility Version (MongoDB $MONGO_VERSION)..."

# Check and set FCV using mongosh
if command -v mongosh &> /dev/null; then
    CURRENT_FCV=$(mongosh --quiet --port $MONGO_PORT --eval "db.adminCommand({ getParameter: 1, featureCompatibilityVersion: 1 }).featureCompatibilityVersion.version" 2>/dev/null || echo "unknown")

    if [ "$CURRENT_FCV" != "$TARGET_FCV" ] && [ "$CURRENT_FCV" != "unknown" ]; then
        msg YELLOW "Current FCV: $CURRENT_FCV"

        # Check if we need a staged upgrade (8.2+ requires 8.0 intermediate step from 7.x)
        if [ "$MONGO_MINOR" -ge 2 ] && [[ "$CURRENT_FCV" =~ ^7\. ]]; then
            line YELLOW
            msg YELLOW "⚠ MongoDB 8.2+ detected with FCV 7.x - staged upgrade required"
            msg YELLOW "Step 1: Upgrading FCV to 8.0 first..."

            if mongosh --quiet --port $MONGO_PORT --eval 'db.adminCommand({ setFeatureCompatibilityVersion: "8.0", confirm: true })' 2>/dev/null; then
                msg GREEN "✓ FCV upgraded to 8.0"
                sleep 2
                msg YELLOW "Step 2: Upgrading FCV to $TARGET_FCV..."

                if mongosh --quiet --port $MONGO_PORT --eval "db.adminCommand({ setFeatureCompatibilityVersion: \"$TARGET_FCV\", confirm: true })" 2>/dev/null; then
                    msg GREEN "✓ Feature Compatibility Version successfully upgraded to $TARGET_FCV"
                else
                    msg RED "⚠ FCV upgrade to $TARGET_FCV failed - staying at 8.0"
                    msg YELLOW "This is safe. You can manually upgrade later if needed."
                fi
            else
                msg RED "⚠ Could not upgrade FCV to 8.0 - staying at $CURRENT_FCV"
            fi
        else
            # Direct upgrade possible
            msg YELLOW "Upgrading to $TARGET_FCV..."
            if mongosh --quiet --port $MONGO_PORT --eval "db.adminCommand({ setFeatureCompatibilityVersion: \"$TARGET_FCV\", confirm: true })" 2>/dev/null; then
                msg GREEN "✓ Feature Compatibility Version set to $TARGET_FCV"
            else
                msg YELLOW "⚠ Could not set FCV - MongoDB might not support direct upgrade"
                msg YELLOW "Current FCV ($CURRENT_FCV) will be maintained"
            fi
        fi
    else
        msg GREEN "✓ Feature Compatibility Version already at $TARGET_FCV"
    fi
else
    # Fallback to mongo shell if mongosh not available
    msg YELLOW "Using legacy mongo shell..."
    mongo --quiet --port $MONGO_PORT --eval "db.adminCommand({ setFeatureCompatibilityVersion: \"$TARGET_FCV\", confirm: true })" 2>/dev/null && \
        msg GREEN "✓ Feature Compatibility Version set to $TARGET_FCV" || \
        msg YELLOW "⚠ Could not verify/set FCV"
fi

# ----------------------------
# Start Bot
# ----------------------------
line BLUE
msg YELLOW "Starting Bot..."
line BLUE

# ----------------------------
# Startup command
# ----------------------------
MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
msg CYAN ":/home/container$ $MODIFIED_STARTUP"

# exec bash -c für komplexe Shell-Kommandos
eval "$MODIFIED_STARTUP"

# stop mongo with correct dbpath
mongod --dbpath /home/container/mongodb/ --shutdown
