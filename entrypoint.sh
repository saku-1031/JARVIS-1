#!/bin/bash
set -e

# Start VNC server
vncserver :1 -geometry 1280x720 -depth 24 -rfbport 5901 -securitytypes None
export DISPLAY=:1

# Start window manager
fluxbox &

echo "JARVIS-1 Entrypoint"
echo "VNC server started on port 5901 (no password)"
echo "Connect with a VNC client to localhost:5901"

# OPENAI_API_KEY の確認
if [ -z "$OPENAI_API_KEY" ]; then
  echo "Error: OPENAI_API_KEY is not set"
  exit 1
fi

# Activate conda environment and run the python script
conda run -n jarvis python -u -m jarvis.stark_tech.entry "$@"

# Keep container running for VNC connection
echo "Minecraft process finished. Keeping container alive for VNC access."
tail -f /dev/null