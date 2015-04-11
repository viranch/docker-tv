#!/bin/bash

mkdir -p /data/{transmission,watch,downloads}
cp /opt/transmission.json /data/transmission/settings.json
ln -s /data/downloads /srv/http/downloads

mkdir -p /etc/systemd/system/transmission.service.d
cat << EOF > /etc/systemd/system/transmission.service.d/env.conf
[Service]
User=root
Environment="EMAIL=$EMAIL"
ExecStart=
ExecStart=/usr/bin/transmission-daemon -f -g /data/transmission
EOF

python2 -c "for feed,opt in zip('$RSS_FEED'.split(','), '$TV_OPTS'.split(',')): print feed+','+opt" | while read s; do
    feed=`echo $s | cut -d',' -f1`
    opts=`echo $s | cut -d',' -f2`
    cat << EOF >> /tmp/tv.cron
30 4 * * * /opt/scripts/tv.sh -l $feed -o /opt/watch $opts
EOF
done
crontab /tmp/tv.cron

exec /usr/bin/init
