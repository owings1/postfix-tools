#!/bin/bash

shopt -s expand_aliases

alias doveadm=/usr/bin/doveadm
alias doveconf=/usr/bin/doveconf
alias dovecot=/usr/sbin/dovecot
alias postfix=/usr/sbin/postfix
alias postmap=/usr/sbin/postmap
alias postconf=/usr/sbin/postconf

if [[ -t 0 ]]; then
    cReset='\033[0m'
    cRed='\033[0;31m'
    cGreen='\033[0;32m'
    cOrange='\033[0;33m'
    cBlue='\033[0;34m'
    cMagenta='\033[0;35m'
    cCyan='\033[0;36m'
    cGreyLight='\033[0;37m'
    cGrey='\033[1;30m'
    cRedLight='\033[1;31m'
    cGreenLight='\033[1;32m'
    cYellow='\033[1;33m'
    cBlueLight='\033[1;34m'
    cMagentaLight='\033[1;35m'
    cCyanLight='\033[1;36m'
    cWhite='\033[1;37m'
    cWhiteBright='\u001b[37;1m'
fi

if [[ -z "$CONFIG_REPO" ]]; then
    CONFIG_REPO="/etc/postfix/repo"
fi

if [[ ! -e "$CONFIG_REPO" ]]; then
    echo "${cRed}ERROR${cReset} $CONFIG_REPO does not exist" >&2
    exit 1
fi

SASL_SPOOL="/var/spool/postfix/var/run/saslauthd"

abs() {
    echo `cd "$1" && pwd`
}

date_path() {
    date +"%Y-%m-%d-%H-%M-%s"
}

postfix_reload() {
    echo "Checking if postfix is up"
    if postfix status; then
        echo "Reloading config"
        postfix reload
        echo "Reconfigured"
    else
        echo "Postfix is not running"
    fi
}

is_dovecot() {
    command -v /usr/sbin/dovecot > /dev/null
}

is_saslauthd() {
    command -v /usr/sbin/saslauthd > /dev/null
}

is_firstrun() {
    [[ ! -e /etc/first-run ]]
}

is_docker() {
    grep -sq 'docker\|lxc' /proc/1/cgroup
}

dovecot_reload() {
    if is_dovecot; then
        if service dovecot status; then
            dovecot reload
        fi
    fi
}

check_okpassword() {
    local pwd="$1"
    local raw="$(cracklib-check <<< "$pwd")"
    if [[ "$(awk '{print $NF}' <<< "$raw")" = 'OK' ]]; then
        return 0
    fi
    local idx="$(expr "${#pwd}" + 3)"
    echo "$(cut "-c$idx-" <<< "$raw")"
    return 1
}

md5cmp() {
    [[ -e "$1" ]] &&
    [[ -e "$2" ]] &&
    [[ "$(md5sum < "$1")" = "$(md5sum < "$2")" ]]
}

port_number() {
    local name="$1"
    if [[ "$name" =~ ^[0-9]+$ ]]; then
        echo "$name"
    else
        getent services "$name" | awk '{print $2}' | sed s-/.*--
    fi
}

postfix_smtp_ports() {
    postconf -F '*/inet/command' | grep ' = smtpd$' | sed 's-/.*--' |
    while read port; do port_number "$port"; done
}

pushdq() {
    pushd "$1" > /dev/null
}

popdq() {
    popd > /dev/null
}

APP_LOGS=(
    /var/log/auth.log
    /var/log/dovecot.err
    /var/log/dovecot.log
    /var/log/mail.err
    /var/log/mail.log
    /var/log/postfix.log
    /var/log/syslog
)