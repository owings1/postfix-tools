#!/bin/bash

set -e

source "$(dirname "$0")/../helpers/common.sh"

dir_="$(abs "$(dirname "$0")")"
files_="$dir_/files"

echo "First run ..."

# source
mkdir -p "$CONFIG_REPO/files"
pushdq "$CONFIG_REPO"
cp -nv "$files_/meta.json" "$files_/"*.cf "$files_/"*.conf .
pushdq files
touch client_checks destinations sender_checks virtual virtual_alias_domains
popdq
popdq
