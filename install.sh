#!/usr/bin/env bash
set -e
if [ -d "bin" ]
then
    echo "=>> Cleaning"
    bash clean.sh
fi
# services that need to be enabled
services=('dbus' 'dhcpcd')
# packages that need to be recompiled because they are compiled on systemd
packages=('xorg-server' 'xf86-input-libinput' 'pulseaudio' \
    'pkgfile' 'libgudev')
build_packages=('polkit-consolekit-git'
    'consolekit-git' 'dbus-git' 'dhcpcd-git'
    'eudev-git' 'lib32-eudev-git' 'networkmanager-consolekit'
    'runit' 'void-runit' 'procps-ng-git')

if [ ! -f packages/pacman-src-git/PKGBUILD ]
then
    echo -e "\\n=>> Downloading latest pacman-src-git PKGBUILD..\\n"
    mkdir packages/pacman-src-git
    curl https://raw.githubusercontent.com/tim241/pacman-src/master/package/PKGBUILD > packages/pacman-src-git/PKGBUILD
fi
cdir="$(pwd)"
arch="$(uname -m)"
export PKGDEST="$cdir/bin"
mkdir -p bin
for package in ${build_packages[@]}
do 
    echo -e "\\n=>> Building $package\\n"
    cd "packages/$package"
    makepkg -sc 
    cd "$cdir"
done
echo -e "\\n=>> Installing packages!\\n"
sudo pacman --force -U bin/*pkg*
echo -e "\\n=>> Copying services"
for service in $(cd services && ls -1)
do
    if [ ! -d "/etc/sv/$service" ]
    then
        sudo cp -r "es/$service" "/etc/sv/$service"
    fi
done
echo -e "\\n=>> Enabling required services..\\n"
for service in "${service[@]}"
do
    echo "  -> enabling $service"
    sudo ln -s /etc/sv/$service /var/service/
done
echo -e "\\n=>> Configuring pacman-src!\\n"
pacman-src -u
echo -e "\\n=>> Recompiling packages"
for package in "${packages[@]}"
do
    if pacman -Qq $package > /dev/null 2>&1
    then
        echo "  -> Recompiling $package"
        pacman-src -snmf $package
    fi
done
echo -e "\\nCompleted, please add 'init=/sbin/runit' to your bootline in your bootloader before rebooting!"

