#!/bin/bash

KBCLIENT_PATH="github.com/keybase/client"
BUILDROOT=$(pwd)
GOOPTS="GOARCH=arm"

if [ -z "$1" ]; then
   VERSION=$(cat $BUILDROOT/latest-version)
else
   VERSION="$1"
fi


function DownloadKeybase() {
    go get -u $KBCLIENT_PATH/go/...
}

function CheckoutVersionAndPath() {
    cd $GOPATH/src/$KBCLIENT_PATH && \
        git checkout "v$VERSION" && \
        git apply $BUILDROOT/keybase-electron-mirror.patch && \
        cd $BUILDROOT
}

function BuildGO() {
    $GOOPTS go build -o $BUILDROOT/target/keybase -tags production github.com/keybase/client/go/keybase
    $GOOPTS go build -o $BUILDROOT/target/kbfsfuse -tags production github.com/keybase/client/go/kbfs/kbfsfuse
    $GOOPTS go build -o $BUILDROOT/target/git-remote-keybase -tags production github.com/keybase/client/go/kbfs/kbfsgit/git-remote-keybase
}

function BuildGUI() {
    cd $GOPATH/src/$KBCLIENT_PATH/shared && \
       yarn install && \
       yarn run package -- --platform linux --arch armv7l --appVersion $VERSION && \
       cp -r $GOPATH/src/$KBCLIENT_PATH/shared/desktop/release/linux-armv7l/Keybase-linux-armv7l $BUILDROOT/target/.
       cd $BUILDROOT
}

function CopyExtras() {
    cp -v $GOPATH/src/$KBCLIENT_PATH/packaging/linux/{run_keybase,crypto_squirrel.txt,systemd/kbfs.service,systemd/keybase.gui.service,systemd/keybase.service} $BUILDROOT/target/.
}

function Package() {
    cd $BUILDROOT
    echo "Packaging:"
    ls target
    mv target keybase-linux-arm-$VERSION
    tar cfvz keybase-linux-arm-$VERSION.tar.gz keybase-linux-arm-$VERSION
}


function main() {
    mkdir -p target
    echo "Downloading..."
    DownloadKeybase
    CheckoutVersionAndPath
    echo "Building Keybase"
    BuildGO
    echo "Building GUI"
    BuildGUI
    CopyExtras
    echo "Packaging..."
    Package
    echo "Done!"
    ls *.tar.gz
}

main
