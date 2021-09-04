#!/bin/bash

cp /etc/hosts /var/spool/postfix/etc/hosts

source "$(dirname "$0")/../helpers/common.sh" || exit 1

dir_="$(abs "$(dirname "$0")")"

syslog="/var/log/syslog"
pfxlog="/var/log/postfix.log"

logfiles=(
    "$syslog"
    /var/log/auth.log
    "$pfxlog"
    /var/log/mail.log
    /var/log/mail.err
    /var/log/dovecot.log
    /var/log/dovecot.err
)
rm -f "${logfiles[@]}"
#touch "${logfiles[@]}"
#chown syslog:adm "${logfiles[@]}"

service rsyslog start || exit 1
alias log="/usr/bin/logger -it cmd"

if [[ ! -e /etc/first-run ]]; then
    "$dir_/first_run.sh" 2>&1 | logger -it first-run
    touch /etc/first-run
fi

/app/scripts/reconfigure 2>&1 | logger -it reconfigure

exit=0

start_all() {
    log 'Starting services'
    local ret=0
    (
        postconf -e "maillog_file = $pfxlog"
        postfix start || ret=1
        if is_dovecot ; then
            service dovecot start || ret=1
        elif is_saslauthd ; then
            service saslauthd start || ret=1
        fi || ret=1
    ) 2>&1 | log
    return "$ret"
}

stop_all() {
    log 'Stopping services'
    (
        postfix stop ;
        if is_dovecot ; then
            service dovecot stop 
        elif is_saslauthd ; then
            service saslauthd stop
        fi;
        service rsyslog stop
    ) 2>&1 | log
}

reload_all() {
    (
        postfix reload ;
        if is_dovecot ; then
            service dovecot reload
        elif is_saslauthd ; then
            service saslauthd reload
        fi
    ) 2>&1 | log
}

on_sighup() {
    log "SIGHUP"
    reload_all
}

on_sigint() {
    log "SIGTERM"
    stop_all
    kill -SIGTERM "$logpid"
}

on_sigterm() {
    log "SIGTERM"
    stop_all
    kill -SIGTERM "$logpid"
}

tail -F -n 100 "${logfiles[@]}" 2>/dev/null &
logpid="$!"

start_all #|| echo "FATAL: Some services failed to start" >&2 && exit 1

trap on_sighup SIGHUP
trap on_sigint SIGINT
trap on_sigterm SIGTERM

wait "$logpid"
exit "$exit"