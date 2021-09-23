#!/bin/bash
set -e

mkdir -p "$CONFIG_REPO"

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"
scripts_="$(abs "$dir_/..")"
helpers_="$scripts_/helpers"

# Compatibility symlink
ln -s /app /usr/local/src/postfix-tools

# Dsable kernel logging for docker
sed -i 's/^module.*"imklog".*/#\0/' /etc/rsyslog.conf
# copy rsyslog conf
cp "$files_/syslog/"* /etc/rsyslog.d/

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
cp "$scripts_/nanorc/"*.nanorc /usr/share/nano
# bashrc nanorc
cp misc/bashrc /root/.bashrc
cp misc/nanorc /root/.nanorc
# aliases, environment
cp misc/aliases misc/environment /etc
newaliases
popdq

pushdq /etc/postfix
# install default config
cp "$files_/"*.cf .
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

# postwhite
"$files_/postwhite/setup.sh"

# Dovecot
if is_dovecot ; then
    "$files_/dovecot/setup.sh"
fi

# SPF
if is_spf ; then
    "$files_/spf/setup.sh"
fi

# SRSD
if is_srsd ; then
    "$files_/srsd/setup.sh"
fi

# DKIM
if is_dkim; then
    "$files_/dkim/setup.sh"
fi