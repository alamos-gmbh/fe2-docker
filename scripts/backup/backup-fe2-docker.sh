#!/bin/bash

##### variables start
#specify path were docker-compose.yml file resides (without trailing /)
FE2_DOCKER_DIR=/home/username/docker/fe2_docker
#specify path (without trailing /) for backup storage
BACKUP_DIR=/home/username/backup/fe2-docker
#specify path containing rsync_ignore.txt file (without trailing /)
#file needs to be copied to the location specified from github
#https://github.com/alamos-gmbh/fe2-docker -> scripts -> backup
RSYNC_IGNORE_PATH=/home/username/scripts/docker-fe2
# How many backups to keep - if backup job is executed daily, 30 will correspond to a backup history of 30 days.
BACKUP_VERSION_COUNT=30

# FE2 database service name (see inside docker-compose.yml)
# Usually no change needed!
DB_SVC_NAME=fe2_database

# emails must be configured - test with echo "Hello world" | mail -s "Test" john@example.com before configuring - otherwise this won't work
SEND_EMAILS=false
EMAIL_RECIPIENT=mail@example.org
# System name to identify this system inside backup result emails
SYSTEM_NAME="FE2 Docker Instance One"

##### variables end

#### functions start

sendMail () {

if [ "$SEND_EMAILS" = true ]; then
  echo "$2" | mail -s "$1" "$EMAIL_RECIPIENT"
else
  echo "Sending emails is disabled"
fi

}

compose_local() {
    if [ ${mod_compose_avail} -eq 0 ]; then
        command docker compose "$@"
    else
        command docker-compose "$@"
    fi
}

#### functions end

## determine which docker-compose command to use - start
docker compose version > /dev/null 2>&1
mod_compose_avail=$?
docker-compose version > /dev/null 2>&1
old_compose_avail=$?

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
fi

echo "Using docker compose:" `compose_local version`

## determine which docker-compose command to use - end

EXECUTION_TIME=$(date +'%d-%b-%Y_%H-%M')
TARGET_DIR=$BACKUP_DIR/$EXECUTION_TIME

mkdir -p $TARGET_DIR
TARGET_DIR_DATA=$TARGET_DIR/data
mkdir -p $TARGET_DIR_DATA

RSYNC_IGNORE_FILE=$RSYNC_IGNORE_PATH/rsync_ignore.txt

if test -f "$RSYNC_IGNORE_FILE"; then
  echo "OK: rsync ignore file found"
else
  ERR_MSG="Rsync ignore file not found ($RSYNC_IGNORE_FILE). Please setup RSYNC_IGNORE_PATH. Cannot continue with backup."
  echo "ERROR: $ERR_MSG"
  sendMail "[Error] FE2 Docker Backup: $SYSTEM_NAME" "$ERR_MSG"
  exit 1
fi

echo "Executing FE2 docker backup at $EXECUTION_TIME"

cd $FE2_DOCKER_DIR
echo ">>> Backing up database <<<"
compose_local exec -T $DB_SVC_NAME sh -c 'mongodump --gzip --archive' > $TARGET_DIR/fe2-dump.gz

DB_DUMP_EXIT_CODE=$?

cd -
echo "Now running in `pwd`"

echo ">>> Backing up files <<<"
rsync -auv --exclude-from=$RSYNC_IGNORE_FILE $FE2_DOCKER_DIR/ $TARGET_DIR_DATA
RSYNC_EXIT_CODE=$?

echo ">>> Cleaning up. Keeping only $BACKUP_VERSION_COUNT versions <<<"
TAIL_CNT=$(($BACKUP_VERSION_COUNT + 1))

#tail count must be plus 1
cd $BACKUP_DIR
ls $BACKUP_DIR -t | tail -n +$TAIL_CNT | xargs rm -rfv

CLEANUP_EXIT_CODE=$?

# evaluate all return codes
if [ ${DB_DUMP_EXIT_CODE} -eq 0 ] && [ ${RSYNC_EXIT_CODE} -eq 0 ] && [ ${CLEANUP_EXIT_CODE} -eq 0 ];
then
  echo "OK: All task completed successfully"
  sendMail "[Success] FE2 Docker Backup: $SYSTEM_NAME" "Backup finished successfully at $(date +'%d-%b-%Y_%H-%M-%S')"
else
  echo "ERROR: At least one task failed"
  sendMail "[Error] FE2 Docker Backup: $SYSTEM_NAME" "Backup failed at $(date +'%d-%b-%Y_%H-%M-%S'). Please check backup.log for details"
fi
