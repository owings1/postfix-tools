#!/bin/bash

cp /etc/hosts /var/spool/postfix/etc/hosts

source "$(dirname "$0")/../helpers/common.sh" || exit 1
alias log="/usr/bin/logger -t coordinator"
dir_="$(abs "$(dirname "$0")")"

syslog="/var/log/syslog"
pfxlog="/var/log/postfix.log"

app_services=("postfix")
if is_dovecot ; then
    app_services+=("dovecot")
elif is_saslauthd ; then
    app_services+=("saslauthd")
fi
all_services=("rsyslog" "${app_services[@]}")

start_all() {
    local svc
    log 'Starting services'
    postconf -e "maillog_file = $pfxlog"
    for svc in "${app_services[@]}" ; do
        service "$svc" start
    done
    log 'Started services'
}

stop_all() {
    local svc
    log 'Stopping services'
    for svc in "${app_services[@]}" ; do
        service "$svc" stop
    done
    service rsyslog stop
}

reload_all() {
    local svc
    log 'Reloading services'
    for svc in "${app_services[@]}" ; do
        service "$svc" reload
    done
}

on_sighup() {
    log "SIGHUP"
    reload_all
}

on_sigint() {
    log "SIGINT"
    stop_all
    kill -SIGTERM "$logpid"
}

on_sigterm() {
    log "SIGTERM"
    stop_all
    kill -SIGTERM "$logpid"
}

"$dir_/fix_perms.sh"

service rsyslog start || exit 1

if is_firstrun ; then
    "$dir_/first_run.sh" 2>&1 | logger -t first-run
    touch /etc/first-run
fi

/app/scripts/reconfigure 2>&1 | logger -t reconfigure

exit=0

tail -F -n 100 "${APP_LOGS[@]}" 2>/dev/null &
logpid="$!"

trap on_sighup SIGHUP
trap on_sigint SIGINT
trap on_sigterm SIGTERM

verify_up() {
    local svc
    for svc in "${all_services[@]}" ; do
        if ! service "$svc" status 2>&1 1>/dev/null ; then
            echo "FATAL: $svc failed to start" >&2
            exit=1
        fi
    done
    if [[ "$exit" != 0 ]]; then
        stop_all
        kill -SIGTERM "$logpid"
    else
        log "Services are running"
    fi
}

start_all
sleep 5
verify_up

wait "$logpid"
exit "$exit"