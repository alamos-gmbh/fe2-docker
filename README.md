# FE2 Docker

## Start via docker-compose.yml
1. clone the repository to a local folder, e.g. /home/username/docker
2. cd to fe-docker
3. copy config.template/data/logback.xml to data/fe2/config/data/
4. copy or move config.env.example to config.env
5. adjust all variables in config.env
6. docker-compose up (-d)

:warning: Do not forget to change the password of the Admin account. This is the first thing to do upon first login to the web interface :warning:

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

:hourglass: After starting an SSL enabled FE2 docker instance for the first time, it takes about 15-30 minutes to generate encryption specific parameters (DH parameters). This is normal. The progress can be visualized using `docker logs -f fe2_nginx`

:bulb: During this time, the FE2 web interface won't be accessible.

### 

## Backup Scripts
Inside 'scripts/backup' several files can be found to perform backup and restore tasks. A cron example is also contained. Copy all files locally, including 'rsync_ignore.txt'. Afterwards follow the instructions inside the scripts to get started.

:warning: Do not edit the script files in the cloned repository, otherwise they will be overwritten by a future git pull. Always reference (e.g. cron job) the copied and modified files.

## Advanced Usage
Advanced usage / deployment options for professional users. 

:warning: Requires profound knowledge of running docker deployments. 

:bulb: No official support is offered for these use cases. 
### Running multiple containers on same docker host
The following must be configured for multiple FE2 docker containers on the same host:

One possible scenario among others: Create a new directory for each deployment and checkout the git repository to each, then setup the following:

- **Unique activation names:** `config.env`: Use a unique `FE2_ACTIVATION_NAME` variable for each deployment. This is necessary for activation purposes.
- **SSL:** `config.env`: The variable `CERTBOT_ENABLED` must be set to `false` (or at most 1 container is allowed to run with certbot enabled using default ports 80 + 443)
- **Unique container names:** In each `docker-compose.yml` every contained `container_name` declaration must be adjusted to a UNIQUE name, e.g. 
  - fe2_database -> fe2_database_2
  - fe2_app -> fe2_app_2
  - fe2_nginx -> fe2_nginx_2
  
  otherwise `docker-compose up / down` calls will interfere and stop unintended containers. 
  
  Suggestion: Rename every `container_name` inside the first `docker-compose.yml` file to '_1', inside the second compose file to '_2', etc. Check with `docker ps` that all intended containers are running, using the adjusted container names.
- **Unique port combinations:** In each `docker-compose.yml` file, setup a unique port combination, for example:
  - First container: 
    - "80:80" 
    - "443:443"
  - Second container:
    - "81:80" 
    - "444:443"
  - Third container:
    - "82:80"
    - "445:443"
  - etc.

  The left hand side of the port definition must be not already in use by the system (check with netstat; see above), thus in our example the ports 80-82;443-445 must NOT already be used by any process of the system.

