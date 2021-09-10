#!/bin/bash
# See https://git.launchpad.net/spf-engine
# See https://www.linode.com/docs/email/postfix/configure-spf-and-dkim-in-postfix-on-debian-9
# See https://github.com/roehling/postsrsd
# See https://github.com/zoni/postforward

set -e
source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"
files_="$dir_/files"

adduser postfix opendkim

cp "$files_/dkim/policyd-spf.conf" /etc/postfix-policyd-spf-python

if is_srsd ; then
    cp "$files_/dkim/postsrsd" /etc/default/
    rm -f /etc/postsrsd.secret
    echo '/^(2\S+ deliver(s|ed) to file).+/    $1
/^(2\S+ deliver(s|ed) to command).+/ $1
/^(\S+ Command died with status \d+):.*(\. Command output:.*)/ $1$2
' > /etc/postfix/local_dsn_filter
fi

