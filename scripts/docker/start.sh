#!/bin/bash

cp /etc/hosts /var/spool/postfix/etc/hosts

source "$(dirname "$0")/../helpers/common.sh" || exit 1
alias log="/usr/bin/logger -t coordinator"
dir_="$(abs "$(dirname "$0")")"

app_services=("postfix")
if is_dovecot ; then
    app_services+=("dovecot")
elif is_saslauthd ; then
    app_services+=("saslauthd")
fi
if is_srsd ; then
    app_services+=("postsrsd")
fi
all_services=("rsyslog" "${app_services[@]}")

start_all() {
    local svc
    log 'Starting services'
    for svc in "${app_services[@]}" ; do
        service_start "$svc"
    done
    log 'Started services'
}

stop_all() {
    local svc
    log 'Stopping services'
    for svc in "${app_services[@]}" ; do
        service_stop "$svc"
    done
    service_stop rsyslog
}

reload_all() {
    local svc
    log 'Reloading services'
    for svc in "${app_services[@]}" ; do
        service_reload "$svc"
    done
}

on_sighup() {
    log "SIGHUP"
    reload_all
}

on_sigint() {
    log "SIGINT"
    stop_all
    kill -SIGTERM "$mainpid"
}

on_sigterm() {
    log "SIGTERM"
    stop_all
    kill -SIGTERM "$mainpid"
}

"$dir_/fix_perms.sh"

service_start rsyslog || exit 1

logfiles=("${APP_LOGS[@]}")
if is_firstrun ; then
    logfiles=(first-run.log "${logfiles[@]}")
fi

pushdq /var/log
tail -F -n 0 "${logfiles[@]}" 2>/dev/null &
mainpid="$!"
popdq

exit=0

if is_firstrun ; then
    if "$dir_/first_run.sh" ; then
        touch /etc/first-run
    else
        echo "FATAL: first_run.sh failed" >&2
        exit=1
    fi
fi

if ! LOGONLY=1 /app/scripts/reconfigure ; then
    echo "FATAL: reconfigure failed" >&2
    exit=1
fi

trap on_sighup SIGHUP
trap on_sigint SIGINT
trap on_sigterm SIGTERM

verify_up() {
    local svc
    for svc in "${all_services[@]}" ; do
        if ! service_up "$svc" 2>&1 1>/dev/null ; then
            echo "FATAL: $svc failed to start" >&2
            exit=1
        fi
    done
    if [[ "$exit" != 0 ]]; then
        stop_all
        kill -SIGTERM "$mainpid"
    else
        log "Services are running"
    fi
}

start_all
sleep 5
verify_up

wait "$mainpid"
exit "$exit"