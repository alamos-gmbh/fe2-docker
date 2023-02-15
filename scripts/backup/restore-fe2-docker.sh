#!/bin/bash

########################## Variables start

#specify path were docker-compose.yml file resides (without trailing /)
FE2_DOCKER_DIR=/home/username/docker/fe2_docker

#specify path (without trailing /) for backup storage
BACKUP_DIR=/home/username/backup/fe2-docker

# FE2 database service name (see inside docker-compose.yml)
# Usually no change needed!
DB_SVC_NAME=fe2_database

#backup to restore, e.g. 29-Dec-2022_14-05 (name of the folder without any slashes inside BACKUP_DIR)
BACKUP_FOLDER_TO_RESTORE=29-Dec-2022_14-00 #changeme

########################## Variables end

## determine which docker-compose command to use - start
docker compose version > /dev/null 2>&1
mod_compose_avail=$?
docker-compose version > /dev/null 2>&1
old_compose_avail=$?

alias compose_local='docker-compose'

if [ ${mod_compose_avail} -eq 1 ] && [ ${old_compose_avail} -eq 1 ];
then
  echo "No compatible docker-compose (docker compose) command found. Cannot continue!"
  exit 1
fi

if [ ${mod_compose_avail} -eq 1 ];
then
  echo "Modern docker compose command NOT available. Using classic docker-compose for execution."
else
  echo "Modern docker compose command available. Using it for execution."
  alias compose_local='docker compose'
fi

echo "Using docker compose:" `compose_local version`

## determine which docker-compose command to use - end


RESTORE_DIR=$BACKUP_DIR/$BACKUP_FOLDER_TO_RESTORE
RESTORE_DIR_DATA=$RESTORE_DIR/data
DB_DUMP_FILE=$RESTORE_DIR/fe2-dump.gz

if [ ! -d "$BACKUP_DIR" ]; then
  # Backup Dir not found#
  echo "Backup directory (BACKUP_DIR variable resolving to '$BACKUP_DIR') does not exist. Please set correctly. Cannot continue."
  exit 1
fi

if [ ! -d "$RESTORE_DIR" ]; then
  # Restore Dir not found#
  echo "ERROR: Restore directory '$RESTORE_DIR' does not exist. Cannot continue. Potential candidates for restore:"
  echo `ls $BACKUP_DIR -t`
  exit 1
fi

if [ ! -d "$RESTORE_DIR_DATA" ]; then
  # Restore dir data not found#
  echo "ERROR: Restore data directory '$RESTORE_DIR_DATA' does not exist. Backup files corrupted. Cannot continue."
  exit 1
fi

if test -f "$DB_DUMP_FILE"; then
  echo "OK: Database dump file found"
else
  echo "ERROR: Database dump file '$DB_DUMP_FILE' not found. Cannot continue."
  exit 1
fi

if [ ! -d "$FE2_DOCKER_DIR" ]; then
  # Docker Dir not found#
  echo "ERROR: FE2 docker directory '$FE2_DOCKER_DIR' does not exist. Cannot continue."
  exit 1
fi

cd $FE2_DOCKER_DIR

echo "Now running in: `pwd`"

echo "Stopping FE2"
compose_local stop fe2_app

echo "Restoring files"
rsync -auv $RESTORE_DIR_DATA/ $FE2_DOCKER_DIR

compose_local up -d fe2_database

echo "Restoring database"

cd $FE2_DOCKER_DIR
compose_local exec -T $DB_SVC_NAME sh -c 'mongorestore --drop --gzip --archive' < $DB_DUMP_FILE

echo "Starting FE2"
compose_local up -d
