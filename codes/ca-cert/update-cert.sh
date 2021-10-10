#!/bin/sh

## Variables
ddns="your-domain.duckdns.org"
token="your-token-here"

## Export Token
export DuckDNS_Token="$token"

## Update DDNS
inadyn -a $ddns -u $token --ssl -S default@duckdns.org -i ppp0 -f 0 -V 1 -b -e /sbin/ddns_updated
sleep 10
kill "$(pgrep inadyn)" 2> /dev/null

## Download ACME
curl -fsSL https://get.acme.sh | sh 2>&1 /dev/null

## Cert Generate
/home/admin/.acme.sh/acme.sh --insecure --server letsencrypt --issue --dns dns_duckdns -d $ddns --cert-file /etc/storage/https/server.crt --key-file /etc/storage/https/server.key --ca-file /etc/storage/https/ca.key --fullchain-file /etc/storage/https/ca.crt 2> /dev/null
/home/admin/.acme.sh/acme.sh --uninstall-cronjob 2> /dev/null

## Restart httpd service
kill "$(pgrep httpd)" 2> /dev/null

## Save configs
mtd_storage.sh save

## Write results on the log.
logger -t rstats "SSL Cert has updated."
