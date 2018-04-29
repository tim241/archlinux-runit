#!/usr/bin/env bash
set -e
bash ./scripts/services/package.sh
bash ./scripts/packages/build.sh
sudo pacman -U bin/*.pkg*
echo "Enabling required services.."
for service in dbus consolekit cgmanager dhcpcd
do
    if [ ! -d "/var/service/$service" ]
    then
        echo " -> enabling $service"
        sudo ln -s /etc/sv/$service /var/service/
    fi
done
echo "Completed, please add 'init=/sbin/runit' to your bootline in your bootloader before rebooting!"
echo "Also add 'IgnorePkg = systemd libsystemd systemd-tools lib32-systemd' to your pacman.conf!"
