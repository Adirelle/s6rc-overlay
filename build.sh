#!/usr/bin/env bash
set -e

function notice() { echo -e "\e[32m# $*\e[0m"; }

ARCH=${1:-amd64}
TAG=${2:-master}

SKAWARE=1.19.1
BASE_URL=https://github.com/just-containers/skaware/releases/download/v$SKAWARE

GOSU=1.10

BUILD=$PWD/build
CACHE=$PWD/cache
ROOT=$BUILD/$ARCH

ARTIFACT=$BUILD/s6rc-overlay-$TAG-$ARCH.tar.bz2

if [ -n "$GITHUB_OAUTH_TOKEN" ]; then
    notice "Using OAuth token to connect to Github"
    CURL_AUTH="-uAdirelle:$GITHUB_OAUTH_TOKEN"
else
    notice "Anonymous connection to Github"
    CURL_AUTH=""
fi

notice "Rate limits:"
curl --silent --show-error --head --include $CURL_AUTH https://api.github.com/users/rate_limit | grep '^X-RateLimit'

function fetch() {
    local URL="$1"
    local FILENAME="$(basename $URL)"
    notice "Fetching $FILENAME"
    curl --silent --show-error --location --remote-time --get $CURL_AUTH --output "$CACHE/$FILENAME" "$URL"
}

if [[ -d $ROOT ]]; then
    notice "Cleaning up target directory"
    rm -rf $ROOT
fi

mkdir --parents $ROOT $CACHE

fetch $BASE_URL/manifest-portable.txt
sed -e 's/-/_/g' $CACHE/manifest-portable.txt > $CACHE/manifest-portable.sh
source $CACHE/manifest-portable.sh

for PKG in execline-$execline s6-$s6 s6-rc-${s6_rc} s6-portable-utils-${s6_portable_utils}; do
    ARCHIVE=$PKG-linux-$ARCH-bin.tar.gz
    fetch $BASE_URL/$ARCHIVE
    notice "Extracting $ARCHIVE"
    tar --extract --file=$CACHE/$ARCHIVE --auto-compress --directory=$ROOT --same-permissions
done

fetch https://github.com/tianon/gosu/releases/download/$GOSU/gosu-$ARCH
cp $CACHE/gosu-$ARCH $ROOT/bin/gosu
chmod a+rx,u+s $ROOT/bin/gosu

notice "Copying overlay"
cp -rp overlay/* $ROOT

notice "Creating $(basename $ARTIFACT)"
tar --create --file=$ARTIFACT --auto-compress --directory=$ROOT --owner=0 --group=0 .

{ cd $(dirname $ARTIFACT); sha512sum $(basename $ARTIFACT) >$ARTIFACT.sha512; }

