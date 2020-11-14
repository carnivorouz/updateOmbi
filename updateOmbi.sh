#!/bin/bash
TIMESTAMP=$(date +"%Y-%m-%e %l:%M:%S %t")
DOWNLOAD=linux-x64.tar.gz
SERVICE_NAME=ombi
VERSION=$(curl -s https://github.com/tidusjar/$SERVICE_NAME.releases/releases | grep "$DOWNLOAD" | grep -Po ".*\/download\/v([0-9\.]+).*" | awk -F'/' '{print $6}' | tr -d 'v' | sort -n | tail -1)
SERVICE_LOC=$(systemctl status $SERVICE_NAME | grep -Po "(?<=loaded \()[^;]+")
WORKING_DIR=$(grep -Po "(?<=WorkingDirectory=).*" $SERVICE_LOC)
INSTALLED=$(grep Ombi/4 $WORKING_DIR/Ombi.deps.json | head -n 1 | sed 's/.*"Ombi\///;s/": {//')
#INSTALLED=$(strings $WORKING_DIR/Ombi | grep -Po 'Ombi/\d+\.\d+\.\d+' | grep -Po '\d+\.\d+\.\d+' | sort -n | tail -n 1)
BACKUP_DIR=$WORKING_DIR../.$INSTALLED
TEMP_DIR=$WORKING_DIR../.$VERSION
URL=https://github.com/tidusjar/Ombi.Releases/releases/download/v
KEEP_BACKUP=no
SLACK_URL=https://hooks.slack.com/services/
SLACK_WEBHOOK=
SLACK_MESSAGE="Updating $SERVICE_NAME to v$VERSION"
SLACK_CHANNEL=alerts
SLACK_USER=ombi

# Start script
if [ "$INSTALLED" = "$VERSION" ]; then
        echo "$TIMESTAMP $SERVICE_NAME is up to date"
        exit 0
 else
        echo "$TIMESTAMP Updating $SERVICE_NAME"
        curl -X POST --data "payload={\"channel\": \"#$SLACK_CHANNEL\", \"username\": \"$SLACK_USER\", \"text\": \":exclamation: ${SLACK_MESSAGE} \"}" $SLACK_URL$SLACK_WEBHOOK
fi

echo  "$TIMESAMP Stopping $SERVICE_NAME"
systemctl stop $SERVICE_NAME

echo "$TIMESTAMP Creating temporary directory $TEMP_DIR"
mkdir $TEMP_DIR $BACKUP_DIR
cd $TEMP_DIR

echo "$TIMESTAMP Downloading $SERVICE_NAME"
wget $URL$VERSION/$DOWNLOAD -O $DOWNLOAD

if [ $? -ne 0 ]; then
   echo "$TIMESTAMP Failed to download"
   exit 1
fi

echo "$TIMESTAMP Extracting $DOWNLOAD"
tar -xf "$DOWNLOAD"

echo "$TIMESTAMP Shuffling directories"
mv $WORKING_DIR/* $BACKUP_DIR/
mv $TEMP_DIR/* $WORKING_DIR/

echo "$TIMESTAMP Copying over files from $BACKUP_DIR"
if [ -f $BACKUP_DIR/database.json ]; then
  cp $BACKUP_DIR/database.json $WORKING_DIR
fi

if [ -f $BACKUP_DIR/database_multi.json ]; then
  cp $BACKUP_DIR/database_multi.json $WORKING_DIR
fi

if [ -f $BACKUP_DIR/Ombi.db ]; then
  cp $BACKUP_DIR/Ombi.db $WORKING_DIR
fi

if [ -f $BACKUP_DIR/OmbiSettings.db ]; then
  cp $BACKUP_DIR/OmbiSettings.db $WORKING_DIR
fi

if [ -f $BACKUP_DIR/OmbiSettings.db ]; then
  cp $BACKUP_DIR/OmbiSettings.db $WORKING_DIR
fi
cp -rn $BACKUP_DIR/wwwroot/images/* $WORKING_DIR/wwwroot/images || true

echo "$TIMESTAMP Changing ownership to $SERVICE_NAME"
chown -R $SERVICE_NAME:$SERVICE_NAME $WORKING_DIR

if [ $KEEP_BACKUP == "yes" ]; then
   echo "$TIMESTAMP Keeping $BACKUP_DIR"
elif [ $KEEP_BACKUP == "no" ]; then
   echo "$TIMESTAMP Deleting $BACKUP_DIR"
   rm -rf $BACKUP_DIR
fi

echo "$TIMESTAMP Starting $SERVICE_NAME"
systemctl start $SERVICE_NAME
