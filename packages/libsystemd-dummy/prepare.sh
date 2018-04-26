#!/usr/bin/env bash
mkdir -p files
sudo pacman -Sw libsystemd --noconfirm --needed
sudo cp /var/cache/pacman/pkg/libsystemd-*.pkg* .
tar xvf libsystemd-*.pkg* -C files/ --force
sudo rm -rf libsystemd-*.pkg*
export NO_INSTALL=yes
