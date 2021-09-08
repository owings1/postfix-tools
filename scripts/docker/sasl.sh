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

if [[ -z "$(postconf -h smtpd_sasl_local_domain)" ]]; then
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
fi
postconf -e \
    'smtpd_sasl_auth_enable = yes' \
    'smtpd_sasl_security_options = noanonymous'
confkey='smtpd_relay_restrictions'
confval='permit_sasl_authenticated'
val="$(postconf -h "$confkey")"
if [[ ! "$val" =~ "$confval" ]]; then
    postconf -e "$confkey = $val $confval"
fi

# main.cf
# --------
#      smtpd_sasl_local_domain = $myhostname
#      smtpd_sasl_auth_enable = yes
#      smtpd_sasl_security_options = noanonymous
#      smtpd_relay_restrictions = permit_sasl_authenticated ...