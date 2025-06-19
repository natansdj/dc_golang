FROM krakend:2.10 AS builder
# ARG ENV=prod

COPY config/krakend.tmpl .
COPY config/settings /etc/krakend/settings
COPY config/templates /etc/krakend/templates

## Save temporary file to /tmp to avoid permission errors
RUN FC_ENABLE=1 \
    FC_OUT=/tmp/krakend.json \
    FC_SETTINGS="/etc/krakend/settings" \
    FC_TEMPLATES="/etc/krakend/templates" \
    krakend check -d -t -c "krakend.tmpl" --lint

FROM krakend:2.10
# Keep operating system updated with security fixes between releases
RUN apk upgrade --no-cache --no-interactive

COPY --from=builder --chown=krakend:nogroup /tmp/krakend.json .
# Uncomment with Enterprise image:
# COPY LICENSE /etc/krakend/LICENSE

EXPOSE ${PORT
