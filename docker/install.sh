#!/bin/bash
set -e

mkdir -p "$CONFIG_REPO"

source "$(dirname "$0")/../scripts/helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"
scripts_="$(abs "$dir_/../scripts")"
helpers_="$scripts_/helpers"
nanorc_="$(abs "$dir_/../nanorc")"

# Compatibility symlink
ln -s /app /opt/postfix-tools

# Dsable kernel logging for docker
sed -i 's/^module.*"imklog".*/#\0/' /etc/rsyslog.conf

# rsyslog
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

# nano syntax files
mkdir -p /usr/share/nano
cp "$nanorc_/"*.nanorc /usr/share/nano

# Install default main.cf and master.cf
pushdq /etc/postfix
cp "$files_/"*.cf .
# Must have new line at end of main.cf, or postconf has trouble.
echo >> main.cf
popdq

# Misc files
"$files_/misc/setup.sh"

# Default SSL
"$files_/ssl/setup.sh"

# Postwhite
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