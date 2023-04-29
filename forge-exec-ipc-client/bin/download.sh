#!/usr/bin/env bash

# from: https://stackoverflow.com/a/246128
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

tag="v0.0.0-rc.10"
targets=("aarch64-apple-darwin" "x86_64-apple-darwin" "x86_64-pc-windows-gnu" "x86_64-pc-windows-msvc" "x86_64-unknown-linux-musl")

mkdir -p $DIR/downloads
cd $DIR/downloads
for target in "${targets[@]}"
do
https://github.com/wighawag/forge-exec/releases/download/v0.0.0-rc.10/forge-exec-ipc-client_v0.0.0-rc.10_x86_64-pc-windows-msvc.tar.gz
    echo https://github.com/wighawag/forge-exec/releases/download/${tag}/forge-exec-ipc-client_${tag}_${target}.tar.gz
    curl -L -O https://github.com/wighawag/forge-exec/releases/download/${tag}/forge-exec-ipc-client_${tag}_${target}.tar.gz
    mkdir -p ../$target; tar -xf forge-exec-ipc-client_${tag}_${target}.tar.gz --strip=1 -C ../$target
    rm forge-exec-ipc-client_${tag}_${target}.tar.gz
done
rmdir $DIR/downloads