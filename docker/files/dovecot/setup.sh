#!/bin/bash
# See: https://wiki.debian.org/PostfixAndSASL
# See: https://www.linuxbabe.com/mail-server/secure-email-server-ubuntu-postfix-dovecot

set -e

source "$(dirname "$0")/../../../scripts/helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

adduser dovecot mail

pushdq /etc/dovecot
cp -ab "$dir_/dovecot.conf" .
cp "$dir_/dh4096.pem" .
pushdq conf.d
cp -ab "$dir_/"10-*.conf .
popdq
popdq

# postconf
postconf -e \
    'smtpd_sasl_auth_enable = yes' \
    'smtpd_sasl_security_options = noanonymous' \
    'smtpd_sasl_type = dovecot' \
    'smtpd_sasl_path = private/auth' \
    'mailbox_transport = lmtp:unix:private/dovecot-lmtp' \
    'smtputf8_enable = no'
if [[ -z "$(postconf -h smtpd_sasl_local_domain)" ]]; then
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
fi

# Edits:
#
# main.cf
# --------
#      smtpd_sasl_local_domain = $myhostname
#      smtpd_sasl_auth_enable = yes
#      smtpd_sasl_security_options = noanonymous
#
# dovecot.conf
# ------------
#    protocols = imap lmtp
#
# 10-mail.conf
# ------------
#     mail_location = maildir:~/Maildir
#     mail_privileged_group = mail
#
# 10-master.conf
# ------------
#     service auth {
#       unix_listener /var/spool/postfix/private/auth {
#         mode = 0660
#         user = postfix
#         group = postfix
#       }
#     }
#     service lmtp {
#      unix_listener /var/spool/postfix/private/dovecot-lmtp {
#        mode = 0600
#        user = postfix
#        group = postfix
#       }
#     }
#
# 10-auth.conf
# ------------
#     disable_plaintext_auth = yes
#     auth_username_format = %n
#     auth_mechanisms = plain login
#
# 10-ssl.conf
# ------------
#     ssl = yes
#     ssl_prefer_server_ciphers = yes
#     ssl_min_protocol = TLSv1.2
#     ssl_dh = </etc/dovecot/dh4096.pem