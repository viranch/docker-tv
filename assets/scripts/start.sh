#!/bin/bash

mkdir -p /data/{transmission,watch,downloads}
cp /opt/transmission.json /data/transmission/settings.json
test ! -L /srv/http/downloads && ln -s /data/downloads /srv/http/downloads
test -n "$EMAIL" && echo Environment="EMAIL=$EMAIL" >> /etc/systemd/system/transmission.service.d/custom.conf

list() { l=`echo $@ | sed 's/,/" "/g'`; echo "(\"$l\")"; }
eval FEEDS=`list $RSS_FEED`
eval OPTS=`list $TV_OPTS`

rm -f /opt/tv.cron
for i in "${!FEEDS[@]}"; do
    feed="${FEEDS[$i]}"
    opts="${OPTS[$i]}"
    echo "30 4 * * * /opt/scripts/tv.sh -l $feed -o /data/watch $opts" >> /opt/tv.cron
done
crontab /opt/tv.cron

exec /usr/bin/init
