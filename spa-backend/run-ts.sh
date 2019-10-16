#!/bin/sh
if [ "$1" = "" ]; then
  echo '引数にtsファイルを指定すること.'
  exit 1
fi
npm-run ts-node $1