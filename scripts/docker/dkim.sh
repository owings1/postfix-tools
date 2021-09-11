#!/bin/bash
set -e
source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"

adduser postfix opendkim

# patch init scripts
cp "$files_/dkim/init" /etc/init.d/opendkim
cp "$files_/dkim/default" /etc/default/opendkim

cp "$files_/dkim/opendkim.conf" /etc/
chmod 0644 /etc/opendkim.conf

mkdir -p /etc/opendkim/keys
chown -R opendkim:opendkim /etc/opendkim
chmod go-rw /etc/opendkim/keys
pushdq /etc/opendkim
touch signing.table key.table trusted.hosts
popdq
