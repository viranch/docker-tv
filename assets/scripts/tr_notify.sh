#!/bin/bash

curl https://api.pushover.net/1/messages.json -d @- <<EOF
{
  "token": "$PUSHOVER_APP_TOKEN",
  "user": "$PUSHOVER_USER_KEY",
  "title": "Transmission ($HOSTNAME)",
  "message": "$TR_TORRENT_NAME downloaded"
}
EOF
