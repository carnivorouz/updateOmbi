#!/bin/bash
DOWNLOAD=linux-x64.tar.gz
SERVICE_NAME=ombi
VERSION=$(curl -s https://github.com/tidusjar/ombi.releases/releases | grep "$DOWNLOAD" | grep -Po ".*\/download\/v([0-9\.]+).*" | awk -F'/' '{print $6}' | tr -d 'v' | sort -n | tail -1)
SERVICE_LOC=$(systemctl status $SERVICE_NAME | grep -Po "(?<=loaded \()[^;]+")
WORKING_DIR=$(grep -Po "(?<=WorkingDirectory=).*" $SERVICE_LOC)
INSTALLED=$(grep -Po "(?<=Ombi/)([\d\.]+)" $WORKING_DIR/Ombi.deps.json | head -1)
BACKUP_DIR=$WORKING_DIR.$INSTALLED
TEMP_DIR=$WORKING_DIR.$VERSION
URL=https://github.com/tidusjar/Ombi.Releases/releases/download/v
KEEP_BACKUP=no
SLACK_WEBHOOK=
SLACK_MESSAGE="Upgrading Ombi to v$VERSION"
SLACK_CHANNEL=alerts
SLACK_USER=ombi

# Start script
if [ "$(printf '%s\n' "$VERSION" "$INSTALLED" | sort -V | head -n1)" = "$VERSION" ]; then
        echo "#### Ombi is up to date ####"
	exit 0
 else
        echo "#### Upgrading Ombi ####"
	curl -X POST --data "payload={\"channel\": \"#$SLACK_CHANNEL\", \"username\": \"$SLACK_USER\", \"text\": \":exclamation: ${SLACK_MESSAGE} \"}" https://hooks.slack.com/services/$SLACK_WEBHOOK
fi

echo  "#### Stopping Ombi ####"
systemctl stop ombi

echo "#### Making a new Ombi directory ####"
mkdir $TEMP_DIR
cd $TEMP_DIR

echo "#### Downloading Ombi ####"
wget $URL$VERSION/$DOWNLOAD

if [ $? -ne 0 ]; then
   echo "#### Failed to download ####"
   exit 1
fi

echo "#### Extracting $DOWNLOAD ####"
tar -xf $DOWNLOAD

echo "#### Shuffling directories ####"
mv $WORKING_DIR $BACKUP_DIR
mv $TEMP_DIR $WORKING_DIR

echo "#### Copying over files from $BACKUP_DIR ####"
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

echo "#### Changing ownership to Ombi ####"
chown -R ombi:ombi $WORKING_DIR

if [ $KEEP_BACKUP == "yes" ]; then
   echo "#### Keeping $BACKUP_DIR ####"
elif [ $KEEP_BACKUP == "no" ]; then
   echo "#### Deleting $BACKUP_DIR ####"
   rm -rf $BACKUP_DIR
fi

echo "#### Starting Ombi ####"
systemctl start ombi
