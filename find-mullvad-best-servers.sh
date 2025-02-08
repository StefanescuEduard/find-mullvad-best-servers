#!/bin/bash

API_URL="https://api.mullvad.net/www/relays/wireguard"

FQDNS=$(curl -s "$API_URL" | jq -r '.[].fqdn')

TOTAL_SERVERS=$(echo "$FQDNS" | wc -l)

RESULTS_FILE="./ping_results/$(date +"%Y-%m-%d_%H-%M-%S").log"
echo "Saving results to $RESULTS_FILE"

touch "$RESULTS_FILE"

process_fqdn() {
    fqdn=$1
    PING_TIME=$(ping -c 3 -W 5 "$fqdn" | awk -F'/' '/^rtt/ {print $5}')
    DDATA=$(curl -s "$API_URL" | jq -r ".[] | select(.fqdn == \"$fqdn\").daita")
    
    if [[ -n "$PING_TIME" ]]; then
        echo "$PING_TIME $fqdn $DDATA" >> "$RESULTS_FILE"
    else
        echo "9999 $fqdn $DDATA" >> "$RESULTS_FILE"
    fi
}

for fqdn in $FQDNS; do
    process_fqdn "$fqdn" &
done

wait

echo "Best 5 servers where daita=false:"
grep -v '^9999' "$RESULTS_FILE" | grep 'false' | sort -n | head -5

echo "Best 5 servers where daita=true:"
grep -v '^9999' "$RESULTS_FILE" | grep 'true' | sort -n | head -5

