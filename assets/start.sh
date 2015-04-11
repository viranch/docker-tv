#!/bin/bash

mkdir -p /data/{transmission,watch,downloads}
cp /opt/transmission.json /data/transmission/settings.json
ln -s /data/downloads /srv/http/downloads

list() { l=`echo $@ | sed 's/,/" "/g'`; echo "(\"$l\")"; }
eval FEEDS=`list $RSS_FEED`
eval OPTS=`list $TV_OPTS`

for i in "${!FEEDS[@]}"; do
    feed="${FEEDS[$i]}"
    opts="${OPTS[$i]}"
    echo "30 4 * * * /opt/scripts/tv.sh -l $feed -o /opt/watch $opts" >> /tmp/tv.cron
done
crontab /tmp/tv.cron

exec /usr/bin/init
