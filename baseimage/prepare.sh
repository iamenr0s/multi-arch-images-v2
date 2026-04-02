#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

export INITRD=no
mkdir -p /etc/container_environment
echo -n no > /etc/container_environment/INITRD

sed -i 's/^#\s*\(deb.*main restricted\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list
apt-get update

dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

$minimal_apt_get_install apt-utils
$minimal_apt_get_install apt-transport-https ca-certificates
$minimal_apt_get_install software-properties-common

apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"

case $(lsb_release -is) in
 Ubuntu)
 $minimal_apt_get_install language-pack-en
 ;;
 Debian)
 $minimal_apt_get_install locales locales-all
 ;;
 *)
 ;;
esac
locale-gen en_US
update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
echo -n en_US.UTF-8 > /etc/container_environment/LANG
echo -n en_US.UTF-8 > /etc/container_environment/LC_CTYPE
