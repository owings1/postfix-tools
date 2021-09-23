#!/bin/bash

set -e

source "$(dirname "$0")/../../../scripts/helpers/common.sh"

dir_="$(abs $(dirname "$0"))"

# misc: bashrc, nanorc, aliases, environment
cp -b "$dir_/bashrc" /root/.bashrc
cp -b "$dir_/nanorc" /root/.nanorc
cp -b "$dir_/aliases" "$dir_/environment" /etc

/usr/bin/newaliases