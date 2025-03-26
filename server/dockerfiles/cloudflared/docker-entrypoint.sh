#!/bin/sh
set -e

# Substitute environment variables in the Cloudflared config template and write to a temporary file
envsubst '$WILDCARD_DOMAIN $TUNNEL_ID' < /etc/cloudflared/config.yml.template > /tmp/config.yml

# Start the Cloudflared tunnel using the generated configuration file
exec tunnel --config /tmp/config.yml run