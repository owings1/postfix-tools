#!/bin/bash

shopt -s expand_aliases

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

if [[ -z "$USER_SOURCE" ]]; then
    echo "${cRed}ERROR${cReset} USER_SOURCE not set" >&2
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
