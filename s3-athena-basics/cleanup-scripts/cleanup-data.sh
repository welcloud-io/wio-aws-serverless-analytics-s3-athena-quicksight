#!/usr/bin/bash

ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

# Delete data buckets
aws s3 rm s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1/ --recursive
aws s3 rb s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1

aws s3 rm s3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1/ --recursive
aws s3 rb s3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1

aws s3 rm s3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1/ --recursive
aws s3 rb s3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1

# Remove datafiles
rm data.csv
rm data.json
