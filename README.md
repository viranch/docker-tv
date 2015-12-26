# docker-tv
Entertainment automation for home (RaspberryPi) and VPS in a docker image

### How does it look like?

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

- Create an account on [Followshows](http://followshows.com/) and follow your favourite shows. Get the link to the RSS feed (right side above the calendar on home page), it should be of the form: `http://followshows.com/feed/some_code`

- Optionally, use your email address for download complete push notifications.  If you're an iPhone user, get the [Boxcar2 app](https://boxcar.io/client) for push notifications. Once you sign up, you will get an email address (of the form `some_code@boxcar.io`), use it here and you'll get notifications straight on your iPhone. (I have not found any _free_ Android app for push notifications yet). Omit the `-e EMAIL=your@email.com` part in following command to disable notifications.

- If you want to use the media streaming server (eg, on a RaspberryPi on home network), run the following:
```
docker run -d --name tv -e EMAIL=your@email.com -e RSS_FEED=http://followshows.com/feed/foo -e "TV_OPTS=-s 720p" -v $PWD/data:/data --net host viranch/tv
```
- If you don't want to use the media streaming server, (eg, when on a VPS), just change the `--net host` part in above command to `-p 80:80`:
```
docker run -d --name tv -e EMAIL=your@email.com -e RSS_FEED=http://followshows.com/feed/foo -e "TV_OPTS=-s 720p" -v $PWD/data:/data -p 80:80 viranch/tv
```
- Navigate to `http://your-ip/`. You can change the port with the `-p` switch, eg: `-p 8000:80`.

- You can also optionally set a basic authentication username & password using the `-e AUTH_USER` & `-e AUTH_PASS` environment variables:
```
docker run [...] -e AUTH_USER=bob -e AUTH_PASS=myprecious [...] viranch/tv
```

### What does it contain?

- [Transmission](http://www.transmissionbt.com/) server for downloading media from torrents.
- Dashboard web page (`http://your-ip/`) that shows:
  - Torrent search bar, with direct "Download" button in search results.
  - The Transmission web interface
  - Web view of the downloads directory (hosted by Apache).
- A daily cron job that looks for new episodes from the RSS link provided in run command.
- [MiniDLNA](http://sourceforge.net/projects/minidlna/) media streaming server, which streams the download directory; so anything downloaded with torrents is readily available for streaming to a TV or any UPnP/DLNA client (eg, VLC Media Player).

### Customizing

##### What is `$TV_OPTS`?

This environment variable is used to pass extra options to the cronjob [script](https://github.com/viranch/docker-tv/blob/master/assets/tv.sh). The one in the sample run above adds the suffix "720p" for all torrent search queries.
 Check out the script to see what options you can pass.

##### Multiple RSS feeds

You can pass multiple comma-separated RSS feed links to `RSS_FEED` variable in the run command.
You can also pass multiple sets of `TV_OPTS` (comma-separated, eg: `TV_OPTS=-s 720p,-s eztv` can also be passed.
Note that the number of RSS feed links and set of `TV_OPTS` should be equal. The first RSS link will be used with first options set in `TV_OPTS`, second link for second options set, and so on.

##### Media streaming server (MiniDLNA)

The configuration for minidlna sits at `/etc/minidlna.conf` inside the container (access a running container with `docker exec -it tv bash`, where `tv` is the container name). You can copy it on the host, customize it and mount it with a new container using `-v /path/to/minidlna.conf:/etc/minidlna.conf` in the above run command.

### Coming up

* [mpd](http://www.musicpd.org/) for playing & controlling your music remotely.
