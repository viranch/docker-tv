#!/bin/bash

test -n "$EMAIL" && echo | mail -S smtp=$(dig +short mx `echo $EMAIL | cut -d'@' -f2` | head -n1 | cut -d' ' -f2) -r tv@`hostname` -s "$TR_TORRENT_NAME downloaded" $EMAIL
