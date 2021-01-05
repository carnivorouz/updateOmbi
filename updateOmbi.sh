#!/bin/bash
DOWNLOAD=linux-x64.tar.gz
SERVICE_NAME=ombi
VERSION=$(curl -s https://github.com/tidusjar/ombi.releases/releases | grep "$DOWNLOAD" | grep -Po ".*\/download\/v([0-9\.]+).*" | awk -F'/' '{print $6}' | tr -d 'v' | sort -n | tail -1)
SERVICE_LOC=$(systemctl status $SERVICE_NAME | grep -Po "(?<=loaded \()[^;]+")
WORKING_DIR=$(grep -Po "(?<=WorkingDirectory=).*" $SERVICE_LOC)
INSTALLED_1=$(strings $WORKING_DIR/Ombi | grep -Po 'Ombi/\d+\.\d+\.\d+' | grep -Po '\d+\.\d+\.\d+' | sort -n | tail -n 1)
INSTALLED_2=$(grep -Po "(?<=Ombi/)([\d\.]+)" 2> /dev/null $WORKING_DIR/Ombi.deps.json | head -1)
STORAGE_DIR=
URL=https://github.com/tidusjar/Ombi.Releases/releases/download/v
KEEP_BACKUP=yes
SLACK_URL=https://hooks.slack.com/services/
SLACK_WEBHOOK=
MESSAGE="Updating $SERVICE_NAME to v$VERSION"
SLACK_CHANNEL=alerts
SLACK_USER=ombi
SLACK_POST=$(curl -X POST --data "payload={\"channel\": \"#$SLACK_CHANNEL\", \"username\": \"$SLACK_USER\", \"text\": \":exclamation: ${MESSAGE} \"}" $SLACK_URL$SLACK_WEBHOOK)
DISCORD_WEBHOOK=
DISCORD_POST=$(curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$MESSAGE\"}" $DISCORD_WEBHOOK)

# Start script
# Check for version info in the executable
if [ ! -z "$INSTALLED_1" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") $SERVICE_NAME $INSTALLED_1 detected. Continuing..."
        INSTALLED=$INSTALLED_1
# Check for version info before it was in the executable
elif [ ! -z "$INSTALLED_2" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") $SERVICE_NAME $INSTALLED_2 detected. Continuing..."
        INSTALLED=$INSTALLED_2
else
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Currently installed version of $SERVICE_NAME not detected. Exiting."
        exit 1
fi

if [ "$INSTALLED" = "$VERSION" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") $SERVICE_NAME is up to date"
	exit 0
elif [ -z $VERSION ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Latest version of $SERVICE_NAME not found. Exiting."
        exit 1
else
        echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Updating $SERVICE_NAME"
	echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") $SLACK_POST"
	echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") $DISCORD_POST"
fi

echo  "$(date +"%Y-%m-%d %H:%M:%S.%3N") Stopping $SERVICE_NAME"
systemctl stop $SERVICE_NAME

# Check to see if directory has a forward slash at the end and correct it
if [[ $WORKING_DIR = */ ]]; then
        WORKING_DIR=$(echo $WORKING_DIR | sed 's/.$//')
else
        WORKING_DIR=$WORKING_DIR
fi

BACKUP_DIR=$WORKING_DIR.$INSTALLED
TEMP_DIR=$WORKING_DIR.$VERSION

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Creating temporary directory $TEMP_DIR"
mkdir $TEMP_DIR
cd $TEMP_DIR

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Downloading $SERVICE_NAME"
wget -N $URL$VERSION/$DOWNLOAD

if [ $? -ne 0 ]; then
   echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Failed to download"
   exit 1
fi

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Extracting $DOWNLOAD"
tar -xf $DOWNLOAD

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Shuffling directories"
mv $WORKING_DIR $BACKUP_DIR
mv $TEMP_DIR $WORKING_DIR

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Copying over files from $BACKUP_DIR"

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



echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Changing ownership to $SERVICE_NAME"
chown -R $SERVICE_NAME:$SERVICE_NAME $WORKING_DIR

if [ $KEEP_BACKUP == "yes" ]; then
   echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Keeping $BACKUP_DIR"
elif [ $KEEP_BACKUP == "no" ]; then
   echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Deleting $BACKUP_DIR"
   rm -rf $BACKUP_DIR
fi

echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") Starting $SERVICE_NAME"
systemctl start $SERVICE_NAME
