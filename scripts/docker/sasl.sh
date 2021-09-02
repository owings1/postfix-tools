#!/bin/bash
set -e
# See: https://wiki.debian.org/PostfixAndSASL

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

# add postfix user to sasl group
adduser postfix sasl

# create sasl/smtpd.conf
#   pwcheck_method: saslauthd
#   mech_list: PLAIN LOGIN
if [[ ! -e /etc/postfix/sasl/smtpd.conf ]]; then  
    echo 'pwcheck_method: saslauthd
    mech_list: PLAIN LOGIN' > /etc/postfix/sasl/smtpd.conf
fi

# in a prod env, make a separate saslauthd process for postfix
# copy /etc/default/saslauthd to /etc/default/saslauthd-postfix and edit:
#     START=yes
#     NAME="saslauthd-postf"
#     DESC="SASL Auth. Daemon for Postfix"
#     OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"
# This creates the args to start saslauthd like so:
#   saslauthd -a pam -c -m /var/spool/postfix/var/run/saslauthd -n 5
sed -i "{ 
    s/^START=no/START=yes/ ;
    s/^NAME=\"saslauthd\"/NAME=\"saslauthd-postf\"/ ;
    s/^DESC=\"SASL Authentication Daemon\"/DESC=\"SASL Auth. Daemon for Postfix\"/ ;
    s#^OPTIONS=.*#OPTIONS=\"-c -m $SASL_SPOOL\"#
}" /etc/default/saslauthd

# create required subdirectories in postfix chroot directory
if ! dpkg-statoverride --list "$SASL_SPOOL"; then
    dpkg-statoverride --add root sasl 710 "$SASL_SPOOL"
fi
install -d --owner=root --group=sasl --mode=0710 "$SASL_SPOOL"

# pam
pushd /etc/pam.d > /dev/null
if [[ "$(md5sum common-password)" = "9ad0ccac57090977d7fc74da3adcf381  common-password" ]]; then
    mv -v common-password "common-password_$(date_path)"
    cp -v "$dir_/files/common-password" .
fi
# copy template for smtp service
cp -an other smtp
popd > /dev/null

# postfix main.cf - basically you want:
#      smtpd_sasl_local_domain = $myhostname
#      smtpd_sasl_auth_enable = yes
#      broken_sasl_auth_clients = yes
#      smtpd_sasl_security_options = noanonymous
#      smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination
if false ; then
    if [[ -z "$(postconf -h smtpd_sasl_local_domain)" ]]; then
        postconf -e 'smtpd_sasl_local_domain = $myhostname'
    fi
    postconf -e \
        'smtpd_sasl_auth_enable = yes' \
        'broken_sasl_auth_clients = yes' \
        'smtpd_sasl_security_options = noanonymous'
    confkey='smtpd_relay_restrictions'
    restricts=('permit_mynetworks' 'permit_sasl_authenticated' 'reject_unauth_destination')
    newvalue="$(postconf -h "$confkey")"
    for val in "${restricts[@]}" ; do
        if [[ ! "$newvalue" =~ "$val" ]]; then
            newvalue="$newvalue $val"
        fi
    done
    postconf -e "$confkey = $newvalue"
fi
