#!/bin/bash
# See https://github.com/roehling/postsrsd
# See https://github.com/zoni/postforward

set -e

source "$(dirname "$0")/../../../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

cp "$dir_/postsrsd" /etc/default/
rm -f /etc/postsrsd.secret
echo '""/^(2\S+ deliver(s|ed) to file).+/"    $1
"/^(2\S+ deliver(s|ed) to command).+/" $1
"/^(\S+ Command died with status \d+):.*(\. Command output:.*)/" $1$2
' > /etc/postfix/local_dsn_filter