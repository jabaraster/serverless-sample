#!/bin/sh
./build-elm.sh \
  && ./build-less.sh \
  && aws s3 sync ./dist/ s3://jabara-serverless-app-web/