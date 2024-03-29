
```
# get delivery report
sendmail -bv <address>
```
https://docs.nginx.com/nginx/admin-guide/mail-proxy/mail-proxy/

```
openssl s_client -connect localhost:587 -starttls smtp
helo localhost

foo/J97q$?E@J=
auth login
Zm9v
Sjk3cSQ/RUBKPQ==

plain login
AGZvbwBKOTdxJD9FQEo9


mail from: <doug@dougowings.net>
rcpt to: <file-test-q6e7WSgPLKXeerR2EnAMPaj4d6kHbMAk>

mail from: <doug@dougowings.net>
rcpt to: <curl-test@mail.dougowings.com>

DATA

Subject: test

This is a test message.
.
```

```
# Print postfix version

postconf mail_version

# Check is running

sudo systemctl is-active --quiet postfix.service

```

```
# Check queue

postqueue -p

# Flush queue

postqueue -f

# View message (deferred and pending)

sudo postcat -vq <ID>
    
# Delete all deferred messages

sudo postsuper -d ALL deferred
```


```
# Get sha2 of cert

openssl x509 -fingerprint -sha256 -noout -in cert.pem 
```

```
## Create DKIM key

# See: https://www.linode.com/docs/email/postfix/configure-spf-and-dkim-in-postfix-on-debian-9

# Set vars
ID=<YYYYMM>
DOMAIN=<my.domain>

# Gen key
cd /etc/opendkim
opendkim-genkey -b 2048 -h rsa-sha256 -r -s "$ID" -d "$DOMAIN" -v
mv "$ID.private" "keys/$ID.$DOMAIN.private"
mv "$ID.txt" "keys/$ID.$DOMAIN.txt"

# extract string from .txt, replace h=rsa-sha256 with h=sha256, save to keys/$ID.$DOMAIN.txt.value
sed -E \
  -e 's~^.*\( ~~' \
  -e 's~h=rsa-sha256~h=sha256~' \
  -e 's~ \)\s+; ----- DKIM.*~~' \
  -e 's~\s{2,}~~' \
  "keys/$ID.$DOMAIN.txt" \
  | tr -d '\n' \
  > "keys/$ID.$DOMAIN.txt.value"


# Set perms
chown opendkim:opendkim keys/*
chmod 0600 keys/*

# create DNS record $ID._domainkey

# Test record
opendkim-testkey -d "$DOMAIN" -s "$ID"

# Add records to signing.table and key.table

# Restart opendkim
systemctl restart opendkim
systemctl status opendkim
```

```
#--------------#
# Check TLS    #
#--------------#

echo 'From: test <root@mail.dougowings.com>
To: file-test <file-test-Lxeay2BddjjBpX3A9kvCjtDHcFVKu4Az@mail.dougowings.com>
Subject: test

test curl message.' > /tmp/email.txt

curl --url 'smtp://172.17.0.2:587' \
  --user 'foo@mailer2:J97q$?E@J=' \
  --mail-from 'foo@mailer2' \
  --mail-rcpt 'foo@mailer2' \
  --upload-file - <<< \
'From: test <root@mail.dougowings.com>
To: file-test <file-test-Lxeay2BddjjBpX3A9kvCjtDHcFVKu4Az@mail.dougowings.com>
Subject: test

test curl message.'
  --upload-file /tmp/email.txt


openssl s_client -connect mail.dougowings.com:25 \
  -verify_return_error \
  -starttls smtp \
  < /dev/null

openssl s_client -connect mail.dougowings.com:587 \
  -verify_return_error \
  -starttls smtp \
  < /dev/null

#-----------------------------------------------------------
#
#-------------------#
# Rebuild aliases   #
#-------------------#

sudo postmap /etc/postfix/virtual
sudo systemctl reload postfix.service

#-----------------------------------------------------------
#
#-------------------#
# Generate dhparams #
#-------------------#

cd /etc/postfix/ssl/dh
dname=`date '+%Y-%m-%d'`
sudo mkdir "$dname" && cd "$dname"
sudo openssl dhparam -5 -check -out dh512.pem 512
sudo openssl dhparam -5 -check -out dh1024.pem 1024
cd ..
sudo rm active
sudo ln -s "$dname" active

#-----------------------------------------------------------
#
#-------------------# 
# Install new cert  #
#-------------------#

# First upload the zip, e.g.:
#    scp mail_dougowings_com.zip carl:/tmp
#    ssh carl
# Then set the out dirname to the expiry, e.g.:
#    dname='2022-09-30'

cd /etc/postfix/ssl/certs
# set a default value jic
[[ -z "$dname" ]] && dname==`date +%Y-%m-%d`
sudo mkdir "$dname" && cd "$dname"
sudo unzip /tmp/mail_dougowings_com.zip
cat \
  SectigoRSADomainValidationSecureServerCA.crt \
  USERTrustRSAAAACA.crt \
  AAACertificateServices.crt \
  | sudo tee ca.crt
sudo chmod 0644 *.crt
sudo ln -s mail_dougowings_com.crt server.crt
cat server.crt ca.crt | sudo tee server.chained.crt
cd ..
sudo rm active
sudo ln -s "$dname" active
```