FROM nginx:stable-alpine

# Install certbot and openssl
RUN apk add --no-cache certbot
RUN apk add --no-cache openssl

# Copy certificate renew cron script
COPY nginx/renew /etc/periodic/daily/renew
RUN chmod +x /etc/periodic/daily/renew

RUN mkdir /var/lib/certbot

# Copy custom entrypoint
COPY nginx/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy config into template dir so env vars will get populated and moved into /etc/nginx/conf.d
# https://stackoverflow.com/a/65529290
COPY nginx/fe2-ssl.conf /etc/nginx/templates/fe2-ssl.conf.template
COPY nginx/fe2-nossl.conf /etc/nginx/templates/fe2-nossl.conf.template

ENTRYPOINT [ "../entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]