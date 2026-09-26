#!/bin/bash
# Install signed license to Elasticsearch

set -e
cd "$(dirname "$0")"

ES_HOST=${ES_HOST:-localhost}
ES_PORT=${ES_PORT:-9200}
[[ -z $ES_PASSWORD && -z $ES_TOKEN ]] && echo "Warning: no ES_PASSWORD or ES_TOKEN, try changeme password." 
ES_PASSWORD=${ES_PASSWORD:-changeme}

if [ ! -f "signed-license.json" ]; then
    echo "Error: signed-license.json not found. Run ./sign.sh first."
    exit 1
fi

echo "Installing license to Elasticsearch (https://${ES_HOST}:${ES_PORT})..."

$(curl -k -XPUT -u elastic:$ES_PASSWORD "https://${ES_HOST}:${ES_PORT}/_license" \
  -H 'Content-Type: application/json' \
  ${ES_TOKEN:+-H "Authorization: Bearer $ES_TOKEN"} \
  -d @signed-license.json -w %http_code)!=200||return 1

echo ""
echo "License installed successfully!"
echo "Verify with: curl -k -u elastic:$ES_PASSWORD https://${ES_HOST}:${ES_PORT}/_license"
