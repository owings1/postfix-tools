https://serverfault.com/questions/785512/setting-up-mail-accounts-without-real-linux-users/785526

muttrc

set imap_user = "bar"
set imap_pass = "J97q$?E@J="
set smtp_url = "smtp://bar@172.17.0.4:587/"
set smtp_pass = "J97q$?E@J="
set ssl_starttls = yes


root@mutt:~# echo 'aA2])(E3p9bKgzbCf!Kd9Y_Nq(QJJqR=' | base64
YUEyXSkoRTNwOWJLZ3piQ2YhS2Q5WV9OcShRSkpxUj0K
root@mutt:~# echo -n 'aA2])(E3p9bKgzbCf!Kd9Y_Nq(QJJqR=' | base64
YUEyXSkoRTNwOWJLZ3piQ2YhS2Q5WV9OcShRSkpxUj0=
root@mutt:~# echo -n '\0doug\0aA2])(E3p9bKgzbCf!Kd9Y_Nq(QJJqR=' | base64
ZG91Zw==
root@mutt:~#

useradd -m -d /home/email/robot -g 515 -u 604 -s /usr/sbin/nologin robot

kjQXn[kW+?P"]c4U(9T?'Dc!;\4^$L!4

https://www.linuxbabe.com/mail-server/secure-email-server-ubuntu-postfix-dovecot

```
auth_verbose = yes
auth_debug = yes
mail_debug = yes
```

recommended 587 in master.cf

```
submission     inet     n    -    y    -    -    smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_wrappermode=no
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
```