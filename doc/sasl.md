
```
testsaslauthd -u foo -p bar -f /var/spool/postfix/var/run/saslauthd/mux -s smtp
```

## setup

https://wiki.debian.org/PostfixAndSASL

https://www.linuxbabe.com/mail-server/secure-email-server-ubuntu-postfix-dovecot

----


```
apt install -y --no-install-recommends libsasl2-modules sasl2-bin
```

Create a file /etc/postfix/sasl/smtpd.conf:
```
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN
```

```
cp /etc/default/saslauthd /etc/default/saslauthd-postfix
```

and edit it
```
START=yes
DESC="SASL Auth. Daemon for Postfix"
NAME="saslauthd-postf"      # max. 15 char.
# Option -m sets working dir for saslauthd (contains socket)
OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"        # postfix/smtp in chroot()
```

```
dpkg-statoverride --add root sasl 710 /var/spool/postfix/var/run/saslauthd
```

```
adduser postfix sasl
```

postconf:

```
smtpd_sasl_local_domain = $myhostname
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
smtpd_sasl_security_options = noanonymous
smtpd_recipient_restrictions = ... permit_sasl_authenticated
smtpd_tls_auth_only = yes
```


