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
Usage: $0 -l <link-to-rss-feed> -o <output-directory> [-s <search-suffix>] [-d <date options, similar to '-d' switch to date command>] [-p use proxy for HTTP requests. Default: off]
EOF
}

link=""
dirpath=""
suff=""
date_opts="-d now"
use_proxy=0
while getopts "l:o:s:d:h" OPTION; do
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
        d)
            date_opts="-d $OPTARG"
            ;;
        p)
            use_proxy=1
            ;;
        h)
            usage
            exit 0
            ;;
    esac
done

# validate input link
match=$(echo $link | grep -o "^http://followshows\.com/feed/[^/]\+$")
test -z "$match" && echo "Invalid URL. Please visit followshows.com to generate your personalised URL" && exit 1
test -d "$dirpath" || mkdir -p "$dirpath" 2>/dev/null || (echo "Invalid download path: $dirpath" && exit 2)

# wrapper around curl to spoof user agent and disable SSL verification
function urlread() {
    curl -k -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36" $*
}

function feed() {
    if [[ $use_proxy -eq 1 ]]; then
        cookie_file="/tmp/surecook"
        rm -f $cookie_file
        while [[ ! -f $cookie_file ]]; do urlread -s -XHEAD https://www.suresome.com/ -c $cookie_file > /dev/null; done
        urlread -s --compressed https://www.suresome.com/proxy/nph-secure/00A/https/torrentz.in/feed%3fq%3d"$@" -b $cookie_file
    else
        urlread -s https://torrentz.in/feed?q="$@"
    fi
}

function search() {
    feed "$@" | grep "<link>.*$" -o | tail -n +2 | sed 's/<link>http:\/\/torrentz\.in\///g' | sed 's/<\/link>//g'
}

function get_torrent() {
    test `(urlread -s --compressed $1 -o $2 -D - ; echo 1) | head -n1 | cut -d' ' -f2` -eq 200
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
urlread -s $link | grep "<title>\|<dc:date>" | grep `date "$date_opts" +%F` -B1 | grep  ">.* S[0-9]\+E[0-9]\+" -o | sed 's/>//g' | sed 's/\s*(.*)//g' | while read title
do
    add_torrent "$title" "$suff"
done
