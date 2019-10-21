#!/bin/sh
aws s3 mb s3://jabara-serverless-app-web --region ap-northeast-1
aws s3 website s3://jabara-serverless-app-web/ --index-document index.html
aws s3api put-bucket-policy --bucket jabara-serverless-app-web --policy file://policy.json
aws dynamodb create-table --table-name photos \
    --attribute-definitions AttributeName=photoId,AttributeType=S \
    --key-schema AttributeName=photoId,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
aws iam create-role --role-name lambda-dynamodb-access --assume-role-policy-document file://trustpolicy.json
aws iam put-role-policy --role-name lambda-dynamodb-access --policy-name dynamodb-access --policy-document file://permission.json
aws s3 mb s3://jabara-serverless-app-photos --region ap-northeast-1
aws s3 website s3://jabara-serverless-app-photos/ --index-document index.html
aws s3api put-bucket-policy --bucket jabara-serverless-app-photos --policy file://spa-backend/policy.json

aws s3 mb s3://jabara-serverless-app-sam