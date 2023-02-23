# docker-tv
Entertainment automation for homelabs on docker

### What does the composition contain?

- [Transmission](http://www.transmissionbt.com/) server for downloading media from torrents.
- [Jackett](https://github.com/Jackett/Jackett) as the torrent search aggregator backend.
- [TorDash](https://github.com/viranch/docker-tordash) for search bar, transmission web and downloads directory browser all in one.

### How to use?

- Install [docker](https://docs.docker.com/installation/#installation).

- Clone this repo: `git clone https://github.com/viranch/docker-tv`

- `cd docker-tv` and edit the relevant docker compose file to insert any secrets/configuration.

- Run the composition with a VPN (recommended): `docker-compose -f docker-compose-with-vpn.yml up -d`

- Or, without a VPN: `docker-compose -f docker-compose-without-vpn.yml up -d`

- Navigate to `http://your-ip/` to access the dashboard.

- In most practical cases, you'd want to import/copy the sample compose setup in this repo to your own compose files and put the dashboard behind your reverse proxy container.
