#!/bin/ash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java version
printf "\033[1m\033[33mcontainer@gameservertech~ \033[0mjava -version\n"
java -version


# Print Python version
if command -v python >/dev/null 2>&1
then
	printf "\033[1m\033[33mcontainer@gameservertech~ \033[0mpython --version\n"
	python --version
else
	printf "\033[1m\033[33mcontainer@gameservertech~ \033[0mpython3 --version\n"
	python3 --version
fi

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@gameservertech~ \033[0m%s\n" "$MODIFIED_STARTUP"
# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi

