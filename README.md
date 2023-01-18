# FE2 Docker

## Start via docker-compose.yml
1. clone the repository to a local folder, e.g. /home/username/docker
2. cd to fe-docker
3. copy config.template/data/logback.xml to data/fe2/config/data/
4. copy or move config.env.example to config.env
5. adjust all variables in config.env
6. docker-compose up (-d)

## SSL Configuration

SSL encryption can be enabled by changing the variable CERTBOT_ENABLED (false|true) inside `config.env`

There are two possible options:

### Running without SSL encryption

When `CERTBOT_ENABLED` is set to `false`, the webserver is reachable on port 80 (default, unless changed in `docker-compose.yml`)
Use this scenario for testing and if SSL termination will be handled by another webserver already installed (nginx, traefik, apache, haproxy, etc.)

If port 80 is already in use, another one (not already in use; check with netstat) can be chosen inside `docker-compose.yml`

### Running with SSL encryption enabled

When `CERTBOT_ENABLED` is set to `true`, the webserver is reachable on port 443 (and 80, but http will be redirected to https automatically).

The following prerequisites must be met:

- Unbound ports 80 / 443 locally -> no other process may be running using one of these ports. Check with `netstat -tulpn | grep LISTEN | grep -E ':80|:443'`
- :warning: Ports 80 + 443 must not be changed in `docker-compose.yml`, they must be left unchanged, otherwise let's encrypt won't work
- Valid DNS A record pointing to the hosts public IP address, e.g. fe2.meinefeuerwehr.de
- Ports 80 and 443 reachable from outside (port forwarding if required, firewall exception (type TCP), etc.) Although http will be redirected to https when accessing FE2 web interface, port 80 must remain open all the time for let's encrypt (periodic certificate renewal task).

This DNS A record must be configured inside `config.env` file as variable `CERTBOT_DOMAIN`. Moreover a valid email address must be configured for let's encrypt information emails as variable `CERTBOT_EMAIL`.

:warning: Do not enter a dummy address here. Let's encrypt will only send important information.

### 

## Backup Scripts
Inside 'scripts/backup' several files can be found to perform backup and restore tasks. A cron example is also contained. Copy all files locally, including 'rsync_ignore.txt'. Afterwards follow the instructions inside the scripts to get started.

:warning: Do not edit the script files in the cloned repository, otherwise they will be overwritten by a future git pull. Always reference (e.g. cron job) the copied and modified files.
