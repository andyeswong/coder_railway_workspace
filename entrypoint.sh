#!/bin/bash
set -e

# Ensure we're running as the coder user
if [ "$(id -u)" -eq 0 ]; then
    exec su - coder -c "$0"
fi

# Log startup
echo "Starting Coder agent..."
echo "CODER_AGENT_URL: $CODER_AGENT_URL"
echo "CODER_DERP_FORCE_WEBSOCKETS: $CODER_DERP_FORCE_WEBSOCKETS"

# Execute the init script
# The init script will handle downloading and starting the agent
eval "$(code-server --no-auth --port 13337)"