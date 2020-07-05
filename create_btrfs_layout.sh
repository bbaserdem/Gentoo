#!/bin/bash
# Create my filesystem layout on a directory using btrfs stuff

# Rename input variable
target_dir="${1}"

if [ -z "${target_dir}" ] ; then
  echo 'Need directory argument.'
  exit 1
elif [ ! -d "${target_dir}" ] ; then
  echo 'Needs to be a directory.'
  exit 2
elif ! mountpoint "${target_dir}" >/dev/null 2>&1 ; then
  echo 'Needs to be a mount point.'
  exit 3
elif [ "$(ls -A "${target_dir}")" ] ; then
  echo 'Directory is not empty.'
  exit 4
fi

# Make the main subvolumes
btrfs subvolume create "${target_dir}/@root"
btrfs subvolume create "${target_dir}/@snapshots"
btrfs subvolume create "${target_dir}/@variable"
btrfs subvolume create "${target_dir}/@swap"
btrfs subvolume create "${target_dir}/@server"
# Create folders that will be mount points is root partition
mkdir "${target_dir}/@root/.snapshots"
mkdir "${target_dir}/@root/boot"
mkdir "${target_dir}/@root/efi"
mkdir "${target_dir}/@root/home"
mkdir "${target_dir}/@root/opt"
mkdir "${target_dir}/@root/swap"
mkdir "${target_dir}/@root/var"
mkdir "${target_dir}/@root/srv"
# Create the nested subvolumes in the variable subvolume
mkdir --parents "${target_dir}/@variable/lib"
btrfs subvolume create "${target_dir}/@variable/lib/libvirt"
btrfs subvolume create "${target_dir}/@variable/lib/machines"
btrfs subvolume create "${target_dir}/@variable/lib/mysql"
btrfs subvolume create "${target_dir}/@variable/lib/portables"
btrfs subvolume create "${target_dir}/@variable/log"
btrfs subvolume create "${target_dir}/@variable/tmp"
btrfs subvolume create "${target_dir}/@root/var/abs"
# Create a swapfile in the swap subvolume
truncate -s 0 "${target_dir}/@swap/swapfile"
chattr +C "${target_dir}/@swap/swapfile"
btrfs property set "${target_dir}/@swap/swapfile" compression none
# Prepare the swap file with 0 size
# dd if=/dev/zero of="${target_dir}/@swap/swapfile" bs=1M count=10K status=progress
# chmod 600 "${target_dir}/@swap/swapfile"
# mkswap "${target_dir}/@swap/swapfile"
# Disable CoW on select directories
chattr +C "${target_dir}/@swap"
chattr +C "${target_dir}/@server"
chattr +C "${target_dir}/@variable/lib/mysql"
chattr +C "${target_dir}/@variable/lib/libvirt"
