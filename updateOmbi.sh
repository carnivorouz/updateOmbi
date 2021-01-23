#!/bin/bash
DOWNLOAD=linux-x64.tar.gz
SERVICE_NAME=ombi
OMBI_URL=https://github.com/Ombi-app/Ombi.Releases/releases
VERSION=$(curl -s $OMBI_URL | grep "$DOWNLOAD" | grep -Po ".*\/download\/v([0-9\.]+).*" | awk -F'/' '{print $6}' | tr -d 'v' | sort -V | tail -1)
SERVICE_LOC=$(systemctl status $SERVICE_NAME | grep -Po "(?<=loaded \()[^;]+")
WORKING_DIR=$(grep -Po "(?<=WorkingDirectory=).*" $SERVICE_LOC)
INSTALLED_1=$(strings $WORKING_DIR/Ombi | grep -Po 'Ombi/\d+\.\d+\.\d+' | grep -Po '\d+\.\d+\.\d+' | sort -n | tail -n 1)
INSTALLED_2=$(grep -Po "(?<=Ombi/)([\d\.]+)" 2> /dev/null $WORKING_DIR/Ombi.deps.json | head -1)
STORAGE_DIR=
KEEP_BACKUP=yes
SLACK_URL=https://hooks.slack.com/services/
SLACK_WEBHOOK=
MESSAGE="Updating $SERVICE_NAME to v$VERSION"
SLACK_CHANNEL=alerts
SLACK_USER=ombi
DISCORD_WEBHOOK=

# Start script
# Privileges check
if [ "$EUID" -ne 0 ]; then
	echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [WARNING] Not running as root. You must have your sudoers file configured correctly."
fi

# Check for version info in the executable
if [ ! -z "$INSTALLED_1" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] $SERVICE_NAME $INSTALLED_1 detected. Continuing..."
        INSTALLED=$INSTALLED_1
# Check for version info before it was in the executable
elif [ ! -z "$INSTALLED_2" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") $SERVICE_NAME $INSTALLED_2 [INFO] detected. Continuing..."
        INSTALLED=$INSTALLED_2
else
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [ERROR] Currently installed version of $SERVICE_NAME not detected. Exiting."
        exit 1
fi

if [ "$INSTALLED" = "$VERSION" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] $SERVICE_NAME is up to date"
	exit 0
elif [ -z $VERSION ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [ERROR] Latest version of $SERVICE_NAME not found. Exiting."
        exit 1
else
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Updating $SERVICE_NAME"
# POST to Slack
	curl -s -o /dev/null -X POST --data "payload={\"channel\": \"#$SLACK_CHANNEL\", \"username\": \"$SLACK_USER\", \"text\": \":exclamation: ${MESSAGE} \"}" $SLACK_URL$SLACK_WEBHOOK
# POST to Discord	
	curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$MESSAGE\"}" $DISCORD_WEBHOOK
fi

echo  "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Stopping $SERVICE_NAME"
systemctl stop $SERVICE_NAME
if [ $? = 1 ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [ERROR] User does not have the permission to control $SERVICE_NAME service"
        exit 1
fi

# Check to see if directory has a forward slash at the end and correct it
if [[ $WORKING_DIR = */ ]]; then
        WORKING_DIR=$(echo $WORKING_DIR | sed 's/.$//')
else
        WORKING_DIR=$WORKING_DIR
fi

BACKUP_DIR=$WORKING_DIR.$INSTALLED
TEMP_DIR=$WORKING_DIR.$VERSION

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Creating temporary directory $TEMP_DIR"
mkdir $TEMP_DIR
cd $TEMP_DIR

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Downloading $SERVICE_NAME"
wget -N $OMBI_URL/download/v$VERSION/$DOWNLOAD

if [ $? -ne 0 ]; then
   echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [ERROR] Failed to download"
   exit 1
fi

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Extracting $DOWNLOAD"
tar -xf $DOWNLOAD

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Shuffling directories"
mv $WORKING_DIR $BACKUP_DIR
mv $TEMP_DIR $WORKING_DIR

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Copying over files from $BACKUP_DIR"

if [ -f $STORAGE_DIR/database.json ]; then
  cp $STORAGE_DIR/database.json $WORKING_DIR
fi

if [ -f $BACKUP_DIR/database.json ]; then
  cp $BACKUP_DIR/database.json $WORKING_DIR
fi

if [ -f $STORAGE_DIR/database_multi.json ]; then
  cp $STORAGE_DIR/database_multi.json $WORKING_DIR
fi

if [ -f $BACKUP_DIR/database_multi.json ]; then
  cp $BACKUP_DIR/database_multi.json $WORKING_DIR
fi

if [ -f $STORAGE_DIR/Ombi.db ]; then
  cp $STORAGE_DIR/Ombi.db $WORKING_DIR
fi

if [ -f $BACKUP_DIR/Ombi.db ]; then
  cp $BACKUP_DIR/Ombi.db $WORKING_DIR
fi

if [ -f $STORAGE_DIR/OmbiSettings.db ]; then
  cp $STORAGE_DIR/OmbiSettings.db $WORKING_DIR
fi

if [ -f $BACKUP_DIR/OmbiSettings.db ]; then
  cp $BACKUP_DIR/OmbiSettings.db $WORKING_DIR
fi

if [ -f $STORAGE_DIR/OmbiExternal.db ]; then
  cp $STORAGE_DIR/OmbiExternal.db $WORKING_DIR
fi

if [ -f $BACKUP_DIR/OmbiExternal.db ]; then
  cp $BACKUP_DIR/OmbiExternal.db $WORKING_DIR
fi

cp -rn $BACKUP_DIR/wwwroot/images/* $WORKING_DIR/wwwroot/images || true

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Changing ownership to $SERVICE_NAME"
chown -R $SERVICE_NAME:$SERVICE_NAME $WORKING_DIR

if [ $KEEP_BACKUP == "yes" ]; then
   echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Keeping $BACKUP_DIR"
elif [ $KEEP_BACKUP == "no" ]; then
   echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Deleting $BACKUP_DIR"
   rm -rf $BACKUP_DIR
fi

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") [INFO] Starting $SERVICE_NAME"
systemctl start $SERVICE_NAME
