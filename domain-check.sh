#!/bin/bash
# Empty array
errors=()
i=0

while IFS='' read -r line || [[ -n "$line" ]]; do
  # Increment the variable  
  ((i++))

  # Skip if offset if specified and current index less than it
  if [[ "$2" && $i -lt "$2" ]]; then
    continue
  fi

#  echo "[${i}] Doing $line"
  statusCode=$(curl -m 3 -s -o /dev/null -I -w "%{http_code}" $line)
  if [[ "$statusCode" = 2* || "$statusCode" = 3* ]]; then
    echo "$line: $statusCode"
    errors+=("[${statusCode}] ${line}")
  fi

  sleep 2
done < "$1"

echo "---------------"
errorsCount=${#errors[@]}
echo "Found $errorsCount errors."

if (( $errorsCount > 0 )); then
  printf '%s\n' "${errors[@]}"
fi
