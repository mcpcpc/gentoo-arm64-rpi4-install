# Raspberry Pi 4, Gentoo 64-bit - Installation Guide
As a new user to Gentoo, I was disappointed by the available guides for configuring a 64-bit Gentoo OS on a Raspberry Pi 4.  I found them entirely unfriendly to people just getting started and might deter new users from hopping onto the "Gentoo bandwagon".  The following guide is my attempt to compile the information that i found from various sources to make the installation process as **straight-forward** as possible.  Credits to the indvidual sources is at the bottom.

## Hardware Requirements
* Raspberry Pi 4 (or newer)
* 32GB MicroSD Card (user preference)
* SD Card adapter (dependent on platform)
* LAN Connection (must be connected for initial setup)

## Important
* Take notice of the command prefix for when to use `root` and when local `user` for permissions required.
* When logged in as `root`, Replace all instances of `<user>` with the local user name. 
* I will not be creating a swap partition as this shortens the life of the SD card.
* Assumes the user is using the `us` keymaps.
* Assumes the timezone you are in is 'US/Eastern'.  A list of available time zones can be found by running `ls /usr/share/zoneinfo`.

## Building Gentoo System
1. Insert the MicroSD Card into the PC you plan to build the Gentoo system on.
2. Prepare the raspberry pi build.

```console
user@localhost ~ $ cd ~
user@localhost ~ $ git clone https://github.com/raspberrypi/tools
user@localhost ~ $ cd tools/armstubs
user@localhost ~/tools/armstub $ make CC8=aarch64-unknown-linux-gnu-gcc LD8=aarch64-unknown-linux-gnu-ld OBJCOPY8=aarch64-unknown-linux-gnu-objcopy OBJDUMP8=aarch64-unknown-linux-gnu-objdump armstub8-gic.bin
user@localhost ~ $ cd ~
user@localhost ~ $ mkdir ~/raspberrypi
user@localhost ~/raspberrypi $ cd ~/raspberrypi
user@localhost ~/raspberrypi $ git clone -b stable --depth=1 https://github.com/raspberrypi/firmware
user@localhost ~/raspberrypi $ git clone https://github.com/raspberrypi/linux
user@localhost ~/raspberrypi $ cd ~/raspberrypi/linux
user@localhost ~/raspberrypi/linux $ ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make bcm2711_defconfig
user@localhost ~/raspberrypi/linux $ ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make menuconfig
```

3. While in the Kernel configuration menu, set the  Default CPUFreq governor to 'ondemand' (see example below).

```
.config - Linux/arm64 4.14.72-raspberrypi Kernel Configuration
 > CPU Power Management > CPU Frequency scaling ──────────────────────────────────
  ┌────────────────────────── CPU Frequency scaling ───────────────────────────┐
  │  Arrow keys navigate the menu.  <Enter> selects submenus ---> (or empty    │  
  │  submenus ----).  Highlighted letters are hotkeys.  Pressing <Y> includes, │  
  │  <N> excludes, <M> modularizes features.  Press <Esc><Esc> to exit, <?>    │  
  │  for Help, </> for Search.  Legend: [*] built-in  [ ] excluded  <M> module │  
  │ ┌────────────────────────────────────────────────────────────────────────┐ │  
  │ │    [*] CPU Frequency scaling                                           │ │  
  │ │    [*]   CPU frequency transition statistics                           │ │  
  │ │    [ ]     CPU frequency transition statistics details                 │ │  
  │ │          Default CPUFreq governor (powersave)  --->                    │ │  
  │ │    <*>   'performance' governor                                        │ │  
  │ │    -*-   'powersave' governor                                          │ │  
  │ │    <*>   'userspace' governor for userspace frequency scaling          │ │  
  │ │    <*>   'ondemand' cpufreq policy governor                            │ │  
```

4. Build the Kernel.

```console
user@localhost ~/raspberrypi/linux $ ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j5
user@localhost ~/raspberrypi/linux $ cd ~
```

5. Determine the the device NAME (for mounting and formatting).  In my case, the device i will be creating the Gentoo system on is `sda`.

```console
user@localhost ~ $ lsblk
```

Example output of the above commands.
```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda
├─sda1
└─sda2
mmcblk0     179:0    0 59.5G  0 disk
├─mmcblk0p1 179:1    0  256M  0 part
└─mmcblk0p2 179:2    0 59.2G  0 part /
``` 

6. Format the MicroSD card with `fdisk` (replace all instances `sda` with your devices name, from Step 2).

```console
root ~ # fdisk /dev/sda
```

7. Remove all previous partitions and create two new partitions.

```
Command (m for help): o
Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-15523839, default 2048): 
Last sector, +sectors or +size{K,M,G,T,P} (2048-15523839, default 15523839): +128M
```

```
Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 2
First sector (2048-15523839, default 2048): 
Last sector, +sectors or +size{K,M,G,T,P} (2048-15523839, default 15523839):
```

8. Toggle boot partition flag and type for the first partition.

```
Command (m for help): a
Partition number (1-3, default 3): 1
```

```
Command (m for help): t
Partition number (1-3, default 3): 1
Partition type (type L to list all types): c
```

9. Write all changes and exit `fdisk`.

```
Command (m for help): w
```

10. The hard part is done!  The rest of the commands can be used with littl modification.

```console
localhost ~ # mkfs -t vfat -F 32 /dev/sda1
localhost ~ # mkfs -i 8192 -t ext4 /dev/sda2
localhost ~ # mkdir /mnt/gentoo
root # mount /dev/sda2 /mnt/gentoo
root # cd ~
root # wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20191124.tar.bz2
root # tar xfpj stage3-arm64-20191124.tar.bz2 -C /mnt/gentoo/
root # wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2
root # tar xjf portage-latest.tar.bz2 -C /mnt/gentoo/usr
root # rm -rf /mnt/gentoo/tmp/*
root # mount /dev/xxx1 /mnt/gentoo/boot
root # cp -rv /home/<user>/raspberrypi/firmware/boot/* /mnt/gentoo/boot
root # cp /home/<user>/raspberrypi/linux/arch/arm64/boot/Image /mnt/gentoo/boot/kernel8.img
root # mv /mnt/gentoo/boot/bcm2711-rpi-4-b.dtb /mnt/gentoo/boot/bcm2711-rpi-4-b.dtb_32
root # cp /home/<user>/raspberrypi/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb /mnt/gentoo/boot
root # cd /home/<user>/raspberrypi/linux
root # ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make modules_install INSTALL_MOD_PATH=/mnt/gentoo
root # cp /home/<user>/armstub8-gic.bin /mnt/gentoo/boot/
root # echo "US/Eastern" > /etc/timezone
root # mkdir /mnt/gentoo/lib/firmware
root # mkdir /mnt/gentoo/lib/firmware/brcm
root # cd /mnt/gentoo/lib/firmware/brcm
root # wget https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43455-sdio.bin
root # wget https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43455-sdio.clm_blob
root # wget https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/master/brcm/brcmfmac43455-sdio.txt
```

11. Create the following lines in the corrosponding file(s).

```console
root # nano -w /mnt/gentoo/etc/udev/rules.d/99-com.rules
```

```
SUBSYSTEM=="input", GROUP="input", MODE="0660"
SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
SUBSYSTEM=="spidev", GROUP="spi", MODE="0660"
SUBSYSTEM=="bcm2835-gpiomem", GROUP="gpio", MODE="0660"

SUBSYSTEM=="gpio*", PROGRAM="/bin/sh -c '\
        chown -R root:gpio /sys/class/gpio && chmod -R 770 /sys/class/gpio;\
        chown -R root:gpio /sys/devices/virtual/gpio && chmod -R 770 /sys/devices/virtual/gpio;\
        chown -R root:gpio /sys$devpath && chmod -R 770 /sys$devpath\
'"

KERNEL=="ttyAMA[01]", GROUP="dialout", PROGRAM="/bin/sh -c '\
        ALIASES=/proc/device-tree/aliases; \
        if cmp -s $ALIASES/uart0 $ALIASES/serial0; then \
                echo 0;\
        elif cmp -s $ALIASES/uart0 $ALIASES/serial1; then \
                echo 1; \
        else \
                exit 1; \
        fi\
'", SYMLINK+="serial%c"

KERNEL=="ttyS0", GROUP="dialout", PROGRAM="/bin/sh -c '\
        ALIASES=/proc/device-tree/aliases; \
        if cmp -s $ALIASES/uart1 $ALIASES/serial0; then \
                echo 0; \
        elif cmp -s $ALIASES/uart1 $ALIASES/serial1; then \
                echo 1; \
        else \
                exit 1; \
        fi \
'", SYMLINK+="serial%c"
```

```console
root # nano -w /mnt/gentoo/boot/config.txt
```

```
# set 64 bit mode
arm_64bit=1
enable_gic=1
armstub=armstub8-gic.bin

# have a properly sized image
disable_overscan=1
# for sound over HDMI
hdmi_drive=2
# Enable audio (loads snd_bcm2835)
dtparam=audio=on
```

```console
root # nano -w /mnt/gentoo/boot/cmdline.txt
```

```
root=/dev/mmcblk0p2 rootfstype=ext4 rootwait
```

12. Hide the following lines in the corrosponding file(s).

```console
root # nano -w /mnt/gentoo/etc/inittab
```

```
#f0:12345:respawn:/sbin/agetty 9600 ttyAMA0 vt100
```

13. Edit the following lines in the corrosponding file(s).

```console
root # nano -w /mnt/gentoo/etc/shadow
```

```
root:$6$xxPVR/Td5iP$/7Asdgq0ux2sgNkklnndcG4g3493kUYfrrdenBXjxBxEsoLneJpDAwOyX/kkpFB4pU5dlhHEyN0SK4eh/WpmO0::0:99999:7:::
```

```console
root -w /mnt/gentoo/etc/portage/make.conf
```

```
CFLAGS="-march=armv8-a+crc+simd -mtune=cortex-a72 -ftree-vectorize -O2 -pipe -fomit-frame-pointer"
ACCEPT_KEYWORDS="~arm64"
```

14. Append the following lines in the corrosponding file(s).

```console
root # nano -w /mnt/gentoo/etc/fstab
```

```
/dev/mmcblk0p1          /boot           vfat            noauto,noatime  1 2
/dev/mmcblk0p2          /               ext4            noatime         0 1
```

```console
root # nano -w /mnt/gentoo/etc/locale.gen
```

```
en_US.UTF-8 UTF-8
```

15. Unmount the system and shutdown.

```console
root # cd ~
root # umount /mnt/gentoo/boot
root # umount /mnt/gentoo
root # shutdown
``` 

## Setting Up and Updating your Gentoo system.
Insert the formatted and configured SD card into your Raspberry PI.  After startup, you will hopefully be greeted by a login prompt.  Default username should be `root` and password should be `raspberry`.

1. Set the date, time (format is `mmddhhmmyyyy`, in 24-hr format) and locale. In the example CLI command below, the date would be 31-July-2017 10:05 PM.  

```console
root # date 073122052017
root # locale-gen
root # eselect locale set 4
```

2. Enable the network and prepare for the long update process.

```console
root # ip link set dev eth0 up
root # busybox udhcpc eth0
root # emerge --sync
root # <need to put portage update command here>
root # perl-cleaner --all
root # emerge -auDN @world
root # emerge net-misc/ntp
root # rc-update del hwclock boot
root # rc-update add swclock boot
root # emerge sys-libs/timezone-data
root # rc-service ntp-client start
root # rc-update add ntp-client default
root # rc-update add sshd default
root # /etc/init.d/sshd start
root # cd /etc/init.d/
root # ln -sv net.lo net.eth0
root # rc-service net.eth0 start
root # rc-update add net.eth0 boot
root # rc-update --update
```

## Credits
* https://wiki.gentoo.org/wiki/User:NeddySeagoon/Raspberry_Pi4_64_Bit_Install
* https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install
* https://wiki.gentoo.org/wiki/Raspberry_Pi/Quick_Install_Guide
* https://wiki.gentoo.org/wiki/Handbook:AMD64
