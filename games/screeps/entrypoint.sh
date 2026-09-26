#!/bin/bash
#Variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

#show versions
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Screeps Installation${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}MongoDB Version:${NC} " && mongod --version
echo -e "${YELLOW}Redis Version:${NC} " && redis-server --version
echo -e "${YELLOW}NodeJS Version:${NC} " && node -v
echo -e "${YELLOW}NPM Version:${NC} " && npm -v
#echo -e "${YELLOW}Java Version:${NC} " && java -version
echo -e "${YELLOW}Linux Distribution: ${RED} $(. /etc/os-release ; echo $PRETTY_NAME)${NC}"
echo -e "${YELLOW}Current timezone:${NC} " && ([ -f /etc/timezone ] && cat /etc/timezone || echo "${TZ:-UTC}")
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

cd /home/container

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e "${YELLOW}:/home/container${NC} ${MODIFIED_STARTUP}"

# start mongo
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}starting MongoDB...${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
mongod --fork --dbpath /home/container/mongodb/ --port 27017 --logpath /home/container/mongod.log --logRotate reopen --logappend && until nc -z -v -w5 127.0.0.1 27017; do echo 'Waiting for mongodb connection...'; sleep 5; done

# Run the Server
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}starting Screeps Server${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
trap "mongod --shutdown" EXIT INT TERM
exec bash -c "${MODIFIED_STARTUP}"

