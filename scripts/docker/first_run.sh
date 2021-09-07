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
    useradd -m -g postmaster -s /bin/bash postmaster || true

    # source
    mkdir -pv "$CONFIG_REPO/files"
    pushdq "$CONFIG_REPO"
    cp -nv "$files_/meta.json" .
    if is_dovecot ; then
        cp -nv "$files_/dovecot.conf" .
        mkdir -pv dovecot
        cp -nv "$files_/"10-*.conf dovecot
    fi
    # the main.cf and master.cf may be updated by install scripts
    cp -nv /etc/postfix/main.cf /etc/postfix/master.cf "$files_/destinations" .
    pushdq files
    for file in client_checks sender_checks virtual virtual_alias_domains ; do
        if [[ ! -e "$file" ]]; then
            touch "$file"
        fi
    done
    popdq
    popdq

    if is_dovecot ; then
        local pwdfile="$(metaval auth.file)"
        local authdir="$(dirname "$pwdfile")"
        # default auth dir
        mkdir -pv "$authdir"
        touch "$pwdfile" "$pwdfile.map"
        passwd_map "$pwdfile"
    fi
}

run
