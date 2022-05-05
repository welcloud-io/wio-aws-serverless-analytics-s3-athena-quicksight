#!/usr/bin/bash

# --------------------------------------------------------------------------------------------------------------------------
# Create local data file
cat << EOF > data.csv
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.219.198.149 34144 123 17 1 76000000 1601909882 1601909919 REJECT OK
EOF

# Create data bucket and upload data file
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1
aws s3 cp data.csv s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1 

# Remove local data file
rm data.csv

# --------------------------------------------------------------------------------------------------------------------------
# Create local data file
cat << EOF > data.json
{"configurationItems":[{"resourceType":"AWS::EC2::NetworkInterface","resourceId":"eni-0000h23056c6d31kb","configuration":{"subnetId":"subnet-000040665eb72f1f7","vpcId":"vpc-0000c52ea2ebufda4"}}]}
EOF

# Create data bucket and upload data file
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1
aws s3 cp data.json s3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1

# Remove local data file
rm data.json

# --------------------------------------------------------------------------------------------------------------------------
# Create data bucket
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
UNLOAD (SELECT * FROM flowlogs) 
TO 's3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1/flowlogs' 
WITH (format = 'PARQUET')
"""
