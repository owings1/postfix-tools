#!/bin/bash

set -e

source "$(dirname "$0")/../helpers/common.sh"

touch /var/log/syslog
for file in "${APP_LOGS[@]}" ; do
    if [[ -e "$file" ]]; then
        chown syslog:adm "$file"
    fi
done

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