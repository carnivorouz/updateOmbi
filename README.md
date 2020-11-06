# updateOmbi

### Notes:
> The assumptions for this script are that you are using Linux for your Ombi and the service is controlled with systemd.
> There are several variables in use you can change to suit your environment.
> * SERVICE_NAME=ombi				# Change this if your systemd service is not named 'ombi'
> * KEEP_BACKUP=no				# Change this to 'yes' if you'd like to keep the previous installation
> * SLACK_WEBHOOK=				# If you'd like to use Slack for updates then input your Webhook you can get from Slack integrations.  If not using Slack, then no need to change this.
> * SLACK_MESSAGE="Upgrading Ombi to v$VERSION" # Adjust if you'd like a different message to the Slack alert
> * SLACK_CHANNEL=alerts			# Adjust to the channel you'd use in Slack
> * SLACK_USER=ombi				# Change to the user you'd like the message to come through as.  It should be dynamic though so no need to change.
