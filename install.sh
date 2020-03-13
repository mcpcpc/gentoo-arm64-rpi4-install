DEVICE=sda
STAGE3=https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20200311T214502Z/hardened/stage3-amd64-hardened-20200311T214502Z.tar.xz
parted -a optimal /dev/${DEVICE} -s print
parted -a optimal /dev/${DEVICE} -s mklabel gpt
parted -a optimal /dev/${DEVICE} -s rm 1
parted -a optimal /dev/${DEVICE} -s rm 2
parted -a optimal /dev/${DEVICE} -s rm 3
parted -a optimal /dev/${DEVICE} -s unit mib
parted -a optimal /dev/${DEVICE} -s mkpart primary 1 3
parted -a optimal /dev/${DEVICE} -s name 1 grub
parted -a optimal /dev/${DEVICE} -s set 1 bios_grub on
parted -a optimal /dev/${DEVICE} -s mkpart primary 3 131
parted -a optimal /dev/${DEVICE} -s name 2 boot
parted -a optimal /dev/${DEVICE} -s mkpart primary 131 -1
parted -a optimal /dev/${DEVICE} -s name 3 rootfr
parted -a optimal /dev/${DEVICE} -s set 2 boot on
mkfs.ext4 /dev/${DEVICE}2
mkfs.ext4 /dev/${DEVICE}3

mount /dev/sda3 /mnt/gentoo

ntpd -q -g
cd /mnt/gentoo
wget ${STAGE3}
tar xpvf stage3-* --xattrs-include='*.*' --numeric-owner

mirrorselect -s3 -b10 -D -c USA >> /mnt/gentoo/etc/portage/make.conf
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
mount /dev/${DEVICE}2 /boot

emerge-webrsync
emerge --sync --quiet
emerge --ask --verbose --update --deep --newuse @world

echo "US/Eastern" > /etc/timezone
emerge --config sys-libs/timezone-data

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
eselect locale set 4
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

emerge --ask sys-kernel/gentoo-sources
emerge --ask sys-apps/pciutils
cd /usr/src/linux
make menuconfig
