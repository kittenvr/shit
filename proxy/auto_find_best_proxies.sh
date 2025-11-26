#!/usr/bin/env bash
# auto_find_best_proxies.sh
# Finds proxies, sorts by ping, saves top 5

LIMIT=10
OUTDIR="/tmp/proxy_tests"
mkdir -p "$OUTDIR"
BEST_FILE="/data/best_proxies.txt"
> "$BEST_FILE"

MY_COUNTRY=$(curl -s --max-time 3 https://ipinfo.io/country || true)
[[ -z "$MY_COUNTRY" ]] && MY_COUNTRY="US"

declare -A REGION_MAP=(
    [BE]="BE NL FR DE LU GB CH AT IT ES DK SE"
)

if [[ -n "${REGION_MAP[$MY_COUNTRY]:-}" ]]; then
    COUNTRIES=(${REGION_MAP[$MY_COUNTRY]})
else
    COUNTRIES=($MY_COUNTRY US GB DE FR SG AU)
fi

# Fetch proxies in parallel
for COUNTRY in "${COUNTRIES[@]}"; do
    OUTFILE="$OUTDIR/proxies_${COUNTRY}.txt"
    : > "$OUTFILE"
    proxybroker2 find --types SOCKS4 SOCKS5 --limit "$LIMIT" --countries "$COUNTRY" --outfile "$OUTFILE" >/dev/null 2>&1 &
done
wait

check_proxy() {
    COUNTRY="$1"
    OUTFILE="$OUTDIR/proxies_${COUNTRY}.txt"
    [[ ! -s "$OUTFILE" ]] && return
    while IFS= read -r line; do
        if [[ $line =~ \[([^\]]+)\][[:space:]]([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+ ]]; then
            TYPES="${BASH_REMATCH[1]}"
            if [[ $line =~ ([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+ ]]; then
                PROXY="${BASH_REMATCH[0]}"
            else
                continue
            fi
            if [[ $TYPES == *"SOCKS5"* ]]; then
                CHOSEN_TYPE="SOCKS5"
            elif [[ $TYPES == *"SOCKS4"* ]]; then
                CHOSEN_TYPE="SOCKS4"
            else
                CHOSEN_TYPE=$(echo "$TYPES" | sed 's/,.*//; s/ //g')
            fi
            HOST=${PROXY%%:*}
            PING_MS=$(ping -c 2 -W 1 -q "$HOST" 2>/dev/null | awk -F'/' '/avg/ {print $5}')
            [[ -z "$PING_MS" ]] && continue
            printf '%s|%s|%s|%s\n' "$PING_MS" "$COUNTRY" "$PROXY" "$CHOSEN_TYPE"
        fi
    done < "$OUTFILE"
}

export -f check_proxy
export OUTDIR

RESULTS=$(printf "%s\n" "${COUNTRIES[@]}" | xargs -n1 -P "$(nproc)" bash -c 'check_proxy "$0"' 2>/dev/null || true)
if [[ -z "$RESULTS" ]]; then
    echo "[!] No reachable proxies found"
    exit 1
fi

# Save top 5
echo "$RESULTS" | sort -n -t'|' -k1 | head -n5 | awk -F'|' '{print $3" ("$1" ms, "$2", "$4")"}' > "$BEST_FILE"
echo "[*] Top 5 proxies saved to $BEST_FILE"
