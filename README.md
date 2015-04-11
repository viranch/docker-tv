# docker-tv
Docker image containing home entertainment automation for Raspberry Pi

### How to use?
```
docker run -d --privileged --name tv -e EMAIL=your@email.com -e RSS_FEED=http://followshows.com/feed/foo -e "TV_OPTS=-s 720p" -v $PWD/data:/data -p 80:80 viranch/tv
```

### What does it contain?

- Transmission server that watches `/data/watch` for torrent files.
- Apache web server hosting downloads directory and transmission interface (http://your-ip/downloads, http://your-ip/transmission).
- Cron daemon with a daily job that looks for new episodes from the RSS link provided in run command.

### Customizing

##### What is `$TV_OPTS`?

This environment variable is used to pass extra options to the cronjob [script](https://github.com/viranch/docker-tv/blob/master/assets/tv.sh). The one in the sample run above adds the suffix "720p" for all torrent search queries.
 Check out the script to see what options you can pass.

##### Multiple RSS feeds

You can pass multiple comma-separated RSS feed links to `RSS_FEED` variable in the run command.
You can also pass multiple sets of `TV_OPTS` (comma-separated, eg: `TV_OPTS=-s 720p,-s eztv` can also be passed.
Note that the number of RSS feed links and set of TV_OPTS should be equal. The first RSS link will be used with first options set in `TV_OPTS`, second link for second options set, and so on.

### Coming up

* [DLNA](http://en.wikipedia.org/wiki/Digital_Living_Network_Alliance) server for streaming your downloaded media straight to your DLNA-compliant TV.
* A torrent search page in-built in the image, with direct "Add to download" button.
* mpd for playing & controlling your music remotely.
