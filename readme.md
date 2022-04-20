# Serverless Analytics with S3, Athena & QuickSight

For simplicity we assume :
- You are currently logged in an AWS account with an IAM ADMIN user or role
- Your AWS account is a SANDBOX or a DEV account
- You are working in AWS Ireland Region (eu-west-1)

## Athena Setup

###### Create Athena result bucket and Workgroup

From [AWS CloudShell](https://eu-west-1.console.aws.amazon.com/cloudshell)
or your own local terminal, run :
```
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

# Create Athena result bucket
aws s3 mb s3://athena-query-results-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1

# Configure Athena with result bucket
aws athena create-work-group --name "Data_Analyst_Group" \
           --configuration ResultConfiguration={OutputLocation=s3://athena-query-results-${ACCOUNT_NUMBER}-eu-west-1}

# Create a new Athena database attached to the created workgroup
aws athena start-query-execution --query-string "CREATE DATABASE analytics_database" --work-group "Data_Analyst_Group"
```

###### Open Athena Query Editor

Open [Athena Query Editor](https://eu-west-1.console.aws.amazon.com/athena/home?region=eu-west-1#/query-editor)
