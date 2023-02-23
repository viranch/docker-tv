# docker-tv
Entertainment automation for homelabs on docker

### What does the image contain?

- [Transmission](http://www.transmissionbt.com/) server for downloading media from torrents.
- [Jackett](https://github.com/Jackett/Jackett) as the torrent search aggregator backend.
- Dashboard web page (`http://your-ip/`) that shows:
  - Torrent search bar, with direct "Download" button in search results.
  - The Transmission web interface
  - Web view of the downloads directory (hosted by [Apache](https://httpd.apache.org/), styled by [Apaxy](https://oupala.github.io/apaxy/)).
- [tivo](https://github.com/viranch/tivo) for automatic download of new episodes as and when they're aired, using personalized feed from [showRSS](https://showrss.info/).
- Push notifications of finished downloads via [PushBullet](https://www.pushbullet.com/).

### What does it look like?

##### Search for torrents
![Search for torrents](https://raw.githubusercontent.com/viranch/docker-tv/master/screenshots/ss1.png)
##### Select from search results
![Select from search results](https://raw.githubusercontent.com/viranch/docker-tv/master/screenshots/ss2.png)
##### Torrent downloads
![Torrent downloads](https://raw.githubusercontent.com/viranch/docker-tv/master/screenshots/ss3.png)
##### Push notification of download complete
![Push notification of download complete](https://raw.githubusercontent.com/viranch/docker-tv/master/screenshots/ss4.jpg)

### How to use?

- Get a [RaspberryPi](http://www.raspberrypi.org/) or a [NUC](https://www.intel.com/content/www/us/en/products/details/nuc.html) or a [NAS](https://www.synology.com/en-us/products?tower=ds_j%2Cds_plus%2Cds_value%2Cds_xs) or a remote [VPS](https://en.wikipedia.org/wiki/Virtual_private_server) or any computer.

- Install any Linux OS (preferably, with a good docker support; choose one of Ubuntu & ArchLinux if in doubt).

- Install [docker](https://docs.docker.com/installation/#installation) on it.

- Run the container:
```
docker run -d --name tv -v $PWD/data:/data -p 80:80 ghcr.io/viranch/tv
```

- [OPTIONAL] To use episode download automation, create an account on [showRSS](https://showrss.info/) and add your favourite shows. Get the link to the RSS feed from "My Feed" tab, it should be of the form: `http://showrss.info/user/XXXXXXX.rss`. Pass this link as `RSS_FEED` environment variable:
```
docker run -d --name tv -v $PWD/data:/data -p 80:80 -e RSS_FEED=http://showrss.info/user/XXXXXXX.rss ghcr.io/viranch/tv
```

- [OPTIONAL] For getting push notifications of download complete on your phone, there are various options:
  - Install the one of the Transmission Android apps ([Remote Transmission](https://play.google.com/store/apps/details?id=com.neogb.rtac) or [Transmission Remote](https://play.google.com/store/apps/details?id=net.yupol.transmissionremote.app)) and configure the remote server, then enable download finished notifications in app settings.
  - Another alternate is to use [Pushover](https://www.pushover.net/). The image has in-built support for Pushover, just declare your API token as `PUSHOVER_APP_TOKEN` environment variable and user key as `PUSHOVER_USER_KEY` env var.
```
docker run -d --name tv -v $PWD/data:/data -p 80:80 -e RSS_FEED=http://showrss.info/user/XXXXXXX.rss -e PUSHOVER_APP_TOKEN=XXXXX -e PUSHOVER_USER_KEY=YYYYY ghcr.io/viranch/tv
```

- [OPTIONAL] To protect your container, you can also set a username & password for basic authentication, using the `AUTH_USER` & `AUTH_PASS` environment variables:
```
docker run [...] -e AUTH_USER=bob -e AUTH_PASS=myprecious [...] ghcr.io/viranch/tv
```

- Navigate to `http://your-ip/`. You can change the port with the `-p` switch, eg: `-p 8000:80`.
