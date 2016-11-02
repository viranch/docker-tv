#!/usr/bin/env python
import sys
import argparse
import urllib, urllib2, base64
from lxml import etree
from datetime import date
import re
import json


parser = argparse.ArgumentParser()
parser.add_argument("-a", "--auth", help="Basic authentication credentials in USER:PASSWORD format", default=None)
parser.add_argument("-l", "--link", help="Link to episode RSS feed", required=True)
parser.add_argument("-s", "--suffix", help="Torrent search suffix (eg, 720p)", default='')
args = parser.parse_args()


opener = urllib2.build_opener()
opener.addheaders = [('User-Agent','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36')]

# encode basic auth
basic_auth = base64.b64encode(args.auth) if args.auth else None


def urlread(url, params={}, auth=False):
    qs = urllib.urlencode(params)
    if qs:
        url += '?' + qs

    req = urllib2.Request(url)
    if auth and basic_auth:
        req.add_header('Authorization', 'Basic ' + basic_auth)

    return etree.parse(opener.open(req), etree.XMLParser()).getroot()


class FollowShows(object):
    def __init__(self, feed):
        self.feed = feed

    def aired_today(self):
        today = date.today().strftime('%Y-%m-%dT')
        title_regex = re.compile(r'(.* S\d{2}E\d{2}) ')
        replace_regex = re.compile(r'\s*\(.*\)')
        doc = urlread(self.feed)
        for title in doc.xpath("//item/*[name()='dc:date' and contains(text(), '" + today + "')]/../title/text()"):
            yield replace_regex.sub('', title_regex.match(title).group(0).strip())


class Torrentz(object):
    def __init__(self):
        # Size: 135 MB Seeds: 0 Peers: 0 Hash: a0729748ee7b3858530c1522d1d7b72411b41ba4
        self.torrent_regex = re.compile(r'Size: (\d+ \w+) Seeds: (\d+) Peers: (\d+) Hash: (\w+)')

    def search(self, title):
        print 'Searching', "'"+title+"'", '...',
        sys.stdout.flush()
        doc = urlread('http://localhost/tz/feed', params={'f': title}, auth=True)

        score = 0
        winner = None
        for item in doc.xpath('//item/description/text()'):
            m = self.torrent_regex.match(item)
            seeds = int(m.group(2))
            peers = int(m.group(3))
            if (seeds*2 + peers) > score:
                winner = m.group(4)
        print 'found', winner
        return winner


class Transmission(object):
    def __init__(self):
        self.session_hdr = 'X-Transmission-Session-Id'
        self.headers = {
            self.session_hdr: None,
        }
        if basic_auth:
            self.headers['Authorization'] = 'Basic ' + basic_auth

    def _call(self, data={}):
        req = urllib2.Request('http://localhost/transmission/rpc', headers=self.headers)
        try:
            return urllib2.urlopen(req, data=json.dumps(data)).read()
        except urllib2.HTTPError as e:
            self.headers[self.session_hdr] = e.headers.get(self.session_hdr)
            return self._call(data)

    def add_to_transmission(self, magnet):
        post_data = {
            'method': 'torrent-add',
            'arguments': {
                'filename': magnet,
            },
        }
        print self._call(post_data)


tvdb = FollowShows(args.link)
search_engine = Torrentz()
tr_client = Transmission()


def download(title, suffix=''):
    title = ' '.join([title, suffix]).strip()
    torrent_hash = search_engine.search(title)
    magnet = 'magnet:?xt=urn:btih:' + torrent_hash
    tr_client.add_to_transmission(magnet)


for title in tvdb.aired_today():
    download(title, args.suffix)
