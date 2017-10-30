# WP Backups: Automated Wordpress backups that sync with Google drive in Ubuntu Server
There are wordpress plugins that handle this, but I didn't liked them for one or more of the following reasons: slower performance, full of ads, ugly UI, high update frequency with no justifiable reason or perceivable benefit, not outputting fully standalone backups.
Plus performing this task at the OS level is more appropiate.

## Requirements
- A working wordpress application to backup
- Wp maintenance mode plugin (see below)
- WP CLI to activate plugins during backup
- Grive2 for syncing backup files with google drive
- Mysql/MariaDB
- Ubuntu Server (tested with 16.04.3 lts)
- Google drive account
- User account with read/write rights to your application files

Not strictly requirements:

- We're assuming apache2 in the examples

By default wordpress enters maintenance mode by creating a file `.maintenance` under the aplication root, but the maintenance page is not customizable. Hence we're using a plugin that enters maintenance mode by reading a `/wp-content/wp-maintenance-mode.php` file, that's presented to the user. You have to create this file to your liking.

## Documentation
### Backup.sh
Creates a named backup (optionally syncs files with google drive)

##### Options:
    
    -h, --help                show brief help
    -m, --message             log message
    -b, --backups-path        path to backups dir (required)
    -d, --document-root-path  path to app files (required)
    --db-name                 app db name (required)
    --no-sync                 bypass sync with google drive

##### Example:
```bash
$ ~/wp-backups/backup.sh --message "log message" --backups-path "~/grive/dev_backups" --document-root-path "/var/www/html" --db-name "test-db" --no-sync
```
It compress files from `/var/www/html`, exports the database `test-db`, and stores those in a child directory of `~/grive/dev_backups`. A pseudo-random auto-generated 16 alfanumeric characters string is used as the child directory and file names, and it's considered the backup name.

`--no-sync` is used to prevent syncronisation with google drive, useful for testing because it can be slow.

The created backup files paths will be like:
```bash
~/grive/dev_backups/RaNdOm16DIgSrInG/
~/grive/dev_backups/RaNdOm16DIgSrInG/RaNdOm16DIgSrInG.tar.gz
~/grive/dev_backups/RaNdOm16DIgSrInG/RaNdOm16DIgSrInG.sql
```

### Backup-delete.sh
Removes backups older than a certain date (optionally syncs files with google drive)

##### Options:
    
    -h, --help            show brief help
    -b, --backups-path    path to backups dir (required)
    -k, --keep            keep backups this time onwards (e.g. "1 hour", "1 days") (required). See 'man date' for more formatting options. (required)
    --dry-run             show matching files, no deletion
    --no-sync             bypass sync with google drive
    
##### Example:

```bash
$ ~/wp-backups/backup-delete.sh --backups-path "~/grive/dev_backups" --keep "30 days" --dry-run --no-sync
```

It finds directories in `~/grive/dev_backups` older than than `30 days` counted from the script's execution time. As `--dry-run` flag is used, It just lists them, otherwise It would delete them.

`--no-sync` is used to prevent syncronisation with google drive, useful for testing because it can be slow.

### Backup-restore.sh
Restores backup by name

##### Options:

    -h, --help                show brief help
    -n, --backup-name         considered as the dir name that contains the backup files (required)
    -b, --backups-path        path to backups dir (required)
    -d, --document-root-path  path to app files (required)
    --db-name                 app db name (required)

##### Example:
```bash
$ ~/wp-backups/backup-restore.sh --backup-name "RaNdOm16DIgSrInG" --backups-path "~/grive/dev_backups" --document-root-path "/var/www/html" --db-name "test-db"
```

It emptys the directory `/var/www/html` and extracts the .tar.gz files from the `RaNdOm16DIgSrInG` backup to it. Emptys the database `test-db` and import the database from the `RaNdOm16DIgSrInG` backup to it.

### Logging

Each script outputs (stdout, stderr) to the console and to a .log file in real time. The log paths are:
```
~/grive/dev_backups/backup.log
~/grive/dev_backups/backup-delete.log
~/grive/dev_backups/backup-restore.log
```

The recommended way to list your `~/grive/dev_backups` directory:

```bash
$ ls -lart --time-style=+"%Y-%m-%d %H:%M:%S" ~/grive/dev_backups
```
That way they'll be displayed in a similar format to that of the log files.

## Tutorial

### Installing WP CLI
Please refer to http://wp-cli.org/#installing

### Install WP Maintenance Mode plugin
```bash
$ wp plugin install WP-Maintenance-Mode --path=/var/www/html
```

### Installing and setting up grive2

Install as per the [offical repo](https://github.com/vitalif/grive2), [or](http://www.webupd8.org/2015/05/grive2-grive-fork-with-google-drive.html):
```bash
$ sudo add-apt-repository ppa:nilarimogard/webupd8
$ sudo apt-get update
$ sudo apt-get install grive
```
Setup grive2 to sync the `grive` folder:
```bash
$ mkdir ~/grive
$ cd ~/grive
$ grive -a
```
It'll request you an auth code, and then It'll read the remote files. When it finally start synchronizing files
(the whole google drive contents) we can cancel operation with `ctrl+c`.

The reason, It's simplier to use grive2 to exclusively sync a subfolder `~/grive/dev_backups` that contains our backups, than syncing the whole google drive contents.

Create the subfolder:
```bash
$ mkdir ~/grive/dev_backups
```

Now, at any point we want to sync our backups directory, We can:
```bash
$ grive -V -P -p ~/grive -s dev_backups
```
That's what WP Backups does.

### Installing WP Backups

Get WP Backups to your system:
```bash
$ wget https://github.com/decimoseptimo/wp-backups/archive/master.tar.gz -P ~
$ tar -xvzf ~/master.tar.gz
$ mv ~/wp-backups-master ~/wp-backups
$ chmod 764 ~/wp-backups/*
```

Setup your mysql/mariadb crendentials by creating a `~/.my.conf` file:
```bash
[client]
user=YOUR_MYSQL_USER
password=YOUR_MYSQL_PASSWORD
```

(Optional)
We can set some values that are frequently used, as environmental variables.
Append this to your `~/.bashrc` file:
```
# wp-backups vars
export DOCUMENT_ROOT_PATH="/var/www/html"
export BACKUPS_PATH="/home/ubuntu/grive/dev_backups"
export DB_NAME="test-db"
```

For our environmental variables to work in in Ubuntu Server 16.04, we had to comment out a line in `~/.bashrc`:
```bash
# If not running interactively, don't do anything
case $- in
    *i*) ;;
#      *) return;;
esac

```

Then we source the .bashrc file:
````bash
$ . ~/.bashrc
````
(/Optional)

Edit your crontab file:
```bash
$ crontab -e
```

In this example we're going to create backups every 5 minutes. And just 1 minute before that, delete backups older than than 30 minutes. Add this to your crontab file:

```bash
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

4-59/5 * * * * . $HOME/.profile; ~/wp-backups/backup-delete.sh --keep "30 minutes" --no-sync
*/5 * * * * . $HOME/.profile; ~/wp-backups/backup.sh -m "Cron backup" --no-sync
``` 

As you can see we're calling the scripts omitting some required flags, specifically those already setup as enviromental variables. Otherwise we'd have to send `--backups-path --document-root-path --db-name` as appropiate.

The SHELL and PATH lines are required so that the script runs in bash, and the paths are available to it.