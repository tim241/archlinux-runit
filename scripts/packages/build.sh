#!/usr/bin/env bash
set -e
source /etc/makepkg.conf
cdir="$(pwd)"
arch="$(uname -m)"
export PKGDEST="$cdir/bin"
mkdir -p bin
built_packages=('')
for package in $(find packages/ -name "PKGBUILD" 2> /dev/null)
do 
    for item in ${built_packages[@]}
    do
        if [ "$item" = "$(echo $package | rev | cut -d'/'  -f2 | rev)" ]
        then
            break
        fi
    done
    cd "$(dirname "$package")"
    echo "Building $package"
    if [ -f "prepare.sh" ]
    then
        source prepare.sh
    fi
    source PKGBUILD 2> /dev/null
    for item in ${depends[@]} ${makedepends[@]}; do
        if ! pacman -Ssq $item | head -1 > /dev/null 2>&1 ||
            ! pacman -Qsq $item | head -1 > /dev/null 2>&1
        then
            _pkgdir="$(pwd)"
            _pkg_found=no
            for package in $(find ../../packages/ -name "PKGBUILD" 2> /dev/null); do
                source $package
                for package in ${provides[@]}; do
                    if [ "$package" = "$item" ]; then
                        _pkg_found=yes
                        cd "$(dirname "$package")"
                        makepkg -sci --force
                    fi
                done
                if [ "$_pkg_found" = "no" ]; then
                    for package in ${pkgname[@]}; do
                        if [ "$package" = "$item" ]; then
                            _pkg_found=yes
                            cd "$(dirname "$package")"
                            makepkg -sci --force
                        fi
                    done
                fi
            done
            if [ "$_pkg_found" = "no" ]; then
                echo "Couldn't find $item"
                exit 1
            else
                build_packages+=('$item')
            fi
            cd "$_pkgdir"
        fi
    done
    makepkg -sc --force
    cd "$cdir"
done
