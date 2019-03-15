#!/bin/bash

jk_conf="/data/jackett/config/Jackett/ServerConfig.json"

if [[ -f $jk_conf ]]; then
    api_key=`jq -r .APIKey < $jk_conf`

    test -f "/tmp/$api_key" && exit 0

    sed -i 's/jk_api = ".*"/jk_api = "'$api_key'"/g' /var/www/html/scripts/stuff.js

    touch "/tmp/$api_key"
fi
