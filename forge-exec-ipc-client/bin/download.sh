#!/usr/bin/env bash

# from: https://stackoverflow.com/a/246128
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

tag="v0.1.1"
release=forge-exec-ipc-client-${tag}
targets=("aarch64-apple-darwin" "x86_64-apple-darwin" "x86_64-pc-windows-gnu" "x86_64-pc-windows-msvc" "x86_64-unknown-linux-musl")

mkdir -p $DIR/downloads
cd $DIR/downloads
for target in "${targets[@]}"
do
    echo https://github.com/wighawag/forge-exec/releases/download/${release}/forge-exec-ipc-client_${tag}_${target}.tar.gz
    curl -L -O https://github.com/wighawag/forge-exec/releases/download/${release}/forge-exec-ipc-client_${tag}_${target}.tar.gz
    mkdir -p ../$target; tar -xf forge-exec-ipc-client_${tag}_${target}.tar.gz --strip=1 -C ../$target
    rm forge-exec-ipc-client_${tag}_${target}.tar.gz
done
rmdir $DIR/downloads