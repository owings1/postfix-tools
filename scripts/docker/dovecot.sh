#!/bin/bash
set -e
# See: https://www.linuxbabe.com/mail-server/secure-email-server-ubuntu-postfix-dovecot

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"

adduser dovecot mail

pushdq /etc/dovecot
# dovecot.conf
# ------------
#    protocols = imap lmtp
cp -ab "$files_/dovecot.conf" .
pushdq conf.d

# 10-mail.conf
# ------------
#     mail_location = maildir:~/Maildir
#     mail_privileged_group = mail
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
# 10-auth.conf
# ------------
#     disable_plaintext_auth = yes
#     auth_username_format = %n
#     auth_mechanisms = plain login
# 10-ssl.conf
# ------------
#     ssl = yes
#     ssl_prefer_server_ciphers = yes
#     ssl_min_protocol = TLSv1.2
#   TODO:
#     ssl_cert = </etc/dovecot/private/dovecot.pem
#     ssl_key = </etc/dovecot/private/dovecot.key
cp -ab "$files_/"10-*.conf .
popdq
popdq


# postconf
postconf -e \
    'mailbox_transport = lmtp:unix:private/dovecot-lmtp' \
    'smtputf8_enable = no'


# missing on minified system
echo 'tty1
tty2
tty3
tty4
ttyS1' > /etc/securetty