# Elasticsearch License Signer

Simplified tool for generating and signing Elasticsearch licenses.

## Quick Start

### 1. Generate Keys
```bash
./gen-keys.sh
```
Creates `private.key` and `public.key` in this directory.

### 2. Edit License
Edit `license.json` with your desired license details:
- `uid`: Unique identifier
- `type`: `basic`, `gold`, `platinum`, or `enterprise`
- `issue_date_in_millis`: Issue date (Unix timestamp in milliseconds)
- `expiry_date_in_millis`: Expiry date (Unix timestamp in milliseconds)
- `issuer`: Issuer name
- `issued_to`: License recipient
- `max_nodes`: Maximum number of nodes,not available in enterprise license
- `max_resource_units`: Maximum resource units

### 3. Sign License
```bash
./sign.sh
```
This compiles the Java signer and creates:
- `signed-license.txt` - Base64 encoded signed license
- `signed-license.json` - Ready for ES API

### 4. Install License
```bash
./install-license.sh
```
Or manually,note ES password/token:
```bash
curl -X PUT localhost:9200/_license \
  -H 'Content-Type: application/json' \
  -d @signed-license.json
```

### 5. Verify,note password/token.
```bash
curl localhost:9200/_license
```

## Manual Steps (if needed)

### Update Public Key in ES JAR
If you need to replace the public key in Elasticsearch:

```bash
# Stop Elasticsearch
sudo systemctl stop elasticsearch
# Start Elasticsearch
sudo systemctl start elasticsearch
```

## File Structure

```
/tmp/ES-License-Signer/
├── ESLicenseSigner.java    # Main signing program
├── gen-keys.sh             # Generate RSA key pair
├── sign.sh                 # Compile and sign license
├── install-license.sh      # Install license to ES
├── license.json            # License template (edit this)
├── private.key             # RSA private key (generated)
├── public.key              # RSA public key (generated)
├── signed-license.txt      # Output: signed license
├── signed-license.json     # Output: ES API format
├── MulanPSL                # Repostory license
└── README.md               # This file
```

## Notes

- **ES authorization**: curl need user/password option or token header in security mode.
- **Private Key Format**: PKCS8 (unencrypted)
- **Signature Algorithm**: SHA512withRSA
- **License Version**: Enterprise (VERSION_ENTERPRISE)
- **Public Key Fingerprint**: SHA256 hash

## Troubleshooting

### Cannot find Elasticsearch modules
Update the `ES_HOME` path in `sign.sh` to match your ES installation:
```bash
export ES_HOME=/path/to/elasticsearch
```

### License validation
Restart ES

### Permission denied
Run scripts with appropriate permissions:
```bash
chmod +x *.sh
```

## License
Copyright (c) [2019] [Pengcheng Libortory @Wuxi Onetech Co.,Ltd.]
[ESLicenseSigner] is licensed under the Mulan PSL v1.
You can use this software according to the terms and conditions of the MulanPSL v1.
