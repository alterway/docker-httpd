#!/bin/bash
set -e

#
# set localtime
if [ "$USER" = "root" ]; then
    ln -sf /usr/share/zoneinfo/$LOCALTIME /etc/localtime
fi
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
# set HTTPD__ conf

if [ ! -d "$HTTPD__DocumentRoot" ]; then echo >&2 "[Error] Document Root Directory not exist (please create $HTTPD__DocumentRoot)"; exit 1; fi
a2enmod "$HTTPD_a2enmod"
set_conf "HTTPD__" "$HTTPD_CONF_DIR/40-user.conf" ""


# Set php-fpm with link - Warning Deprecated
if [ -n "$PHPFPM_PORT_9000_TCP_ADDR" ]; then
    echo "[WARNING] Deprecated - Future versions of Docker will not support links - you should remove them for forwards-compatibility."
    a2enmod "proxy proxy_fcgi"
    echo "ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://${PHPFPM_PORT_9000_TCP_ADDR}:${PHPFPM_PORT_9000_TCP_PORT}${HTTPD__DocumentRoot}/\$1" > $HTTPD_CONF_DIR/20-phpfpm.conf
fi

#
# set PHPFPM proxy balancer
if [ -n "$PHPFPM" ]; then

    a2enmod "proxy proxy_fcgi proxy_balancer lbmethod_byrequests slotmem_shm"

    IFSO=$IFS; IFS=' ' read -ra BACKENDS <<< "${PHPFPM}"
    for BACKEND in "${BACKENDS[@]}"; do
        BALANCEMEMBER=`echo -e "${BALANCEMEMBER}\n\tBalancerMember fcgi://${BACKEND}${HTTPD__DocumentRoot}/\$1 ${PHPFPM_CONFIG:-timeout=5 retry=30 ping=2}"`
    done; IFS=$IFSO;

cat << EOF >> $HTTPD_CONF_DIR/20-phpfpm.conf
    <Proxy "balancer://phpfpm_balencer/">
        ${BALANCEMEMBER}
    </Proxy>
    <FilesMatch \.php\$>
        SetHandler "proxy:balancer://phpfpm_balencer"
    </FilesMatch>
EOF

fi

#
# Run

if [[ ! -z "$1" ]]; then
    exec ${*}
else
    exec httpd-foreground
fi
