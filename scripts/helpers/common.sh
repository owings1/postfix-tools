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
    echo -e "${cRed}ERROR${cReset} $CONFIG_REPO does not exist" >&2
    exit 1
fi

SASL_SPOOL="/var/spool/postfix/var/run/saslauthd"

abs() {
    echo `cd "$1" && pwd`
}

date_path() {
    date +"%Y-%m-%d-%H-%M-%s"
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

is_systemd() {
    pidof systemd > /dev/null
}

service_up() {
    if is_systemd; then
        systemctl is-active "$1" > /dev/null
    else
        service "$1" status
    fi
}

service_reload() {
    if is_systemd ; then
        systemctl reload "$1"
    else
        service "$1" reload
    fi
}

service_start() {
    if is_systemd ; then
        systemctl start "$1"
    else
        service "$1" start
    fi
}

service_stop() {
    if is_systemd ; then
        systemctl stop "$1"
    else
        service "$1" stop
    fi
}

dovecot_reload() {
    if is_dovecot; then
        echo "Checking if dovecot is up"
        if service_up dovecot; then
            echo "Reloading dovecot config"
            service_reload dovecot
            echo "Reloaded dovecot config"
        else
            echo "Dovecot is not running"
        fi
    fi
}

postfix_reload() {
    echo "Checking if postfix is up"
    if service_up postfix; then
        echo "Reloading postfix config"
        service_reload postfix
        echo "Reloaded postfix config"
    else
        echo "Postfix is not running"
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

passwd_map() {
    local pwdfile="$1"
    local mapfile="$pwdfile.map"
    sed 's/:.*/ ./' "$pwdfile" > "$mapfile" &&
    postmap "$mapfile" &&
    echo "Updated passwd map" >&2
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
    postconf -F '*/inet/command' | grep -P ' = smtpd($|\s)' | sed 's-/.*--' |
    while read port; do port_number "$port"; done
}

pushdq() {
    pushd "$1" > /dev/null
}

popdq() {
    popd > /dev/null
}

APP_LOGS=(
    coordinator.log
    auth.log
)
if is_dovecot; then
    APP_LOGS+=(
        dovecot.debug
        dovecot.log
        dovecot.err
    )
fi
APP_LOGS+=(
    postfix.debug
    postfix.log
    postfix.err
    reconfigure.log
    mail.err
    mail.log
    syslog
)