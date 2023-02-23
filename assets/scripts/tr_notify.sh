#!/bin/bash

curl https://api.pushover.net/1/messages.json -d "token=$PUSHOVER_APP_TOKEN" -d "user=$PUSHOVER_USER_KEY" -d "title=Transmission ($HOSTNAME)" -d "message=$TR_TORRENT_NAME downloaded"
