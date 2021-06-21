#!/bin/sh

API_TOKEN=''
CHAT_ID=''

if [ -z "$CHAT_ID" ]; then
    echo 'Please, define CHAT_ID first! See "chat":{"id":xxxxxxx string below:'
    /usr/bin/wget -qO - https://149.154.167.220:443/bot$API_TOKEN/getUpdates
    exit 1
fi

MSG="<b>$(nvram get computer_name)</b>: $@"

/usr/bin/wget -qs "https://149.154.167.220:443/bot$API_TOKEN/sendMessage?chat_id=$CHAT_ID&parse_mode=html&text=$MSG" 2>&1

if [ $? -eq 0 ]; then
    echo 'Message sent successfully.'
else
    echo 'Error while sending message!'
    exit 1
fi
