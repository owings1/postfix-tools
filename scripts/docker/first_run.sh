#!/bin/bash
source "$(dirname "$0")/../helpers/common.sh"
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
    alias metaval="$dir_/../helpers/metaval"

    groupadd -g 500 postmaster || true
    useradd -m -g postmaster -s /usr/sbin/nologin postmaster || true

    # source
    mkdir -pv "$CONFIG_REPO/files"
    pushdq "$CONFIG_REPO"
    cp -nv "$files_/meta.json" .
    if is_dovecot ; then
        cp -nv "$files_/dovecot/dovecot.conf" .
        mkdir -pv dovecot
        cp -nv "$files_/dovecot/"10-*.conf dovecot
    fi
    # the main.cf and master.cf may be updated by install scripts
    cp -nv /etc/postfix/main.cf /etc/postfix/master.cf .
    pushdq files
    cp -nv "$files_/destinations" .
    for file in client_checks sender_checks virtual virtual_alias_domains ; do
        if [[ ! -e "$file" ]]; then
            touch "$file"
        fi
    done
    popdq
    # SPF
    if is_spf ; then
        cp -nv "$files_/dkim/policyd-spf.conf" .
    fi
    # srsd
    if is_srsd ; then
        if [[ ! -e /etc/postsrsd.secret ]]; then
            pwgen -s 32 1 > /etc/postsrsd.secret
            chmod 0600 /etc/postsrsd.secret
        fi
        cp -nv "$files_/dkim/postsrsd" postsrsd.conf
        cp -nv /etc/postfix/local_dsn_filter files
    fi
    popdq

    if is_dovecot ; then
        local authdir="$(metaval auth.dir)"
        pwdfile="$authdir/users.passwd"
        mapfile="$authdir/users.map"
        # default auth dir
        mkdir -pv "$authdir"
        touch "$pwdfile"
        passwd_map "$pwdfile"
    fi
}

run
