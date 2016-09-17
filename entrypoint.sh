#!/bin/bash
set -eo pipefail

# verify variables
if [ -z "$S3_ACCESS_KEY" -o -z "$S3_SECRET_KEY" -o -z "$S3_URL" ]; then
	echo >&2 'Backup information is not complete. You need to specify S3_ACCESS_KEY, S3_SECRET_KEY, S3_URL. No backups, no fun.'
	exit 1
fi

CFG_FILE=/root/.s3cfg

# set s3 config
sed -i "s/%%S3_ACCESS_KEY%%/$S3_ACCESS_KEY/g" $CFG_FILE
sed -i "s/%%S3_SECRET_KEY%%/$S3_SECRET_KEY/g" $CFG_FILE

# verify S3 config
s3cmd -c $CFG_FILE ls "s3://$S3_URL" > /dev/null

# set cron schedule TODO: check if the string is valid (five or six values separated by white space)
[[ -z "$CRON_SCHEDULE" ]] && CRON_SCHEDULE='0 2 * * *' && \
   echo "CRON_SCHEDULE set to default ('$CRON_SCHEDULE')"

# add a cron job
echo "$CRON_SCHEDULE root rm -rf /tmp/dump && rabbitmqctl stop_app && tar -czf all.tgz /var/lib/rabbitmq/ && rabbitmqctl start_app && s3cmd -c $CFG_FILE sync /tmp/dump s3://$S3_URL/ && rm -rf /tmp/dump" >> /etc/crontab
crontab /etc/crontab

exec "$@"