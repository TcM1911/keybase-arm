#!/bin/bash

KBCLIENT_PATH="github.com/keybase/client"
BUILDROOT=$(pwd)

if [ -z "$1" ]; then
   VERSION=$(shell git describe --tags 2> /dev/null || git rev-list -1 HEAD)
else
   VERSION="$1"
fi


function DownloadKeybase() {
    go get -u -v $KBCLIENT_PATH/go/...
}

function CheckoutVersionAndPath() {
    cd $GOPATH/src/$KBCLIENT_PATH && \
        git checkout $VERSION && \
        git apply $BUILDROOT/keybase-electron-mirror.patch && \
        cd $BUILDROOT
}

function BuildGO() {
    GOOS=linux GOARCH=arm go build -o $BUILDROOT/target/keybase -v -tags production github.com/keybase/client/go/keybase
    GOOS=linux GOARCH=arm go build -o $BUILDROOT/target/kbfsfuse -v -tags production github.com/keybase/client/go/kbfs/kbfsfuse
    GOOS=linux GOARCH=arm go build -o $BUILDROOT/target/git-remote-keybase -v -tags production github.com/keybase/client/go/kbfs/kbfsgit/git-remote-keybase
}

function BuildGUI() {
    cd $GOPATH/src/$KBCLIENT_PATH/shared && \
       yarn install && \
       yarn run package -- --platform linux --arch armv7l --appVersion $VERSION && \
       cd $BUILDROOT
}


function main() {
    mkdir -p target
    DownloadKeybase
    CheckoutVersionAndPath
    BuildGO
    BuildGUI
}

main
