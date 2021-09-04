#!/bin/bash
set -e
# See: https://wiki.debian.org/PostfixAndSASL

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"

# pam
pushdq /etc/pam.d
cp -b "$files_/common-password" .
# copy template for smtp service
cp -an other smtp
popdq

# postfix main.cf - basically you want:
#      smtpd_sasl_local_domain = $myhostname
#      smtpd_sasl_auth_enable = yes
#      broken_sasl_auth_clients = yes
#      smtpd_sasl_security_options = noanonymous
#      smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination
if [[ -z "$(postconf -h smtpd_sasl_local_domain)" ]]; then
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
fi
postconf -e \
    'smtpd_sasl_auth_enable = yes' \
    'broken_sasl_auth_clients = yes' \
    'smtpd_sasl_security_options = noanonymous noplaintext'
confkey='smtpd_relay_restrictions'
restricts=('permit_mynetworks' 'permit_sasl_authenticated' 'reject_unauth_destination')
newvalue="$(postconf -h "$confkey")"
for val in "${restricts[@]}" ; do
    if [[ ! "$newvalue" =~ "$val" ]]; then
        newvalue="$newvalue $val"
    fi
done
postconf -e "$confkey = $newvalue"
