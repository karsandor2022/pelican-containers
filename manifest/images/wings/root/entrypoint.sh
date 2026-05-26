#!/bin/sh

echo "Pre-start: Checking for Wings configuration..."

count=1
while [ ! -f /etc/pelican/config.yml ]; do
    echo "Pre-start: Wings config does not exist... Waiting [Try "$count"]"
    count=`expr $count + 1`
    sleep 15
done

echo "Pre-start: Config found"

echo "Starting Pelican Wings ${VERSION}..."

exec /usr/local/bin/wings