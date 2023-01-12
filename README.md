# FE2 Docker

## Start via docker-compose.yml
1. copy config.template/data/logback.xml to data/fe2/config/data/
2. copy or move config.env.example to config.env
3. adjust all variables in config.env
4. docker-compose up (-d)

## Backup Scripts
Inside 'scripts/backup' several files can be found to perform backup and restore tasks. A cron example is also contained. Copy all files locally, including 'rsync_ignore.txt'. Afterwards follow the instructions inside the scripts to get started.

:warning: Do not edit the script files in the cloned repository, otherwise they will be overwritten by a future git pull. Always reference (e.g. cron job) the copied and modified files.