#!/usr/bin/env bash
mkdir -p files
sudo pacman -Sw lib32-systemd --noconfirm --needed
sudo cp /var/cache/pacman/pkg/lib32-systemd-*.pkg* .
tar xvf lib32-systemd-*.pkg* -C files/ --force
ls | grep lib32-systemd-*.pkg* | cut -d'-' -f3 > version
rm -rf lib32-systemd-*.pkg*
