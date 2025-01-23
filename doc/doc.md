```
# Print postfix version

postconf mail_version

# Check is running

systemctl is-active --quiet postfix.service

# Check queue

postqueue -p

# Flush queue

postqueue -f

# View message (deferred and pending)

postcat -vq <ID>
    
# Delete all deferred messages

postsuper -d ALL deferred

# Get sha2 of cert

openssl x509 -fingerprint -sha256 -noout -in cert.pem 
```

