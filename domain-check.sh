#!/bin/bash

# Ensure required tools are installed, if not - bail
if ! command -v assetfinder &> /dev/null; then
    echo "Error: assetfinder is not installed. Install it using: go install github.com/tomnomnom/assetfinder@latest"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Install it using: sudo apt install curl (Linux) or brew install curl (Mac)"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 -domain <example.com>"
    echo ""
    echo "Options:"
    echo "  -domain <domain>    Specify the target domain for subdomain discovery."
    echo "  -h, --help          Show this help message."
    exit 0
}

# Parse command-line arguments
if [[ "$#" -eq 0 ]]; then
    usage
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -domain) DOMAIN="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# Check if domain is provided
if [[ -z "$DOMAIN" ]]; then
    echo "Error: No domain specified."
    usage
fi

# Temporary file for subdomains
TEMP_FILE=$(mktemp)

echo "[*] Finding subdomains for: $DOMAIN"

# Find unique subdomains
assetfinder --subs-only "$DOMAIN" | sort -u > "$TEMP_FILE"

echo "[*] Checking HTTP/HTTPS status codes..."
while read -r subdomain; do
    # Try HTTPS first with a 1-second connection timeout
    STATUS_CODE=$(curl -s -o /dev/null --connect-timeout 1 --max-time 2 -w "%{http_code}" "https://$subdomain")

    # If HTTPS fails (000), try HTTP with a standard timeout
    if [[ "$STATUS_CODE" -eq 000 ]]; then
        STATUS_CODE=$(curl -s -o /dev/null --connect-timeout 2 --max-time 3 -w "%{http_code}" "http://$subdomain")
    fi

    # Only show 2xx or 3xx responses
    if [[ "$STATUS_CODE" =~ ^(2|3)[0-9]{2}$ ]]; then
        echo "$subdomain - $STATUS_CODE"
    fi
done < "$TEMP_FILE"

# Cleanup
rm "$TEMP_FILE"
