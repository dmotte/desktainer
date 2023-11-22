#!/bin/bash

set -e

bot_token='{{ lognot_bot_token }}'
chat_id='{{ lognot_chat_id }}'

curl -sSXPOST "https://api.telegram.org/bot$bot_token/sendMessage" \
    -dchat_id="$chat_id" --data-urlencode text@- --fail-with-body -w'\n'
