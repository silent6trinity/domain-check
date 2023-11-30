#!/bin/bash

# Check if a file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <subdomains_file>"
    exit 1
fi

file="$1"

# Check if the file exists
if [ ! -f "$file" ]; then
    echo "File not found: $file"
    exit 1
fi

# Iterate through each line in the file
while IFS= read -r subdomain; do
    # Sending a web request to each subdomain with a 5-second timeout
    status_code=$(curl -m 5 -o /dev/null -s -w "%{http_code}" "$subdomain")

    # Output the URL and the status code
    echo "$subdomain - $status_code"
done < "$file"
