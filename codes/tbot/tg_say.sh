#!/bin/sh

API_TOKEN=''
CHAT_ID=''

if [ -z "$CHAT_ID" ]; then
    echo 'Please, define CHAT_ID first! See "chat":{"id":xxxxxxx string below:'
    wget -qO - https://api.telegram.org/bot$API_TOKEN/getUpdates
    exit 1
fi

MSG="<b>$(nvram get computer_name)</b>: $@"

wget -q --spider "https://api.telegram.org/bot$API_TOKEN/sendMessage?chat_id=$CHAT_ID&parse_mode=html&text=$MSG" 2>&1

if [ $? -eq 0 ]; then
    logger -t rstats "Message sent successfully."
else
    logger -t rstats "Error while sending message!"
    exit 1
fi