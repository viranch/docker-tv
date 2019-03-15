#!/bin/bash

if [[ -n "$AUTH_USER" ]]; then
    echo $AUTH_PASS | htpasswd -ic /etc/apache2/htpasswd $AUTH_USER
    cat << EOF > /etc/apache2/conf-enabled/auth.conf
# protect directory listing & reverse proxy requests with basic auth
<Location />
    AuthType Basic
    AuthName "By Invitation Only"
    AuthUserFile /etc/apache2/htpasswd
    Require valid-user
</Location>

# don't enforce auth on files for download convenience
<LocationMatch /downloads/.*[^/]$>
    Require all granted
</LocationMatch>
EOF
fi

mkdir -p /data/{transmission,watch,downloads}
test ! -f /data/transmission/settings.json && cp /opt/transmission.json /data/transmission/settings.json
test ! -L /var/www/html/downloads && ln -s /{data,var/www/html}/downloads

cron_file="/tmp/tv.cron"
echo "*/5 * * * * /opt/scripts/update_jk.sh" > $cron_file
if [[ -n "$RSS_FEED" ]]; then
    opts="-seen /data/tivo.seen"
    test -n "$AUTH_USER" && opts="-auth $AUTH_USER:$AUTH_PASS $opts"
    echo "*/10 * * * * /usr/local/bin/tivo -feed $RSS_FEED $opts" >> $cron_file
fi
crontab $cron_file

mkdir -p /data/jackett/config
/opt/scripts/update_jk.sh

exec "$@"
