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

function feed() {
    curl -s https://torrentz.in/feed?q="$@"
    #cookie_file="/tmp/surecook"
    #rm -f $cookie_file
    #while [[ ! -f $cookie_file ]]; do curl -s -XHEAD https://www.suresome.com/ -c $cookie_file > /dev/null; done
    #curl -s --compressed https://www.suresome.com/proxy/nph-secure/00A/https/torrentz.in/feed%3fq%3d"$@" -b $cookie_file
}

function search() {
    feed "$@" | grep "<link>.*$" -o | tail -n +2 | sed 's/<link>http:\/\/torrentz\.in\///g' | sed 's/<\/link>//g'
}

function get_torrent() {
    test `curl -s --compressed $1 -o $2 -D - | head -n1 | cut -d' ' -f2` -eq 200
}

function add_torrent() {
    title="$1"
    test -n "$2" && title="$title $2"
    query=`echo "$title" | sed 's/ /+/g' | sed "s/'//g"`
    echo -n "Searching '$title'... "
    status="failed"
    for hash in `search $query`; do
        fname="`echo $title | sed 's/ /./g'`.torrent"
        get_torrent http://torcache.net/torrent/$hash.torrent "$dirpath/$fname"
        if [[ $? == 0 ]]; then
            status="found"
            break
        fi
    done
    echo $status
}

# download .torrent for shows aired today
echo "Getting episode list..."
curl -s $link | grep "<title>\|<dc:date>" | grep `date +%F` -B1 | grep  ">.* S[0-9]\+E[0-9]\+" -o | sed 's/>//g' | sed 's/\s*(.*)//g' | while read title
do
    add_torrent "$title" "$suff"
done
