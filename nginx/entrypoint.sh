#!/bin/sh

if [ $CERTBOT_ENABLED = true ]
then
  # Generate dhparam.pem
  if [[ ! -f /etc/letsencrypt/dhparam.pem ]]
  then
      openssl dhparam -out /etc/letsencrypt/dhparam.pem 4096
  fi

  # Request certificates in standalone mode before nginx starts
  certbot certonly -n -d $CERTBOT_DOMAIN \
    --standalone --preferred-challenges http --email $CERTBOT_EMAIL --agree-tos --expand --rsa-key-size 4096

  # Enable renew cron
  /usr/sbin/crond -f -d 8 &

  # Delete nossl conf
  rm /etc/nginx/templates/fe2-nossl.conf.template
else
  # Delete ssl conf
  rm /etc/nginx/templates/fe2-ssl.conf.template
fi

# Call original entrypoint
exec /docker-entrypoint.sh "$@"