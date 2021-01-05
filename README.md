# updateOmbi

### Notes:
The assumptions for this script are that you are using Linux for your Ombi and the service is controlled with systemd.  
 
There are several variables in use you can change to suit your environment:
> * SERVICE_NAME=ombi				# Change this if your systemd service is not named 'ombi'
> * KEEP_BACKUP=no				# Change this to 'yes' if you'd like to keep the previous installation as backup
> * STORAGE_DIR=				# If using `--storage` parameter in service script then add that here 
> * SLACK_WEBHOOK=				# Webhook found in Slack settings.  Not required.
> * MESSAGE="Upgrading Ombi to v$VERSION" 	# Adjust if you'd like a different message to the alerts
> * SLACK_CHANNEL=alerts			# Adjust to the channel you'd use in Slack. Not required.
> * SLACK_USER=ombi				# Change to the user you'd like the message to come through as. Not required.
> * DISCORD_WEBHOOK=                        	# Copy and paste this just as you get it from Discord Integrations. Not required.

This works as a script you can put in (`cp /link/to/script/updateOmbi.sh /etc/cron.daily`) or symlink to (`ln -s /link/to/script/updateOmbi.sh /etc/cron.daily`) in /etc/cron.daily or hourly  
That will run it as root  
If you'd like it to not run it as root, then you should use `visudo` to add `ombi    ALL=NOPASSWD: /bin/systemctl stop ombi.service, /bin/systemctl start ombi.service` to the sudoers file  
Then you could run it under `/var/spool/cron/ombi` as an entry such as `0 0 0 ? * * * /link/to/script/updateOmbi.sh` and that would run it daily at midnight  
