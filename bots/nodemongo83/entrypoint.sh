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

# Check for MongoDB version compatibility issues and clean if needed
# Only run compatibility check if we haven't already migrated (check for marker file)
if [ -f "/home/container/mongodb/_mdb_catalog.wt" ] || [ -f "/home/container/mongodb/WiredTiger.wt" ]; then
    line YELLOW
    msg YELLOW "Existing MongoDB data detected - checking compatibility..."

    # Check if we've already done a migration (marker file exists)
    if [ -f "/home/container/mongodb/.mongodb8_upgraded" ]; then
        line GREEN
        msg GREEN "MongoDB 8.0 upgrade already completed, skipping compatibility check..."
    else
        # MongoDB 8.0 supports direct upgrade from 7.x
        # Just ensure featureCompatibilityVersion is set correctly
        line CYAN
        msg YELLOW "Testing MongoDB 8.0 compatibility..."

        # Start mongod briefly to check for critical errors
        mongod --dbpath /home/container/mongodb/ --port 27018 --logpath /tmp/mongo_test.log --fork 2>/dev/null || true
        sleep 2

        # Check if the test log contains CRITICAL version errors (not just warnings)
        if grep -q "Wrong mongod version\|STORAGE_ENGINE_ERROR" /tmp/mongo_test.log 2>/dev/null; then
            line RED
            msg RED "CRITICAL: MongoDB data appears corrupted or incompatible!"
            line RED
            msg YELLOW "Creating backup of existing data for safety..."

            # Stop the test mongod
            mongod --shutdown --port 27018 2>/dev/null || pkill -f "mongod.*27018" || true

            # Create backup directory with timestamp
            BACKUP_DIR="/home/container/mongodb_backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"

            # Move old data to backup
            mv /home/container/mongodb/* "$BACKUP_DIR/" 2>/dev/null || true

            line GREEN
            msg GREEN "✓ Data backed up to: $BACKUP_DIR"
            msg GREEN "✓ Starting fresh MongoDB 8.0 instance"
            msg YELLOW "⚠ Restore your data using mongorestore if needed"
            line GREEN

            # Create marker file
            touch /home/container/mongodb/.mongodb8_upgraded
        else
            # Stop the test mongod if it started successfully
            mongod --shutdown --port 27018 2>/dev/null || pkill -f "mongod.*27018" || true
            line GREEN
            msg GREEN "✓ MongoDB 8.0 can upgrade from existing data"
            msg YELLOW "Note: MongoDB will automatically upgrade featureCompatibilityVersion on first start"

            # Create marker file to skip check on future restarts
            touch /home/container/mongodb/.mongodb8_upgraded
        fi

        # Clean up test log
        rm -f /tmp/mongo_test.log
    fi
else
    # Fresh MongoDB 8.0 data or already compatible
    line GREEN
    msg GREEN "MongoDB 8.0 data directory ready..."
    # Create marker file for future restarts
    touch /home/container/mongodb/.mongodb8_upgraded
fi

line BLUE
# MongoDB 8.0 startup with latest features
mongod --dbpath /home/container/mongodb/ \
       --port 27017 \
       --bind_ip_all \
       --logpath /home/container/mongod.log \
       --logappend \
       --storageEngine wiredTiger \
       --wiredTigerCacheSizeGB 0.5 \
       --wiredTigerEngineConfigString="cache_size=512MB" \
       --setParameter enableFlowControl=true \
       --setParameter flowControlTargetLagSeconds=10 \
       --setParameter mirrorReads="{samplingRate: 0.01}" &

until nc -z -v -w5 127.0.0.1 27017; do
  echo 'Waiting for MongoDB connection...'
  sleep 5
done

line GREEN
msg GREEN "✓ MongoDB is ready"

# ----------------------------
# Set Feature Compatibility Version to 8.0
# ----------------------------
line CYAN
msg YELLOW "Setting MongoDB Feature Compatibility Version to 8.0..."

# Check and set FCV using mongosh
if command -v mongosh &> /dev/null; then
    CURRENT_FCV=$(mongosh --quiet --eval "db.adminCommand({ getParameter: 1, featureCompatibilityVersion: 1 }).featureCompatibilityVersion.version" 2>/dev/null || echo "unknown")

    if [ "$CURRENT_FCV" != "8.0" ] && [ "$CURRENT_FCV" != "unknown" ]; then
        msg YELLOW "Current FCV: $CURRENT_FCV - Upgrading to 8.0..."
        mongosh --quiet --eval 'db.adminCommand({ setFeatureCompatibilityVersion: "8.0" })' 2>/dev/null && \
            msg GREEN "✓ Feature Compatibility Version set to 8.0" || \
            msg YELLOW "⚠ Could not set FCV (might already be correct)"
    else
        msg GREEN "✓ Feature Compatibility Version already at 8.0"
    fi
else
    # Fallback to mongo shell if mongosh not available
    msg YELLOW "Using legacy mongo shell..."
    mongo --quiet --eval 'db.adminCommand({ setFeatureCompatibilityVersion: "8.0" })' 2>/dev/null && \
        msg GREEN "✓ Feature Compatibility Version set to 8.0" || \
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
