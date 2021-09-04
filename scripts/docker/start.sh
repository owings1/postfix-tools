#!/bin/bash

source "$(dirname "$0")/../helpers/common.sh" || exit 1

alias log="/usr/bin/logger -it cmd"

dir_="$(abs "$(dirname "$0")")"

if [[ ! -e /etc/first-run ]]; then
    "$dir_/first_run.sh"
    touch /etc/first-run
fi

/app/scripts/reconfigure 2>&1 | logger -it reconfigure

exit=0

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
touch "${logfiles[@]}"
chown syslog:adm "${logfiles[@]}"

start_all() {
    service rsyslog start || return 1
    log 'Starting services'
    local ret=0
    (
        postconf -e "maillog_file = $pfxlog" &&
        postfix start &&
        service saslauthd start &&
        service dovecot start || ret=1
    ) 2>&1 | log
    return "$ret"
}

stop_all() {
    log 'Stopping services'
    (
        postfix stop ;
        service saslauthd stop ;
        service dovecot stop ;
        service rsyslog stop
    ) 2>&1 | log
}

reload_all() {
    (
        postfix reload ;
        service saslauthd reload ;
        service dovecot reload
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

tail -f -n 100 "${logfiles[@]}" &
logpid="$!"

start_all || log "FATAL: Some services failed to start" && exit 1

trap on_sighup SIGHUP
trap on_sigint SIGINT
trap on_sigterm SIGTERM

wait "$logpid"
exit "$exit"