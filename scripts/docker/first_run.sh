#!/bin/bash

set -e

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs "$(dirname "$0")")"
files_="$dir_/files"
alias metaval="$dir_/../helpers/metaval"

{
    echo  "First run ..."

    groupadd -g 500 postmaster || true
    useradd -m -g postmaster -s /bin/bash postmaster || true

    #sleep 30
    # source
    mkdir -pv "$CONFIG_REPO/files"
    pushdq "$CONFIG_REPO"
    cp -nv "$files_/meta.json" .
    if is_dovecot ; then
        cp -nv "$files_/"10-*.conf "$files_/dovecot.conf" .
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
        pwdfile="$(metaval auth.file)"
        authdir="$(dirname "$pwdfile")"
        # default auth dir
        mkdir -pv "$authdir"
        touch "$pwdfile" "$pwdfile.map"
        passwd_map "$pwdfile"
    fi
} 2>&1 | /usr/bin/logger -t first-run
