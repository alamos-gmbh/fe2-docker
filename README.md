# FE2 Docker

## Start via docker-compose.yml
1. clone the repository to a local folder, e.g. /home/username/docker
2. cd to fe-docker
3. copy config.template/data/logback.xml to data/fe2/config/data/
4. copy or move config.env.example to config.env
5. adjust all variables in config.env
6. docker-compose up (-d)

## Backup Scripts
Inside 'scripts/backup' several files can be found to perform backup and restore tasks. A cron example is also contained. Copy all files locally, including 'rsync_ignore.txt'. Afterwards follow the instructions inside the scripts to get started.

:warning: Do not edit the script files in the cloned repository, otherwise they will be overwritten by a future git pull. Always reference (e.g. cron job) the copied and modified files.
