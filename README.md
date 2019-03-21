[![Docker Pulls](https://img.shields.io/docker/pulls/viranch/tv.svg?maxAge=604800)](https://hub.docker.com/r/viranch/tv/) [![Docker Stars](https://img.shields.io/docker/stars/viranch/tv.svg?maxAge=604800)](https://hub.docker.com/r/viranch/tv/) [![Layers](https://images.microbadger.com/badges/image/viranch/tv:armv7.svg)](https://hub.docker.com/r/viranch/tv/)

# docker-tv
Entertainment automation for home (RaspberryPi) and VPS in a docker image

### What does the image contain?

- [Transmission](http://www.transmissionbt.com/) server for downloading media from torrents.
- [Jackett](https://github.com/Jackett/Jackett) as the torrent search aggregator backend.
- Dashboard web page (`http://your-ip/`) that shows:
  - Torrent search bar, with direct "Download" button in search results.
  - The Transmission web interface
  - Web view of the downloads directory (hosted by [Apache](https://httpd.apache.org/), styled by [Apaxy](https://oupala.github.io/apaxy/)).
- Automatic download of new episodes as and when they're aired, using personalized feed from [showRSS](https://showrss.info/).
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

- Get a VPS or a [RaspberryPi](http://www.raspberrypi.org/) and install any Linux OS (preferably, with a good docker support; choose one of Ubuntu & ArchLinux if in doubt).

- Install [docker](https://docs.docker.com/installation/#installation) on it.

- Run the container:
```
docker run -d --name tv -v $PWD/data:/data -p 80:80 viranch/tv
```

- [OPTIONAL] To use episode download automation, create an account on [showRSS](https://showrss.info/) and add your favourite shows. Get the link to the RSS feed from "My Feed" tab, it should be of the form: `http://showrss.info/user/XXXXXXX.rss`. Pass this link as `RSS_FEED` environment variable:
```
docker run -d --name tv -v $PWD/data:/data -p 80:80 -e RSS_FEED=http://showrss.info/user/XXXXXXX.rss viranch/tv
```

- [OPTIONAL] For getting push notifications of download complete on your phone, there are various options:
  - Install the one of the Transmission Andoird apps ([Remote Transmission](https://play.google.com/store/apps/details?id=com.neogb.rtac) or [Transmission Remote](https://play.google.com/store/apps/details?id=net.yupol.transmissionremote.app)) and configure the remote server, then enable download finished notifications in app settings.
  - If you have an iPhone, the other alternate is [PushBullet](https://www.pushbullet.com/). The image has in-built support for PushBullet, just declare your API token as `PB_TOKEN` environment variable.
```
docker run -d --name tv -v $PWD/data:/data -p 80:80 -e RSS_FEED=http://showrss.info/user/XXXXXXX.rss -e PB_TOKEN=XXXXX viranch/tv
```

- [OPTIONAL] To protect your container, you can also set a username & password for basic authentication, using the `AUTH_USER` & `AUTH_PASS` environment variables:
```
docker run [...] -e AUTH_USER=bob -e AUTH_PASS=myprecious [...] viranch/tv
```

- Navigate to `http://your-ip/`. You can change the port with the `-p` switch, eg: `-p 8000:80`.
