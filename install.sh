#!/usr/bin/env bash
set -e
cdir="$(pwd)"
# Define colors
_color_white='\033[1;37m'
_color_green='\033[1;32m'
_color_red='\033[1;31m'
_color_yel='\033[0;33m'
_color_blue='\033[0;34m'
_color_reset='\033[0m' 
# print text
function _print() {
     echo -e "\\n$*\\n"
}
# Print white text
function _wprint() {
    _print "${_color_green}=>>${_color_reset} ${_color_white}$* ${_color_reset}"
}
function _installpkgs() {
    _wprint "Installing packages!"
    sudo pacman --force -U "$cdir"/bin/*pkg*
}

# services that need to be enabled
services=('dbus' 'dhcpcd')
# packages that need to be recompiled because they are compiled on systemd
packages=('xorg-server' 'xf86-input-libinput' 'pulseaudio' \
    'pkgfile' 'libgudev')
build_packages=('polkit-consolekit-git'
    'consolekit-git' 'dbus-git' 'dhcpcd-git'
    'eudev-git' 'lib32-eudev-git' 'networkmanager-consolekit'
    'runit' 'void-runit-git' 'procps-ng-git' 'libsystemd-dummy' 'lib32-systemd-dummy')
# get latest pacman-src pkgbuild
if [ ! -f packages/pacman-src-git/PKGBUILD ]
then
    _wprint "Downloading latest pacman-src-git PKGBUILD.."
    mkdir packages/pacman-src-git
    curl https://raw.githubusercontent.com/tim241/pacman-src/master/package/PKGBUILD > packages/pacman-src-git/PKGBUILD
fi
arch="$(uname -m)"
unset NO_INSTALL
export PKGDEST="$cdir/bin"
mkdir -p bin
for package in ${build_packages[@]}
do 
    cd "packages/$package"
    if [ ! -f "$cdir/bin"/$(makepkg --packagelist | grep $arch | head -1)* ]
    then
        if [[ $package = lib32-* ]]
        then
            _installpkgs
        fi
        if [ -f "prepare.sh" ]
        then
            _wprint "Preparing ${_color_blue}$package"
            source prepare.sh
        fi
        _wprint "Building ${_color_blue}$package"
        makepkg -sc --nocheck
        if [ "x$NO_INSTALL" != "xyes" ]
        then
            _wprint "Installing ${_color_blue}$package"
            sudo pacman -U "$cdir/bin"/$(makepkg --packagelist | grep $arch | head -1)*
        fi
        unset NO_INSTALL
    fi
    cd "$cdir"
done
_installpkgs
_wprint "Copying services"
for service in $(cd services && ls -1)
do
    if [ ! -d "/etc/sv/$service" ]
    then
        sudo cp -r "services/$service" "/etc/sv/$service"
    fi
done
_wprint "Enabling required services.."
for service in "${services[@]}"
do
    if [ ! -d "/var/service/$service" ]
    then
        _print "  ${_color_blue}->${_color_white} enabling ${_color_blue}$service${_color_reset}"
        sudo ln -s /etc/sv/$service /var/service/
    fi
done
mkdir tmp
_wprint "Configuring pacman-src!"
pacman-src -u
_wprint "Recompiling packages"
for package in "${packages[@]}"
do
    if pacman -Qq $package > /dev/null 2>&1
    then
        _print "  ${_color_blue}->${_color_white} recompiling ${_color_blue}$package${_color_reset}" 
        pacman-src -snmf $package
    fi
done
_wprint "Completed, please add 'init=/sbin/runit' to your bootline in your bootloader before rebooting!"
_wprint "Also add 'IgnorePkg = systemd libsystemd systemd-tools lib32-systemd' to your pacman.conf!"
