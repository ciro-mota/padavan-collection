#!/bin/sh

API_TOKEN=''
CHAT_ID=''
NAME="<b>$HOSTNAME</b>"
V4=$(nvram get wan0_ipaddr)
TELEGRAM=$(echo -n $NAME": WAN Up, IP: " ; echo $V4)

if [ -z "$CHAT_ID" ]; then
    echo 'Please, define CHAT_ID first! See "chat":{"id":xxxxxxx string below:'
    /usr/bin/wget -qO - https://api.telegram.org/bot$API_TOKEN/getUpdates
    exit 1
fi

wget -q --no-hsts --spider "https://api.telegram.org/bot$API_TOKEN/sendMessage?chat_id=$CHAT_ID&parse_mode=html&disable_web_pag"

if [ $? -eq 0 ]; then
    logger -t rstats "Message sent successfully."
else
    logger -t rstats "Error while sending message!"
    exit 1
fi