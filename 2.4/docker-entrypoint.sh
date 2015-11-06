#!/bin/bash
set -e

#
# set localtime
ln -sf /usr/share/zoneinfo/$LOCALTIME /etc/localtime

#
# functions

function set_conf {
    echo >$2; IFSO=$IFS; IFS=$(echo -en "\n\b")
    for c in `printenv|grep $1`; do echo "`echo $c|cut -d "=" -f1|awk -F"$1" '{print $2}'` $3 `echo $c|cut -d "=" -f2`" >> $2; done;
    IFS=$IFSO
}

function a2enmod {
    for module in $1; do
        if [ ! -f  "$HTTPD_PREFIX/modules/mod_${module}.so" ]; then
            echo >&2 "[ERROR] The httpd module ${module} not found ! "
            exit 1
        fi
        sed -i "s/#LoadModule ${module}_module modules\/mod_${module}.so/LoadModule ${module}_module modules\/mod_${module}.so/" $HTTPD_PREFIX/conf/httpd.conf
    done
}

#
# APACHE

if [ ! -d "$HTTPD__DocumentRoot" ]; then echo >&2 "[Error] Document Root Directory not exist (please create $HTTPD__DocumentRoot)"; exit 1; fi
a2enmod "$HTTPD_a2enmod"
set_conf "HTTPD__" "$HTTPD_CONF_DIR/40-user.conf" ""

#
# Docker links

# Set php-fpm with link
if [ -n "$PHPFPM_PORT_9000_TCP_ADDR" ]; then
    a2enmod "proxy proxy_fcgi"
    echo "ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://${PHPFPM_PORT_9000_TCP_ADDR}:${PHPFPM_PORT_9000_TCP_PORT}${HTTPD__DocumentRoot}/\$1" > $HTTPD_CONF_DIR/20-phpfpm.conf
fi


#
# Run

if [[ ! -z "$1" ]]; then
    exec ${*}
else
    exec httpd-foreground
fi
