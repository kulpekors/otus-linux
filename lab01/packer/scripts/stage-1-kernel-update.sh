#!/bin/bash

#yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm 
#yum --enablerepo elrepo-kernel install kernel-ml -y

dnf install -y bzip2 tar python3 perl bc flex bison make gcc openssl-devel elfutils-libelf-devel

cd /usr/src/kernels
curl -O https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.0.7.tar.xz
tar xpf linux-6.0.7.tar.xz
cd linux-6.0.7

cp -p /boot/config-$(uname -r) .config

make olddefconfig &&
sed -ri '/CONFIG_SYSTEM_TRUSTED_KEYS/s/=.+/=""/g' .config
sed -ri '/CONFIG_DEBUG_INFO_BTF/s/=.+/=n/g' .config

make &&
make modules &&
make modules_install &&
make install &&

grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."

shutdown -r now
