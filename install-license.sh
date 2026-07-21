#!/bin/bash
# Install signed license to Elasticsearch

set -e

cd "$(dirname "$0")"

ES_HOST="${ES_HOST:-localhost}"
ES_PORT="${ES_PORT:-9200}"

if [ ! -f "signed-license.json" ]; then
    echo "Error: signed-license.json not found. Run ./sign.sh first."
    exit 1
fi

echo "Installing license to Elasticsearch (${ES_HOST}:${ES_PORT})..."

curl -X PUT "${ES_HOST}:${ES_PORT}/_license" \
  -H 'Content-Type: application/json' \
  -d @signed-license.json

echo ""
echo "License installed successfully!"
echo "Verify with: curl ${ES_HOST}:${ES_PORT}/_license"
