#!/bin/bash

cat .storage.tmpl | while read line; do
    mkdir -p "/data/${line}"
done

# Generate config file if it doesnt exist
if [ ! -e /data/pelican.conf ]; then
    printf "\n[pelican-init] Generating Application Key...\n"

    # Generate base template
    touch /data/pelican.conf
    echo "##" > /data/pelican.conf
    echo "# Generated on:" $(date +"%B %d %Y, %H:%M:%S") >> /data/pelican.conf
    echo "# This file was generated on first start and contains " >> /data/pelican.conf
    echo "# the key for sensitive information. All panel configuration " >> /data/pelican.conf
    echo "# can be done here using the normal method (NGINX not included!)," >> /data/pelican.conf
    echo "# or using Docker's environment variables parameter." >> /data/pelican.conf
    echo "##" >> /data/pelican.conf
    echo "" >> /data/pelican.conf
    echo "APP_ENV=production" >> /data/pelican.conf
    echo "APP_DEBUG=false" >> /data/pelican.conf
    echo "APP_KEY=peli_SomeRandomString3232RandomString" >> /data/pelican.conf
    echo "APP_URL=http://localhost" >> /data/pelican.conf
    echo "APP_INSTALLED=false" >> /data/pelican.conf
    echo "APP_TIMEZONE=UTC" >> /data/pelican.conf
    echo "APP_LOCALE=en" >> /data/pelican.conf
    echo "" >> /data/pelican.conf
    echo "HASHIDS_SALT=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)" >> /data/pelican.conf
    echo "HASHIDS_LENGTH=8" >> /data/pelican.conf


    sleep 1
    php artisan p:environment:setup

    printf "[pelican-init] Application Key Generated\n"
fi



printf "\n[pelican-init] Clearing cache/views...\n"
    
php artisan cache:clear
php artisan config:clear

printf "\n[pelican-init] Optimize cache...\n"

php artisan filament:optimize

printf "\n[pelican-init] Migrating/Seeding database...\n"

php artisan migrate --seed --force
