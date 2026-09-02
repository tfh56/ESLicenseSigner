#!/bin/bash
# Install signed license to Elasticsearch

set -e
cd "$(dirname "$0")"

ES_HOST=${ES_HOST:-127.0.0.1}
ES_PORT=${ES_PORT:-9200}
[ -z $ES_PASSWORD -a -z ES_TOKEN ] && echo "Warning: no ES_PASSWORD or ES_TOKEN, try changme password." 
ES_PASSWORD=${ES_PASSWORD:-changme}

if [ ! -f "signed-license.json" ]; then
    echo "Error: signed-license.json not found. Run ./sign.sh first."
    exit 1
fi

echo "Installing license to Elasticsearch (https://${ES_HOST}:${ES_PORT})..."

curl -k -X PUT -u elastic:$ES_PASSWORD "https://${ES_HOST}:${ES_PORT}/_license" \
  -H 'Content-Type: application/json' \
  ${ES_TOKEN:+-H "Authorization: Bearer $ES_TOKEN"} \
  -d @signed-license.json

echo ""
echo "License installed successfully!"
echo "Verify with: curl -k -u elastic:$ES_PASSWORD https://${ES_HOST}:${ES_PORT}/_license"
