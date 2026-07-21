#!/bin/bash
# Generate RSA key pair for Elasticsearch license signing

set -e

cd "$(dirname "$0")"

echo "Generating RSA key pair..."

# Generate private key (PKCS8 format)
openssl genrsa -out private.key 2048

# Extract public key
openssl rsa -in private.key -pubout -outform der -out public.key

echo "Keys generated:"
echo "  - private.key (PKCS8 RSA private key)"
echo "  - public.key (RSA public key)"
echo ""
echo "Next steps:"
echo "  1. Edit license.json with your license details"
echo "  2. Run: ./sign.sh"
echo "  3. Update ES license: curl -X PUT localhost:9200/_license -H 'Content-Type: application/json' -d @signed_license.json"
