FROM openresty/openresty:alpine-fat
MAINTAINER Stewart Wu <wys1203@gmail.com>

ENV AWS_ACCESS_KEY_ID = \
    AWS_SECRET_ACCESS_KEY = \
    ACL_ID =

RUN apk add --update --no-cache \
        bash \
        py-pip \
        openssl \
        fail2ban \
        supervisor \
    && luarocks install \
        lua-resty-auto-ssl \
    && pip install boto3

RUN mkdir -p /etc/resty-auto-ssl \
    # generate a self signed ssl for nginx to start with
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj '/CN=sni-support-required-for-valid-ssl' \
        -keyout /etc/ssl/resty-auto-ssl-fallback.key \
        -out /etc/ssl/resty-auto-ssl-fallback.crt

RUN mkdir -p /var/log/nginx \
    && ln -sf /var/log/nginx/access.log /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /var/log/nginx/error.log /usr/local/openresty/nginx/logs/error.log

RUN rm -rf /etc/fail2ban/jail.d && mkdir -p /var/run/fail2ban

ADD fail2ban /etc/fail2ban/
ADD nginx /usr/local/openresty/nginx/conf/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY aws-acl-fail2ban /usr/bin/aws-acl-fail2ban
RUN chmod a+x /usr/bin/aws-acl-fail2ban

EXPOSE 80 443

ENTRYPOINT ["/usr/bin/supervisord"]

# https://github.com/docker/docker/issues/3753 For more detail about `CMD[]`
CMD ["-c", "/etc/supervisor/conf.d/supervisord.conf"]

