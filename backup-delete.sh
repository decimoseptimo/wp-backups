#!/bin/bash

# Process args
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo "Removes backups older than a certain date (optionally syncs files with google drive)"
    echo " "
    echo "options:"
    echo "-h, --help            show brief help"
    echo "-b, --backups-path    path to backups dir (required)"
    echo "-k, --keep            keep backups this time onwards (e.g. \"1 hour\", \"1 days\") (required). See 'man date' for more formatting options. (required)"
    echo "--dry-run             show matching files, no deletion"
    echo "--no-sync             bypass sync with google drive"
    echo " "
    exit 0
    ;;
    -b|--backups-path)
    BACKUPS_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -k|--keep)
    keep="$2"
    shift # past argument
    shift # past value
    ;;
    --dry-run)
    dry_run=true
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
if [ -z $BACKUPS_PATH ] || [ -z $keep ]; then
    echo "Missing required arguments. See -h for help."
    exit 0
fi

# Set aditional vars
date=$(date +"%Y-%m-%d %H:%M:%S")
keep_date=$(date +"%Y-%m-%d %H:%M:%S" -d "-$keep")
log_file="$BACKUPS_PATH/backup-delete.log"

echo "Start time:   $date" |& tee -a $log_file
echo "Keep:         $keep" |& tee -a $log_file
echo "Keep time:    $keep_date" |& tee -a $log_file

# List dirs but not delete (dry-run)
if [ $dry_run ]; then
#    find_stdout=$(find $BACKUPS_PATH/* -type d ! -newermt "$keep_date" -printf " [%TY-%Tm-%Td %TH:%TM:%.2TS] %p\n" | sort -n)
#    find_count=$("${find_stdout}" | wc -l)
    echo "Would delete (dry run):" |& tee -a $log_file
    find $BACKUPS_PATH/* -type d ! -newermt "$keep_date" -printf " [%TY-%Tm-%Td %TH:%TM:%.2TS] %p\n" | sort -n |& tee -a $log_file
#    echo "${find_stdout}" | wc -l
#    find $BACKUPS_PATH/* -type d ! -newermt "$keep_date" -printf " [%TY-%Tm-%Td %TH:%TM:%.2TS] %p\n" | sort -n
#    echo "${find_stdout}" |& tee -a $log_file
# Delete dirs
else
    echo "Deleted:" |& tee -a $log_file
    find $BACKUPS_PATH/* -type d ! -newermt "$keep_date" -printf " [%TY-%Tm-%Td %TH:%TM:%.2TS] %p\n" -exec rm -r {} \; | sort -n |& tee -a $log_file
fi
# List ignored dirs
echo "Kept:" |& tee -a $log_file
find $BACKUPS_PATH/* -type d -newermt "$keep_date" ! -newermt "$date" -printf " [%TY-%Tm-%Td %TH:%TM:%.2TS] %p\n" | sort -n |& tee -a $log_file

# Sync files with google drive
if [ -z $no_sync ]; then
#    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Syncing files."
    cd ~/grive
    grive -V -P -p $(dirname "$BACKUPS_PATH") -s $(basename "$BACKUPS_PATH")
    echo "$(($SECONDS - $backup_time)) seconds" |& tee -a $log_file
fi

# End
echo "Finish time:  $(date +"%Y-%m-%d %H:%M:%S")" |& tee -a $log_file
echo " " |& tee -a $log_file