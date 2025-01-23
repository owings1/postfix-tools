#!/bin/bash

set -e

source "$(dirname "$0")/../../../scripts/helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

adduser postfix opendkim

# patch init scripts
cp "$dir_/init" /etc/init.d/opendkim
cp "$dir_/default" /etc/default/opendkim

cp "$dir_/opendkim.conf" /etc/
chmod 0644 /etc/opendkim.conf

mkdir -p "$DKIM_KEYS_DIR"
chown -R opendkim:opendkim /etc/opendkim
chmod go-rw "$DKIM_KEYS_DIR"
pushdq /etc/opendkim
touch signing.table key.table trusted.hosts
popdq
