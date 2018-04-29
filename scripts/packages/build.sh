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
    cd "$(dirname "$package")"
    echo "Building $package"
    if [ -f "prepare.sh" ]
    then
        source prepare.sh
    fi
    makepkg -sc --force
    cd "$cdir"
done
