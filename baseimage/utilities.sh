#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

$minimal_apt_get_install curl less vim-tiny psmisc gpg-agent dirmngr
ln -s /usr/bin/vim.tiny /usr/bin/vim

cp /bd_build/bin/setuser /sbin/setuser
cp /bd_build/bin/install_clean /sbin/install_clean
