#!/bin/bash

KBCLIENT_PATH="github.com/keybase/client"
BUILDROOT=$(pwd)

if [ -z "$1" ]; then
   VERSION=$(cat $BUILDROOT/latest-version)
else
   VERSION="$1"
fi


function DownloadKeybase() {
    GOOS=linux GOARCH=arm go get -u -v $KBCLIENT_PATH/go/...
}

function CheckoutVersionAndPath() {
    cd $GOPATH/src/$KBCLIENT_PATH && \
        git checkout "v$VERSION" && \
        git apply $BUILDROOT/keybase-electron-mirror.patch && \
        cd $BUILDROOT
}

function BuildGO() {
    GOOS=linux GOARCH=arm go build -o $BUILDROOT/target/keybase -tags production github.com/keybase/client/go/keybase
    GOOS=linux GOARCH=arm go build -o $BUILDROOT/target/kbfsfuse -tags production github.com/keybase/client/go/kbfs/kbfsfuse
    GOOS=linux GOARCH=arm go build -o $BUILDROOT/target/git-remote-keybase -tags production github.com/keybase/client/go/kbfs/kbfsgit/git-remote-keybase
}

function BuildGUI() {
    cd $GOPATH/src/$KBCLIENT_PATH/shared && \
       yarn install && \
       yarn run package -- --platform linux --arch armv7l --appVersion $VERSION && \
       cp -r $GOPATH/src/$KBCLIENT_PATH/shared/desktop/release/linux-armv7l/Keybase-linux-armv7l $BUILDROOT/target/.
       cd $BUILDROOT
}

function CopyExtras() {
    cp $GOPATH/src/$KBCLIENT_PATH/packaging/linux/{run_keybase,crypto_squirrel.txt,systemd/kbfs.service,systemd/keybase.gui.service,systemd/keybase.service} target/.
}

function Package() {
    cd $BUILDROOT
    mv target keybase-linux-arm-$VERSION
    tar cfvz keybase-linux-arm-$VERSION.tar.gz keybase-linux-arm-$VERSION
}


function main() {
    mkdir -p target
    DownloadKeybase
    CheckoutVersionAndPath
    BuildGO
    BuildGUI
    CopyExtras
    Package
}

main
