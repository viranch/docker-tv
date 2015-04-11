#!/bin/bash

echo | mail -S smtp=$(dig +short mx `echo $EMAIL | cut -d'@' -f2` | head -n1 | cut -d' ' -f2) -r tv@home -s "$TR_TORRENT_NAME downloaded" $EMAIL
