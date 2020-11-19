#!/bin/bash
DOWNLOAD=linux-x64.tar.gz
SERVICE_NAME=ombi
VERSION=$(curl -s https://github.com/tidusjar/$SERVICE_NAME.releases/releases | grep "$DOWNLOAD" | grep -Po ".*\/download\/v([0-9\.]+).*" | awk -F'/' '{print $6}' | tr -d 'v' | sort -n | tail -1)
SERVICE_LOC=$(systemctl status $SERVICE_NAME | grep -Po "(?<=loaded \()[^;]+")
WORKING_DIR=$(grep -Po "(?<=WorkingDirectory=).*" $SERVICE_LOC)
INSTALLED_1=$(strings $WORKING_DIR/Ombi | grep -Po 'Ombi/\d+\.\d+\.\d+' | grep -Po '\d+\.\d+\.\d+' | sort -n | tail -n 1)
INSTALLED_2=$(grep -Po "(?<=Ombi/)([\d\.]+)" 2> /dev/null $WORKING_DIR/Ombi.deps.json | head -1)
BACKUP_DIR=$WORKING_DIR.$INSTALLED
TEMP_DIR=$WORKING_DIR.$VERSION
URL=https://github.com/tidusjar/Ombi.Releases/releases/download/v
KEEP_BACKUP=no
SLACK_URL=https://hooks.slack.com/services/
SLACK_WEBHOOK=
SLACK_MESSAGE="Updating $SERVICE_NAME to v$VERSION"
SLACK_CHANNEL=alerts
SLACK_USER=ombi

# Start script
if [ ! -z "$INSTALLED_1" ]; then
        echo "$(date +"%Y-%m-%e %l:%M:%S %t") $SERVICE_NAME $INSTALLED_1 detected. Continuing..."
        INSTALLED=$INSTALLED_1
elif [ ! -z "$INSTALLED_2" ]; then
        echo "$(date +"%Y-%m-%e %l:%M:%S %t") $SERVICE_NAME $INSTALLED_2 detected. Continuing..."
        INSTALLED=$INSTALLED_2
else
        echo "$(date +"%Y-%m-%e %l:%M:%S %t") $SERVICE_NAME version not detected. Exiting."
        exit 1
fi

if [ "$INSTALLED" = "$VERSION" ]; then
        echo "$(date +"%Y-%m-%e %l:%M:%S %t") $SERVICE_NAME is up to date"
	exit 0
 else
        echo "$(date +"%Y-%m-%e %l:%M:%S %t") Updating $SERVICE_NAME"
	curl -X POST --data "payload={\"channel\": \"#$SLACK_CHANNEL\", \"username\": \"$SLACK_USER\", \"text\": \":exclamation: ${SLACK_MESSAGE} \"}" $SLACK_URL$SLACK_WEBHOOK
fi

echo  "$(date +"%Y-%m-%e %l:%M:%S %t") Stopping $SERVICE_NAME"
systemctl stop $SERVICE_NAME

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Creating temporary directory $TEMP_DIR"
mkdir $TEMP_DIR
cd $TEMP_DIR

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Downloading $SERVICE_NAME"
wget $URL$VERSION/$DOWNLOAD

if [ $? -ne 0 ]; then
   echo "$(date +"%Y-%m-%e %l:%M:%S %t") Failed to download"
   exit 1
fi

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Extracting $DOWNLOAD"
tar -xf $DOWNLOAD

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Shuffling directories"
mv $WORKING_DIR $BACKUP_DIR
mv $TEMP_DIR $WORKING_DIR

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Copying over files from $BACKUP_DIR"
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

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Changing ownership to $SERVICE_NAME"
chown -R $SERVICE_NAME:$SERVICE_NAME $WORKING_DIR

if [ $KEEP_BACKUP == "yes" ]; then
   echo "$(date +"%Y-%m-%e %l:%M:%S %t") Keeping $BACKUP_DIR"
elif [ $KEEP_BACKUP == "no" ]; then
   echo "$(date +"%Y-%m-%e %l:%M:%S %t") Deleting $BACKUP_DIR"
   rm -rf $BACKUP_DIR
fi

echo "$(date +"%Y-%m-%e %l:%M:%S %t") Starting $SERVICE_NAME"
systemctl start $SERVICE_NAME
