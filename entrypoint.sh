#!/bin/bash
set -e

# Ensure we're running as the coder user
if [ "$(id -u)" -eq 0 ]; then
    exec su - coder -c "$0"
fi

# run update apt
sudo apt-get update

# create .profile
if [ ! -f /home/coder/.profile ]; then
    touch /home/coder/.profile
fi


curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash


# Log startup
echo "Starting Coder agent..."
echo "CODER_AGENT_URL: $CODER_AGENT_URL"
echo "CODER_DERP_FORCE_WEBSOCKETS: $CODER_DERP_FORCE_WEBSOCKETS"

# Execute the init script
# The init script will handle downloading and starting the agent
code-server --port 13337