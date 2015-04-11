#!/bin/bash

mkdir -p /data/{transmission,watch,downloads}
cp /opt/transmission.json /data/transmission/settings.json
ln -s /data/downloads /srv/http/downloads

python2 -c "for feed,opt in zip('$RSS_FEED'.split(','), '$TV_OPTS'.split(',')): print feed+','+opt" | while read s; do
    feed=`echo $s | cut -d',' -f1`
    opts=`echo $s | cut -d',' -f2`
    echo "30 4 * * * /opt/scripts/tv.sh -l $feed -o /opt/watch $opts" >> /tmp/tv.cron
done
crontab /tmp/tv.cron

exec /usr/bin/init
