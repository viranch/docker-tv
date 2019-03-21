#!/bin/bash -e

FEED=$1
SEEN_FILE=$2
REMOTE=$3

test -z "$SEEN_FILE" && SEEN_FILE="$HOME/.config/tivo.seen"
test -z "$REMOTE" && REMOTE="http://127.0.0.1:9091"

mkdir -p `dirname $SEEN_FILE`
test -f $SEEN_FILE || touch $SEEN_FILE

TR_SESSION=`curl -so/dev/null -D- "$REMOTE/transmission/rpc" | grep -iF 'X-Transmission-Session-Id:' | cut -d':' -f2 | sed 's/\r//g'`

curl -sL $FEED | xmllint --format - | grep -F '<link>magnet:' | grep -vFf $SEEN_FILE | while read line; do
    link=`echo $line | cut -d'>' -f2 | cut -d'<' -f1 | sed 's/&amp;/\&/g'`
    curl -s "$REMOTE/transmission/rpc" -H "X-Transmission-Session-Id:$TR_SESSION" -d '{"method": "torrent-add", "arguments": {"filename": "'$link'"}}' -D-
    echo $link | grep -o '[A-Z0-9]\{40\}' >> $SEEN_FILE
done
