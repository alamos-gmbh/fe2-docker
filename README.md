# FE2 Docker

## Important hints
### Support

:raising_hand_man: This project addresses professional users with profound Linux and Docker knowledge.

### Environment

The following versions are required
- Docker Engine 20.10 or newer
- Docker Compose **v2** (the `docker compose` subcommand, not the standalone `docker-compose` v1 binary)

:bulb: We recommend running Ubuntu Server

:warning: Docker Desktop for Windows (Windows Linux Subsystem (WSL2)) is not supported.

### Major Upgrades / Minor Upgrades

:warning: Major upgrades are not supported and will lead to errors.
Example:
When a `docker-compose.yml` file specifies version 2.28, it's not supported to upgrade to 2.31 directly by just changing version information.

The upgrade path is:

- 2.28 -> 2.29
- 2.29 -> 2.30
- 2.30 -> 2.31

A major upgrade can also affect the other containers specified in the `docker-compose.yml`file (most likely the mongoDB database version). Before upgrading always check the corresponding git branch of this project. We'll offer compatible environments on release branches, e.g. release/2.28, release/2.29 etc.

:bulb: Upgrades within major releases (aka minor upgrades) are supported, for example:

Upgrading from 2.28.**351** to 2.28.**406** by just changing fe2_app's image version followed by a `docker compose down && docker compose up -d` is fine.
We'll make sure that these upgrades work flawlessly.

### Using existing Windows configuration
:window: While it **might** work to copy all files from a windows installation over, it's not supported, so please don't ask for help after doing so.

## Start via docker-compose.yml

All configuration lives directly in `docker-compose.yml`. You can use a `config.env` if you want to.

1. Copy `docker-compose.yml` to your machine
2. edit `docker-compose.yml` and adjust every value marked with `# ANPASSEN`:
   - `fe2_app` -> `hostname`: your desired hostname. This is important for correct functionality of the
     system outage function.
   - `fe2_app` -> `FE2_EMAIL` / `FE2_PASSWORD`: the e-mail address and password of your license account
   - `fe2_app` -> `FE2_ACTIVATION_NAME`: your desired activation name
3. `docker compose up -d`

:bulb: FE2's web interface is then published on host port 8083 over plain HTTP. It needs a reverse proxy in front of it - see [Reverse proxy and TLS](#reverse-proxy-and-tls).

## Reverse proxy and TLS

This deployment does **not** contain a reverse proxy and does **not** terminate TLS. FE2's web interface is published on host port **8083** over plain HTTP. Putting a proxy in front of it, and obtaining and renewing certificates, is the operator's responsibility.

:warning: Port 8083 speaks unencrypted HTTP, including the login form, and is published on **all** interfaces. UFW or iptables does not prevent access - docker bypasses them, the same behaviour described under "Emergency access" below. Make sure a firewall appliance or your network design keeps this port away from untrusted networks, and never expose it to the internet directly.

:bulb: If your reverse proxy runs directly on the same docker host, restrict the binding to loopback in `docker-compose.yml`. The port is then unreachable from the network and the warning above no longer applies:

```yaml
    ports:
      - "127.0.0.1:8083:83"
```

A proxy running in its own container cannot use this: `127.0.0.1` there is the proxy container's own loopback, not the host's. Such a setup needs the docker host's address, and the port has to stay published on all interfaces.

### What your proxy has to do

FE2 keeps a websocket connection open for live updates. Two things follow from that, and both are easy to miss:

1. The `Upgrade` and `Connection` headers have to be forwarded to FE2.
2. Idle connections must not be cut after the usual 60 seconds - raise the read timeout well beyond that.

Get either wrong and the web interface reconnects over and over.

:bulb: If you would rather not hand-write a proxy configuration, [Nginx Proxy Manager](https://nginxproxymanager.com/) is a common choice. It runs as a container, terminates TLS and takes care of Let's Encrypt certificates including renewal, all from its web UI. Point a proxy host at the docker host's address on port 8083. The one FE2-specific setting is the **Websockets Support** switch in the proxy host - make sure it is on.

nginx, traefik, Caddy, apache, haproxy or a hardware appliance all work, as long as those two points are covered.

### Migrating from a release that shipped nginx

Earlier releases of this repository contained an `fe2_nginx` service that terminated TLS via Let's Encrypt. When upgrading from one of those:

1. Set up your own reverse proxy **before** switching over. Otherwise FE2 is only reachable over plain HTTP on port 8083 in the meantime.
2. `docker compose down` with the old file, then `git pull`, then `docker compose up -d`. Ports 80 and 443 are no longer bound by this deployment and are free for your proxy.
3. The `fe2_nginx` container and its locally built image are no longer part of the project. If either lingers, remove it: `docker rm -f fe2_nginx` and `docker image rm <old fe2_nginx image>`
4. `data/certbot/` still holds the old Let's Encrypt account, certificates and private keys. Nothing reads it any more. Either reuse those certificates in your own proxy or delete the directory.

## Emergency access to the FE2 http port (via 64112)

When you're locked out, emergency access to FE2 is possible via port 64112 after activation in `docker-compose.yml`. In the `fe2_app` service, uncomment the `64112` entry inside the existing `ports:` block:

```yaml
    ports:
      - "8083:83"
      - "64112:64112"
```

Save and restart with `docker compose down && docker compose up -d`

Open a browser of your choice and navigate to http://{DOCKER_HOST_IP}:64112

:bulb: The emergency binding will not use https://

:warning: This exposes port 64112. If no firewall appliance prevents access, the port will be publicly accessible. UFW or iptables firewall does not prevent access (unless explicitly configured, docker bypasses UFW / iptables). More info about that behavior can be found [here](https://www.techrepublic.com/article/how-to-fix-the-docker-and-ufw-security-flaw/).

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

- **Unique activation names:** `docker-compose.yml`: Use a unique `FE2_ACTIVATION_NAME` variable for each deployment. This is necessary for activation purposes.
- **Unique container names:** In each `docker-compose.yml` every contained `container_name` declaration must be adjusted to a UNIQUE name, e.g. 
  - fe2_database -> fe2_database_2
  - fe2_app -> fe2_app_2
  
  otherwise `docker compose up / down` calls will interfere and stop unintended containers. 
  
  Suggestion: Rename every `container_name` inside the first `docker-compose.yml` file to '_1', inside the second compose file to '_2', etc. Check with `docker ps` that all intended containers are running, using the adjusted container names.
- **Unique host ports:** In each `docker-compose.yml` file, publish the FE2 web interface on a unique host port, for example:
  - First container: `"8083:83"`
  - Second container: `"8084:83"`
  - Third container: `"8085:83"`
  - etc.

  The left hand side of the port definition must not already be in use by the system (check with netstat; see above). If you also enable the emergency port, it needs a unique host port per deployment too, e.g. `"64112:64112"`, `"64113:64112"`, etc. Your reverse proxy then targets one host port per FE2 instance.

## Development

Development of this project happens in Alamos' internal GitLab instance. This GitHub repository is a
**mirror**, published from the internal pipeline after its checks pass.

The mirror publishes snapshots, so one commit here can correspond to several internal commits, and internal
build configuration is not part of this repository. History here is append-only - `git clone` and `git pull`
work as usual.

Changes pushed or merged here on GitHub are overwritten by the next mirror run. If you want to report a
problem or suggest a change, please open an issue here and we will pick it up internally.
