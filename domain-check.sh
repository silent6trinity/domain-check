#!/bin/bash

# Ensure required tools are installed
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
    echo "Usage: $0 -domain <example.com> [-debug]"
    echo ""
    echo "Options:"
    echo "  -domain <domain>    Specify the target domain for subdomain discovery."
    echo "  -debug              Enable debug output (shows failed subdomains)."
    echo "  -h, --help          Show this help message."
    exit 0
}

# Default values
DEBUG_MODE=0
DOMAIN=""

# Parse command-line arguments
if [[ "$#" -eq 0 ]]; then
    usage
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -domain) DOMAIN="$2"; shift ;;
        -debug) DEBUG_MODE=1 ;;  # Enable debug mode
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
    STATUS_CODE=""

    # Try HTTPS first with a 1-second connection timeout
    HTTPS_STATUS=$(curl -s -o /dev/null --connect-timeout 1 --max-time 3 -w "%{http_code}" "https://$subdomain")

    # If HTTPS succeeds (not 000), use it
    if [[ "$HTTPS_STATUS" != "000" ]]; then
        STATUS_CODE=$HTTPS_STATUS
    else
        # Otherwise, fall back to HTTP with a longer timeout
        HTTP_STATUS=$(curl -s -o /dev/null --connect-timeout 3 --max-time 5 -w "%{http_code}" "http://$subdomain")

        # Use HTTP response if it's valid
        if [[ "$HTTP_STATUS" != "000" ]]; then
            STATUS_CODE=$HTTP_STATUS
        fi
    fi

    # If we got a valid status, check if it's 2xx or 3xx
    if [[ "$STATUS_CODE" =~ ^(2|3)[0-9]{2}$ ]]; then
        echo "$subdomain - $STATUS_CODE"
    elif [[ "$DEBUG_MODE" -eq 1 ]]; then
        echo "[DEBUG] $subdomain - No valid response" >&2
    fi
done < "$TEMP_FILE"

# Cleanup
rm "$TEMP_FILE"
