#!/bin/bash

source "$(dirname "$0")/../helpers/common.sh" || exit 1

dir_="$(abs "$(dirname "$0")")"

if [[ ! -e /etc/first-run ]]; then
    "$dir_/first_run.sh"
    touch /etc/first-run
fi

/app/scripts/reconfigure

exit=0
logfiles=(
    /var/log/syslog /var/log/auth.log /var/log/postfix.log
    /var/log/mail.log /var/log/mail.err
)
rm -f "${logfiles[@]}"
touch "${logfiles[@]}"
chown syslog:adm "${logfiles[@]}"

start_syslog() {
    service rsyslog start 2>&1 >> /var/log/syslog
}

start_postfix() {
    postconf maillog_file=/var/log/postfix.log
    postfix start 2>&1 >> /var/log/syslog
}

start_sasl() {
    service saslauthd start 2>&1 >> /var/log/syslog
}

start_dovecot() {
    service dovecot start 2>&1 >> /var/log/syslog
}

stop_all() {
    postfix stop 2>&1 >> /var/log/syslog
    service saslauthd stop 2>&1 >> /var/log/syslog
    service dovecot stop 2>&1 >> /var/log/syslog
    service rsyslog stop 2>&1 >> /var/log/syslog
    kill -SIGTERM "$logpid"
}

reload() {
    postfix reload 2>&1 >> /var/log/syslog
    service saslauthd reload 2>&1 >> /var/log/syslog
}

on_sighup() {
    echo "SIGHUP" >> /var/log/syslog
    sleep 10
    reload
}

on_sigint() {
    echo "SIGINT" >> /var/log/syslog
    stop_all
}

on_sigterm() {
    echo "SIGTERM" >> /var/log/syslog
    stop_all
}

tail -f -n 100 "${logfiles[@]}" &
logpid="$!"

start_syslog
start_postfix
start_sasl
start_dovecot

trap on_sighup SIGHUP
trap on_sigint SIGINT
trap on_sigterm SIGTERM

wait "$logpid"
exit "$exit"