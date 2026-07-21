#!/bin/bash
# Sign Elasticsearch license

set -e

cd "$(dirname "$0")"
ES_HOME=${ES_HOME:-/usr/share/elasticsearch}

# Find Elasticsearch modules for classpath
ES_MODULES=$(find ${ES_HOME}/lib ${ES_HOME}/modules/x-pack-core -name "*.jar" 2>/dev/null | tr '\n' ':' || echo "")

if [ -z "$ES_MODULES" ]; then
    echo "Error: Cannot find Elasticsearch modules. Please setup env ES_HOME."
    echo "Current ES path searched from: ${ES_HOME}"
    exit 1
fi

#echo "Compiling ESLicenseSigner.java..."
javac -cp ".:${ES_MODULES}" ESLicenseSigner.java

echo "Signing license.json..."
${ES_HOME}/jdk/bin/java -cp ".:${ES_MODULES}" ESLicenseSigner license.json private.key signed-license.txt

echo ""
echo "Creating signed-license.json for ES API..."
escaped_signature=$(sed 's@/@\\/@g' signed-license.txt)
if grep -q '"signature":' license.json; then
    sed 's/\("signature": \?\)"[^"]*"/\1"'"$escaped_signature"'"/g' license.json > signed-license.json
else
    sed -e 's/\("start_date_in_millis":[0-9]\+\)/\1,"signature":"'"$escaped_signature"'"/' -e 's/\("start_date_in_millis": \+[0-9]*\)/\1,\n    "signature": "'"$escaped_signature"'"/' license.json > signed-license.json
fi

echo ""
echo "Update public.key to validate signed license ..."
${ES_HOME}/jdk/bin/jar -uvf ${ES_HOME}/modules/x-pack-core/x-pack-core-[0-9]*[0-9].jar public.key

echo "Done! Files created:"
echo "  - signed-license.txt (base64 encoded signed license)"
echo "  - signed-license.json (ready for ES API)"
echo ""
echo "To install the license:"
echo "  curl -X PUT localhost:9200/_license -H 'Content-Type: application/json' -d @signed-license.json"
