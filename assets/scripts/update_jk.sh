#!/bin/bash

jk_conf="/data/jackett/config/Jackett/ServerConfig.json"

echo "*/5 * * * * /opt/scripts/update_jk.sh" > /opt/tv.cron

if [[ -f $jk_conf ]]; then
    api_key=`jq -r .APIKey < $jk_conf`

    test -f "/tmp/$api_key" && exit 0

    sed -i 's/jk_api = ".*"/jk_api = "'$api_key'"/g' /var/www/html/scripts/stuff.js

    list() { l=`echo $@ | sed 's/,/" "/g'`; echo "(\"$l\")"; }
    eval FEEDS=`list $RSS_FEED`
    eval OPTS=`list $TV_OPTS`

    for i in "${!FEEDS[@]}"; do
        feed="${FEEDS[$i]}"
        opts="${OPTS[$i]} -api $api_key"
        test -n "$AUTH_USER" && opts="$opts -auth $AUTH_USER:$AUTH_PASS"
        test -n "$feed" && echo "30 4 * * * /usr/local/bin/tivo -feed $feed $opts" >> /opt/tv.cron
    done

    touch "/tmp/$api_key"
fi

crontab /opt/tv.cron
