#!/bin/bash
set -e
# See: https://www.linuxbabe.com/mail-server/secure-email-server-ubuntu-postfix-dovecot

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"

adduser dovecot mail

pushdq /etc/dovecot
cp -ab "$files_/dovecot/dovecot.conf" .
cp "$files_/dovecot/dh4096.pem" .
pushdq conf.d
cp -ab "$files_/dovecot/"10-*.conf .
popdq
popdq

# postconf
postconf -e \
    'smtpd_sasl_type = dovecot' \
    'smtpd_sasl_path = private/auth' \
    'mailbox_transport = lmtp:unix:private/dovecot-lmtp' \
    'smtputf8_enable = no'

# Edits:
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