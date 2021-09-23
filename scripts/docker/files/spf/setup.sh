#!/bin/bash
# See https://git.launchpad.net/spf-engine
# See https://www.linode.com/docs/email/postfix/configure-spf-and-dkim-in-postfix-on-debian-9

set -e

source "$(dirname "$0")/../../../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

cp "$dir_/policyd-spf.conf" /etc/postfix-policyd-spf-python



