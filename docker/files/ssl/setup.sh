#!/bin/bash

set -e

source "$(dirname "$0")/../../../scripts/helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

# Default SSL certs, dhparams
mkdir -p /etc/postfix/ssl/certs/snakeoil /etc/postfix/ssl/dh/build

pushdq /etc/postfix/ssl

# Default key file
cp /etc/ssl/private/ssl-cert-snakeoil.key server.key

# Default certs
pushdq certs
cp /etc/ssl/certs/ssl-cert-snakeoil.pem snakeoil/server.crt
cp snakeoil/server.crt snakeoil/ca.crt
ln -s snakeoil active
popdq

# Default dh params
pushdq dh
cp "$dir_/dh512.pem" "$dir_/dh1024.pem" build
ln -s build active
popdq

popdq