#!/usr/bin/env bash
for service in services/*
do
    if [ -f "$service/run" ]
    then
        pkgname="$(echo "$service" | cut -d'/' -f2)"
        if [ -f "$service/command.sh" ]
        then
            command="$(cat $service/command.sh)"
        else
            command="$pkgname"
        fi
        if which $command > /dev/null 2>&1
        then
            echo "Generating PKGBUILD for $pkgname"
            PKGBUILD="packages/services/$pkgname-runit/PKGBUILD"
            if [ ! -d "packages/services/$pkgname-runit" ]
            then
                mkdir -p packages/services/$pkgname-runit
            fi
            if ! PKGDEPENDS="$(pacman -Qo $command | cut -d' ' -f5)"
            then
                echo "Failed to generate pkgbuild for $pkgname"
                exit 1
            fi
            cp scripts/services/template/PKGBUILD   "$PKGBUILD"
            sed -i "s/@PKGNAME@/$pkgname/g"         "$PKGBUILD"
            sed -i "s/@MD5SUM@/$(cat "$service/run" | md5sum | cut -d' ' -f1)/g" "$PKGBUILD"
            sed -i "s/@PKGDEPENDS@/$PKGDEPENDS/g"   "$PKGBUILD"
            cp "$service/run"                       $(dirname "$PKGBUILD")
            unset PKGDEPENDS PKGBUILD 
        fi
    fi
done
