#!/bin/bash
set -e

echo "Starting Coder agent..."

# The agent token and URL are passed via environment variables
# CODER_AGENT_TOKEN and CODER_AGENT_URL

# Start the Coder agent in the background
coder agent > /tmp/coder-agent.log 2>&1 &

echo "Coder agent started"

# Keep container alive
tail -f /tmp/coder-agent.log