#!/bin/bash

set -e

source "$(dirname "$0")/../helpers/common.sh"

chown root:syslog /var/log
chmod 0775 /var/log
touch /var/log/syslog

pushdq /var/log
for file in "${APP_LOGS[@]}" ; do
    if [[ -e "$file" ]]; then
        chown syslog:adm "$file"
    fi
done
popdq

chown syslog:adm /var/spool/rsyslog
chown postfix:postfix /var/lib/postfix

pushdq /var/spool/postfix
chown -R postfix:root \
    active \
    bounce \
    corrupt \
    defer \
    deferred \
    flush \
    incoming \
    private \
    saved
chown -R postfix:postdrop \
    maildrop \
    public
popdq

pushdq /usr/sbin
chown root:postdrop \
    postdrop \
    postqueue
popdq

if is_dkim_enabled; then
    chown -R opendkim:opendkim /etc/opendkim
    mkdir -p /var/spool/postfix/opendkim
    chown opendkim:postfix /var/spool/postfix/opendkim
    chmod 0775 /var/spool/postfix/opendkim
fi