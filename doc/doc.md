```
openssl s_client -connect localhost:587 -starttls smtp
helo localhost

foo/J97q$?E@J=
auth login
Zm9v
Sjk3cSQ/RUBKPQ==

plain login
AGZvbwBKOTdxJD9FQEo9



mail from: <root@dev>
rcpt to: <file-test-q6e7WSgPLKXeerR2EnAMPaj4d6kHbMAk@mailer2>
RCPT TO: <kate@fabrikam.com>
DATA
Subject: test

This is a test message.
.
```

# Print postfix version

`postconf mail_version`

# Check is running

`sudo systemctl is-active --quiet postfix.service`

# Reload config

`sudo systemctl reload postfix.service`

# Watch logs

`tail -f -n 0 /var/log/mail.err /var/log/mail.log`

# Check queue

`postqueue -p`

# View message (deferred and pending)

`sudo postcat -vq <ID>`
    
# Delete all deferred messages

`sudo postsuper -d ALL deferred`

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
cd ..
sudo rm active
sudo ln -s "$dname" active
```