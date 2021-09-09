#!/bin/bash
set -e

mkdir -p "$CONFIG_REPO"

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"
helpers_="$(abs "$dir_/../helpers")"

# disable kernel logging for docker
sed -i 's/^module.*"imklog".*/#\0/' /etc/rsyslog.conf
# copy rsyslog conf
cp "$files_/00-template.conf" \
    "$files_/40-custom.conf" \
    "$files_/50-default.conf" \
    /etc/rsyslog.d/

pushdq /etc
# chroot files
cp services host.conf hosts localtime nsswitch.conf resolv.conf \
    /var/spool/postfix/etc
popdq
# missing on minified system
echo 'tty1
tty2
tty3
tty4
ttyS1' > /etc/securetty

pushdq "$files_"
# nano syntax
mkdir -p /usr/share/nano
cp "$helpers_/"*.nanorc /usr/share/nano
# bashrc nanorc
cp bashrc /root/.bashrc
cp nanorc /root/.nanorc
# aliases, environment
cp aliases environment /etc
newaliases
popdq

pushdq /etc/postfix
# install default config
cp "$files_/"*.cf "$files_/destinations" .
# must have new line at end of file
echo >> main.cf
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
# dh params
pushdq dh
cp "$files_/dh512.pem" "$files_/dh1024.pem" build
ln -s build active
popdq
popdq
popdq

if is_dovecot || is_saslauthd ; then
    "$dir_/sasl.sh"
    if is_dovecot; then
        "$dir_/dovecot.sh"
    elif is_saslauthd; then
        "$dir_/saslauthd.sh"
    fi
fi

