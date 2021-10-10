#!/bin/sh
PATH=/opt/sbin:/opt/bin:/opt/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


# 0.0.0.0 It is defined as a non-routable address used to designate an invalid, unknown, or inapplicable destination. In addition to being faster empirically, possibly because there is no waiting for a timeout resolution.
ENDPOINT_IP4="0.0.0.0"
ENDPOINT_IP6="::"
TMPDIR="/tmp/block.build.list"
STGDIR="/tmp/block.build.before"
TARGET="/tmp/block.hosts"
DLIST="/etc/storage/adblock_deny.list"
ALIST="/etc/storage/adblock_allow.list"

# Download your block lists. They should be used in hosts format. Use wisely, not always many lists will yield a better result:
wget -U "Mozilla/5.0 (X11; Linux x86_64; rv:93.0) Gecko/20100101 Firefox/93.0" -qO- "https://block.energized.pro/spark/formats/hosts.txt" | awk -vr="$ENDPOINT_IP4" '{sub(/^0.0.0.0/, r)} $0 ~ "^"r' >> "$TMPDIR"
wget -U "Mozilla/5.0 (X11; Linux x86_64; rv:93.0) Gecko/20100101 Firefox/93.0" -qO- "https://block.energized.pro/spark/formats/hosts-ipv6.txt" | awk -vr="$ENDPOINT_IP6" '{sub(/^::/, r)} $0 ~ "^"r' >> "$TMPDIR"


# Add blacklist, if non-empty
if [ -s "$DLIST" ]
then
awk -v r="$ENDPOINT_IP4" '/^[^#]/ { print r,$1 }' "$DLIST" >> "$TMPDIR"
fi

# Sort the download/black lists
awk '{sub(/\r$/,"");print $1,$2}' "$TMPDIR" | sort -u > "$STGDIR"

# Filter (if applicable)
if [ -s "$ALIST" ]
then
# Filter the blacklist, suppressing whitelist matches
# This is relatively slow
grep -E -v "^[[:space:]]*$" "$ALIST" | awk '/^[^#]/ {sub(/\r$/,"");print $1}' | grep -vf - "$STGDIR" > "$TARGET"
else
cat "$STGDIR" > "$TARGET"
fi

# Delete files used to build list to free up the limited space
rm -f "$TMPDIR"
rm -f "$STGDIR"

killall -SIGHUP dnsmasq
