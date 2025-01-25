#!/bin/bash

source "$(dirname "$0")/../scripts/helpers/common.sh"

shopt -s expand_aliases

alias logger="/usr/bin/logger -t first-run"

log() {
    local priority="$1"
    local msg
    while read msg ; do
        logger -p "$priority" "$msg"
    done
}

run() {
    {
        _run 2>&1 1>&3 3>&- | log err
    } 3>&1 1>&2 | log notice
}

_run() {

    set -e

    echo  "First run ..."

    local dir_="$(abs "$(dirname "$0")")"
    local files_="$dir_/files"

    # Create a default postmaster user, referenced in /etc/aliases, since Dovecot
    # does not route to root.
    groupadd -g 500 postmaster || true
    useradd -m -g postmaster -s /usr/sbin/nologin postmaster || true

    ## Install any missing default config files.

    mkdir -pv "$CONFIG_REPO/files"
    pushdq "$CONFIG_REPO"

    # Dovecot
    if is_dovecot ; then
        cp -nv "$files_/dovecot/dovecot.conf" .
        mkdir -pv dovecot
        cp -nv "$files_/dovecot/"10-*.conf dovecot
    fi

    # Postfix config
    # The main.cf and master.cf may be updated by install scripts
    cp -nv /etc/postfix/main.cf /etc/postfix/master.cf .
    pushdq files
    if [[ ! -e destinations ]]; then
        echo 'localhost' > destinations
    fi
    for file in client_checks sender_checks virtual virtual_alias_domains ; do
        if [[ ! -e "$file" ]]; then
            touch "$file"
        fi
    done
    popdq

    # SPF
    if is_spf ; then
        cp -nv "$files_/spf/policyd-spf.conf" .
    fi

    # SRSD
    if is_srsd ; then
        if [[ ! -e /etc/postsrsd.secret ]]; then
            pwgen -s 32 1 > /etc/postsrsd.secret
            chmod 0600 /etc/postsrsd.secret
        fi
        cp -nv "$files_/srsd/postsrsd" postsrsd.conf
        cp -nv /etc/postfix/local_dsn_filter files
    fi
    popdq

    ## Install & setup auth files

    # Dovecot auth files
    if is_dovecot ; then
        local authdir="$AUTH_DIR"
        pwdfile="$authdir/users.passwd"
        mkdir -pv "$authdir"
        touch "$pwdfile"
        passwd_vmbx "$pwdfile"
        passwd_tlsdb "$pwdfile"
    fi
}

run
