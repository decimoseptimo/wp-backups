#!/bin/bash

# Set initial vars
message="[NONE]"
sync_time="[NONE]"

# Process args
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo "Creates a named backup (optionally syncs files with google drive)"
    echo " "
    echo "options:"
    echo "-h, --help                show brief help"
    echo "-m, --message             log message"
    echo "-b, --backups-path        path to backups dir (required)"
    echo "-d, --document-root-path  path to app files (required)"
    echo "--db-name                 app db name (required)"
    echo "--no-sync                 bypass sync with google drive"
    echo " "
    exit 0
    ;;
    -m|--message)
    message="$2"
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
    --no-sync)
    no_sync=true
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Check required vars
if [ -z $BACKUPS_PATH ] || [ -z $DOCUMENT_ROOT_PATH ] || [ -z $DB_NAME ]; then
    echo "Missing required arguments. See -h for help."
    exit 0
fi

# Set aditional vars
backup_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
backup_path="$BACKUPS_PATH/$backup_name"
tar_path="$backup_path/$backup_name.tar.gz"
sql_path="$backup_path/$backup_name.sql"
log_file="$BACKUPS_PATH/backup.log"

{
echo "Start time:       $(date +"%Y-%m-%d %H:%M:%S")"
echo "Backup name:      $backup_name"
echo "Message:          $message"
echo "Setting maintenance mode."
} |& tee -a $log_file

# Set site in maintenance mode
wp plugin activate WP-Maintenance-Mode --path=$DOCUMENT_ROOT_PATH

# Create dir
mkdir $backup_path

echo "Compressing files." |& tee -a $log_file

# Compress files
cd $DOCUMENT_ROOT_PATH
tar -czf $tar_path *

echo "Exporting DB." |& tee -a $log_file

# Export db
mysqldump --defaults-file=~/.my.conf $DB_NAME > $sql_path

{
echo "Backup files:"
echo " $backup_path/"
echo " $tar_path ($(( $(stat -c%s $tar_path) /1024/1024 )) MB)"
echo " $sql_path ($(( $(stat -c%s $sql_path) /1024/1024 )) MB)"
echo "Un-setting maintenance mode."
} |& tee -a $log_file

# Unset site from maintenance mode
wp plugin deactivate WP-Maintenance-Mode --path=$DOCUMENT_ROOT_PATH

backup_time=$SECONDS

# Sync files with google drive
if [ -z $no_sync ]; then
    echo "Syncing with google drive." |& tee -a $log_file
    cd ~/grive
    grive -V -P -p $(dirname "$BACKUPS_PATH") -s $(basename "$BACKUPS_PATH")
    echo "Sync duration:    $(($SECONDS - $backup_time)) seconds" |& tee -a $log_file
fi

{
echo "Total duration:   $SECONDS seconds"
echo "Finish time:      $(date +"%Y-%m-%d %H:%M:%S")"
echo " "
} |& tee -a $log_file