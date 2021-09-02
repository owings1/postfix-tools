#!/bin/bash
set -e

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

pushdq "$dir_"
cp files/bashrc /root/.bashrc
cp files/aliases /etc/aliases
newaliases
popdq

# source
mkdir -p "$USER_SOURCE/files"
pushdq "$USER_SOURCE"
cp "$dir_/files/meta.json" "$dir_/files/"*.cf .
pushdq files
touch client_checks destinations sender_checks virtual virtual_alias_domains
popdq
popdq

# default ssl
pushdq /etc/postfix
mkdir -p ssl
pushdq ssl
mkdir -p certs/snakeoil dh/build
cp /etc/ssl/private/ssl-cert-snakeoil.key server.key
pushdq certs
cp /etc/ssl/certs/ssl-cert-snakeoil.pem snakeoil/server.crt
cp snakeoil/server.crt snakeoil/ca.crt
ln -s snakeoil active
popdq
pushdq dh
cp "$dir_/files/dh"* build
ln -s build active
popdq
popdq
popdq