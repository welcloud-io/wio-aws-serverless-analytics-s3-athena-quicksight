#!/usr/bin/bash

ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

# Delete database
aws athena start-query-execution --query-string "DROP DATABASE analytics_database CASCADE" --work-group "Data_Analyst_Group"

# Delete Workgroup
aws athena delete-work-group --work-group "Data_Analyst_Group" --recursive-delete-option

# Delete result bucket
aws s3 rm s3://athena-query-results-$ACCOUNT_NUMBER-eu-west-1/ --recursive
aws s3 rb s3://athena-query-results-$ACCOUNT_NUMBER-eu-west-1
