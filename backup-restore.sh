#!/bin/bash

# Process args
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo "Restores backup by name"
    echo " "
    echo "options:"
    echo "-h, --help                show brief help"
    echo "-n, --backup-name         considered as the dir name that contains the backup files (required)"
    echo "-b, --backups-path        path to backups dir (required)"
    echo "-d, --document-root-path  path to app files (required)"
    echo "--db-name                 app db name (required)"
    echo " "
    exit 0
    ;;
    -n|--dir-name)
    backup_name="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--backups-path)
    BACKUPS_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--document-root-path)
    DOCUMENT_ROOT_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    --db-name)
    DB_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Check required vars
if [ -z $BACKUPS_PATH ] || [ -z $DOCUMENT_ROOT_PATH ] || [ -z $DB_NAME ] || [ -z $backup_name ]; then
    echo "Missing required arguments. See -h for help."
    exit 0
fi

# Set aditional vars
backup_path="$BACKUPS_PATH/$backup_name"
log_file="$BACKUPS_PATH/backup-restore.log"

echo "Start time:       $(date +"%Y-%m-%d %H:%M:%S")" |& tee -a $log_file
echo "Backup name:      $backup_name" |& tee -a $log_file

# Empty dir
rm -rf $DOCUMENT_ROOT_PATH/*

echo "Restoring files." |& tee -a $log_file

# Extract files
tar -xvzf $backup_path/$backup_name.tar.gz -C $DOCUMENT_ROOT_PATH

echo "Restoring DB." |& tee -a $log_file

# Empty db, Import db
mysql --defaults-file=~/.my.conf -e "
    DROP DATABASE IF EXISTS $DB_NAME;
    CREATE DATABASE $DB_NAME;
    use $DB_NAME;
    source $backup_path/$backup_name.sql;"

{
echo "Total duration:   $SECONDS seconds"
echo "Finish time:      $(date +"%Y-%m-%d %H:%M:%S")"
echo " "
} |& tee -a $log_file