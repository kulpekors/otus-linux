Для сборки образа с компиляцией ядра и установкой VBoxGuestAdditions для работы Shared Folders

1. Внесены изменения в json-файл для packer
Увеличен размер диска:
"disk_size": "32768"

Дистрибутив:
"iso_checksum": "a96b15fdea3842de667b2472ee10842db6bd1ec9a7e76f58541b5b0d59433349"
"iso_url": "https://mirror.yandex.ru/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20221005-boot.iso"

Увелилчино количество cpu до 4
      "vboxmanage": [
        [
          "modifyvm",
          "{{.Name}}",
          "--memory",
          "2048"
        ],
        [
          "modifyvm",
          "{{.Name}}",
          "--cpus",
          "4"
        ]
      ],

Изменил название конечного образа:
"output": "centos-{{user `artifact_version`}}-custom-kernel-6.0.7-x86_64-Minimal.box"

Изменил описания:
    "artifact_description": "CentOS Stream 8 with custom kernel 6.0.7",
    "artifact_version": "8",
    "image_name": "centos-8-custom-kernel-6.0.7"


2. Внесены изменения в Kickstart-файл http/ks.cfg:

timezone Asia/Krasnoyarsk

Удалена строчка:
authconfig --enableshadow --passalgo=sha512

Добавлено:

%packages
@^Minimal Install
%end

%post
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/vagrant
%end

3. Внесены изменения в scripts/stage-1-kernel-update.sh

Удалено:
yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm 
yum --enablerepo elrepo-kernel install kernel-ml -y

Добавлено:
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

4. Внесены изменения в scripts/stage-2-clean.sh

Добавлено
mount /home/vagrant/VBoxGuestAdditions.iso /mnt
/mnt/VBoxLinuxAdditions.run --nox11

cd /usr/src/kernels/linux-6.0.7
make clean

# Fill zeros all empty space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync

Удалено:
grub2-set-default 1
echo "###   Hi from secone stage" >> /boot/grub2/grub.cfg


Установка:
packer build centos-8-custom-kernel-6.0.7.json

Сборка с компиляцией ядра занимает около 3-х часов.

В итоге получаем образ centos-8-custom-kernel-6.0.7-x86_64-Minimal.box с компилированным ядром linux 6.0.7 и установленным VBoxGuestAdditions

Загрузим образ в  vagrant cloud

c:\otus-linux\lab01\packer# vagrant cloud publish --release kulpekors/centos-8-custom-kernel-6.0.7 1.0 virtualbox centos-8-custom-kernel-6.0.7-x86_64-Minimal.box
You are about to publish a box on Vagrant Cloud with the following options:
kulpekors/centos-8-custom-kernel-6.0.7:   (v1.0) for provider 'virtualbox'
Automatic Release:     true
Do you wish to continue? [y/N]y
Saving box information...
Uploading provider with file c:/otus-linux/lab01/packer/centos-8-custom-kernel-6.x-x86_64-Minimal.box

Releasing box...
Complete! Published kulpekors/centos-8-custom-kernel-6.0.7
Box:              kulpekors/centos-8-custom-kernel-6.0.7
Description:
Private:          yes
Created:          2022-11-06T08:30:25.660+07:00
Updated:          2022-11-06T08:30:25.660+07:00
Current Version:  N/A
Versions:         1.0
Downloads:        0


В Vagrantfile укажем

config.vm.box = "kulpekors/centos-8-custom-kernel-6.0.7"

Запустим

c:\otus-linux\lab01# vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'kulpekors/centos-8-custom-kernel-6.0.7' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'kulpekors/centos-8-custom-kernel-6.0.7'
    default: URL: https://vagrantcloud.com/kulpekors/centos-8-custom-kernel-6.0.7
==> default: Adding box 'kulpekors/centos-8-custom-kernel-6.0.7' (v1.0) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/kulpekors/boxes/centos-8-custom-kernel-6.0.7/versions/1.0/providers/virtualbox.box
    default: 
==> default: Successfully added box 'kulpekors/centos-8-custom-kernel-6.0.7' (v1.0) for 'virtualbox'!
==> default: Importing base box 'kulpekors/centos-8-custom-kernel-6.0.7'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'kulpekors/centos-8-custom-kernel-6.0.7' version '1.0' is up to date...
==> default: Setting the name of the VM: lab01_default_1667712358769_82349
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: 
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default: 
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
[default] GuestAdditions seems to be installed (6.1.40) correctly, but not running.
Redirecting to /bin/systemctl start vboxadd.service
Redirecting to /bin/systemctl start vboxadd-service.service
/opt/VBoxGuestAdditions-6.1.40/bin/VBoxClient: error while loading shared libraries: libX11.so.6: cannot open shared object file: No such file or directory
/opt/VBoxGuestAdditions-6.1.40/bin/VBoxClient: error while loading shared libraries: libX11.so.6: cannot open shared object file: No such file or directory
VirtualBox Guest Additions: Starting.
VirtualBox Guest Additions: Setting up modules
VirtualBox Guest Additions: Building the VirtualBox Guest Additions kernel 
modules.  This may take a while.
VirtualBox Guest Additions: To build modules for other installed kernels, run
VirtualBox Guest Additions:   /sbin/rcvboxadd quicksetup <version>
VirtualBox Guest Additions: or
VirtualBox Guest Additions:   /sbin/rcvboxadd quicksetup all
VirtualBox Guest Additions: Building the modules for kernel 6.0.7.
VirtualBox Guest Additions: Running kernel modules will not be replaced until 
the system is restarted
Restarting VM to apply changes...
==> default: Attempting graceful shutdown of VM...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Mounting shared folders...
    default: /vagrant => C:/otus-linux/lab01

c:\otus-linux\lab01# vagrant ssh
Last login: Sun Nov  6 00:07:36 2022 from 10.0.2.2
[vagrant@otus-c8 ~]$ uname -a
Linux otus-c8 6.0.7 #1 SMP PREEMPT_DYNAMIC Sat Nov 5 21:41:01 +07 2022 x86_64 x86_64 x86_64 GNU/Linux
[vagrant@otus-c8 ~]$ cat /etc/os-release 
NAME="CentOS Stream"
VERSION="8"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="8"
PLATFORM_ID="platform:el8"
PRETTY_NAME="CentOS Stream 8"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:8"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_SUPPORT_PRODUCT="Red Hat Enterprise Linux 8"
REDHAT_SUPPORT_PRODUCT_VERSION="CentOS Stream"
[vagrant@otus-c8 ~]$ mount -l | grep vbox
vagrant on /vagrant type vboxsf (rw,nodev,relatime,iocharset=utf8,uid=1000,gid=1000,_netdev)
[vagrant@otus-c8 ~]$ ls /vagrant
packer  Vagrantfile  Vagrantfile.bak
[vagrant@otus-c8 ~]$ 

