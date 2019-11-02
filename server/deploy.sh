#!/bin/sh
\cp -f package.json dist/src/ \
  && cd dist/src/ \
  && npm install \
  && aws cloudformation package --template-file ../../template.yaml --output-template-file template-output.yaml --s3-bucket jabara-serverless-app-sam \
  && aws cloudformation deploy --template-file template-output.yaml --stack-name jabara-serverless-app --capabilities CAPABILITY_IAM --region ap-northeast-1
osascript -e 'display notification "Deploy finish!" with title ""'