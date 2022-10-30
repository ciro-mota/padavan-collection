#!/bin/sh

## Variables
sddns="your-site-name-duckdns" # Only sitename, without domain.
ddns="your-site.duckdns.org" # Without https://.
token="your-token-here"
pathcrt="/home/admin/.acme.sh"

## Update DDNS
/opt/bin/wget --no-check-certificate -O - -o /opt/home/admin/duck.log "https://www.duckdns.org/update?domains=$sddns&token=$token&ip="

## Download ACME
/opt/bin/curl -fsSL https://get.acme.sh | sh 2>&1 /dev/null

## Cert Generate
/opt/home/admin/.acme.sh/acme.sh --insecure --uninstall-cronjob --server letsencrypt --issue --dns dns_duckdns -d $ddns 2> /dev/null

## Copy Cert Files
cp $pathcrt/$ddns/$ddns.key /etc/storage/https/server.key
cp $pathcrt/$ddns/$ddns.cer /etc/storage/https/server.crt
cp $pathcrt/$ddns/fullchain.cer /etc/storage/https/ca.crt

## Restart httpd Service
kill "$(pgrep httpd)" 2> /dev/null

## Save Configs
mtd_storage.sh save

## Write results on the log.
logger -t rstats "SSL Cert has updated."
