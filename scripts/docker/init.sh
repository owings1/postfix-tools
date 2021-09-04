#!/bin/bash
set -e

mkdir -p "$CONFIG_REPO"

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"

pushdq /etc
# chroot files
cp services host.conf hosts localtime nsswitch.conf resolv.conf /var/spool/postfix/etc
popdq

pushdq "$dir_"
# environment
echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/app/scripts' > /etc/environment
# bashrc
cp files/bashrc /root/.bashrc
# aliases
cp files/aliases /etc/aliases
newaliases
popdq

pushdq /etc/postfix
# install config
cp "$files_/"*.cf .
#touch client_checks destinations sender_checks virtual virtual_alias_domains
# default ssl
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
cp "$files_/dh"* build
ln -s build active
popdq
popdq
popdq