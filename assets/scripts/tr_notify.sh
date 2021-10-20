#!/bin/bash

curl https://api.pushbullet.com/v2/pushes -H 'Content-Type: application/json' -H "Access-Token: $PB_TOKEN" -d @- << EOF
{
  "title": "Transmission ($HOSTNAME)",
  "body": "$TR_TORRENT_NAME downloaded",
  "type": "note"
}
EOF
