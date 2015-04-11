#!/bin/bash

chown -R transmission: /srv/http

mkdir -p /etc/systemd/system/transmission.service.d
cat << EOF > /etc/systemd/system/transmission.service.d/env.conf
[Service]
Environment="EMAIL=$EMAIL"
EOF

exec /usr/bin/init
