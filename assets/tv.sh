#!/bin/bash
#
# Script to download .torrent files for your TV shows as they get aired.
# Requires your customized feed from myrvrss.com with your selected shows.
#
# Run as a daily cron job, downloads shows aired the previous day from now.
# Usage: tv.sh -l <link-to-rss-feed> -o <download-directory>
# Eg: tv.sh -l http://mytvrss.com/tvrss.xml?id=123456 -o ~/Downloads/torrents
#
# Transmission/uTorrent can watch for .torrent files in the download directory.
#

usage() {
    cat << EOF
Usage: $0 -l <link-to-rss-feed> -o <output-directory> [-s <search-suffix>]
EOF
}

link=""
dirpath=""
suff=""
while getopts "l:o:s:h" OPTION; do
    case $OPTION in
        l)
            link="$OPTARG"
            ;;
        o)
            dirpath="$OPTARG"
            ;;
        s)
            suff="$OPTARG"
            ;;
        h)
            usage
            ;;
    esac
done

# validate input link
match=$(echo $link | grep -o "^http://followshows\.com/feed/[^/]\+$")
test -z "$match" && echo "Invalid URL. Please visit followshows.com to generate your personalised URL" && exit 1
test -d "$dirpath" || mkdir -p "$dirpath" 2>/dev/null || (echo "Invalid download path: $dirpath" && exit 2)

function search() {
    curl -s https://torrentz.in/feed?q="$@" | grep "<link>.*$" -o | head -n2 | grep -v "search?q=" | sed 's/<link>http:\/\/torrentz\.in\///g' | sed 's/<\/link>//g'
    #cookie_file="/tmp/surecook"
    #rm -f $cookie_file
    #while [[ ! -f $cookie_file ]]; do curl -s -XHEAD https://www.suresome.com/ -c $cookie_file > /dev/null; done
    #curl -s --compressed https://www.suresome.com/proxy/nph-secure/00A/http/torrentz.in/feed%3fq%3d"$@" -b $cookie_file | grep "<link>.*$" -o | head -n2 | grep -v "search?q=" | sed 's/<link>http:\/\/torrentz\.in\///g' | sed 's/<\/link>//g'
}


function add_torrent() {
    title="$1"
    test -n "$2" && title="$title $2"
    query=`echo "$title" | sed 's/ /+/g' | sed "s/'//g"`
    echo -n "Searching '$title'... "
    hash=$(search $query)
    if [[ -n $hash ]]; then
        echo "found"
        fname="`echo $title | sed 's/ /./g'`.torrent"
        curl -s --compressed http://torcache.net/torrent/$hash.torrent > "$dirpath/$fname"
    else
        echo "failed"
    fi
}

# download .torrent for shows aired today
echo "Getting episode list..."
curl -s $link | grep "<title>\|<dc:date>" | grep `date +%F` -B1 | grep  ">.* S[0-9]\+E[0-9]\+" -o | sed 's/>//g' | sed 's/\s*(.*)//g' | while read title
do
    add_torrent "$title" "$suff"
done
