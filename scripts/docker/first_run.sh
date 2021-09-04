#!/bin/bash

set -e

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs "$(dirname "$0")")"
files_="$dir_/files"

echo "First run ..."

groupadd -g 500 postmaster || true
useradd -m -g postmaster -s /bin/bash postmaster || true

# source
mkdir -p "$CONFIG_REPO/files"
pushdq "$CONFIG_REPO"
cp -nv "$files_/meta.json" "$files_/"*.conf .
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
