#!/bin/bash

################################################################################################
# A script to run the Curity Identity Server with mobile DCR settings configured and a test user
################################################################################################

#
# First check prerequisites
#
if [ ! -f './idsvr/license.json' ]; then
  echo "Please provide a license.json file in the deployment/idsvr folder in order to deploy the system"
  exit 1
fi

#
# This is for Curity developers only, to prevent accidental checkins of license files
#
cp ./hooks/pre-commit ./.git/hooks

#
# Spin up ngrok, to get a trusted SSL internet URL for the Identity Server that mobile apps or simulators can connect to
#
kill -9 $(pgrep ngrok) 2>/dev/null
ngrok http 8443 -log=stdout &
sleep 5
export NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto == "https") | .public_url')
if [ "$NGROK_URL" == "" ]; then
  echo "Problem encountered getting an NGROK URL"
  exit 1
fi

#
# Next deploy the Curity Identity server
#
cd idsvr
docker compose up --detach --force-recreate
if [ $? -ne 0 ]; then
  echo "Problem encountered starting Docker components"
  exit 1
fi

#
# Update the mobile app's configuration file to use the NGROK URL
#
DISCOVERY_URL="$NGROK_URL/oauth/v2/oauth-anonymous/.well-known/openid-configuration"
MOBILE_CONFIG=$(cat ./app/config.json)
echo $MOBILE_CONFIG | jq --arg i "$DISCOVERY_URL" '.issuer = $i' > ./app/config.json

#
# Also output the URL, which can be useful to grab for development purposes
#
echo "Identity Server is running at $DISCOVERY_URL"
