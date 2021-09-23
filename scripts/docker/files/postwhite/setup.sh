#!/bin/bash

set -e

source "$(dirname "$0")/../../../helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

cp "$dir_/postwhite.conf" /etc/