# Serverless Analytics with S3, Athena & QuickSight

For simplicity we assume :
- You are currently logged in an AWS account with an IAM ADMIN user or role
- Your AWS account is a SANDBOX or a DEV account
- You are working in AWS Ireland Region (eu-west-1)

---
## Athena Setup

###### Create Athena result bucket and Workgroup

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :
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

---
## Query CSV files with Athena


##### Create Data bucket and upload csv file

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```
# Create local data file
cat << EOF > data.csv
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 76000000 1652313600 1652313610 ACCEPT OK
EOF

# Create data bucket and upload data file
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1
aws s3 cp data.csv s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1

# Remove local data file
rm data.csv
```

##### Create Athena Table for CSV data
From an empty tab in the <a href="https://eu-west-1.console.aws.amazon.com/athena/home?region=eu-west-1#/query-editor" target="_blank">Athena Query Editor</a>, 
run the sql query in the scrip below.

OR

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```sql
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
DROP TABLE IF EXISTS flowlogs
"""

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
CREATE EXTERNAL TABLE
flowlogs (
  version int,
  account string,
  interfaceid string,
  sourceaddress string,
  destinationaddress string,
  sourceport string,
  destinationport string,
  protocol string,
  numpackets int,
  numbytes bigint,
  starttime int,
  endtime int,
  action string,
  logstatus string 
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
LOCATION 's3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1/' 
TBLPROPERTIES
(
'skip.header.line.count'='1'
)
"""
```

##### Query Athena table with csv data

From an empty tab in the <a href="https://eu-west-1.console.aws.amazon.com/athena/home?region=eu-west-1#/query-editor" target="_blank">Athena Query Editor</a>, 
run the sql query in the scrip below.

OR

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT * FROM flowlogs limit 10
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

---
## Query JSON files with Athena

##### Json Document Example
```json
{
   "configurationItems":[
      {
         "resourceType":"AWS::EC2::NetworkInterface",
         "resourceId":"eni-0000h23056c6d31kb",
          "configuration":{
            "subnetId":"subnet-000040665eb72f1f7",
            "vpcId":"vpc-0000c52ea2ebufda4"
          }       
      }      
   ]
}
```

N.B. Json files in S3 must contain one document per line

```
# Create local data file
cat << EOF > data.json
{"configurationItems":[{"resourceType":"AWS::EC2::NetworkInterface","resourceId":"eni-0000h23056c6d31kb","configuration":{"subnetId":"subnet-0b17406654b72e1f7","vpcId":"vpc-0000c52ea2ebufda4"}}]}
EOF

# Create data bucket and upload data file
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1
aws s3 cp data.json s3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1

# Remove local data file
rm data.json
```

##### Create Athena table

```sql
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
DROP TABLE IF EXISTS config
"""

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
CREATE EXTERNAL TABLE
config (
  configurationItems array < 
    struct <
      resourceType:string,
      resourceId:string,
      configuration:struct <
        subnetId:string,
        vpcId:string
      >    
    >
  > 
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://serverless-analytics-demo-json-${ACCOUNT_NUMBER}-eu-west-1/'
"""
```

##### Query Athena table

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT * FROM config
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT configurationItem 
FROM config
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT configurationItem.resourcetype 
FROM config
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT configurationItem.resourcetype, count(*) as count
FROM config
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
group by configurationItem.resourcetype
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

---
## Create a view in Athena
```sql
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
CREATE OR REPLACE VIEW 
config_view AS 
SELECT configurationItem.resourceid, configurationItem.configuration.vpcid 
FROM config
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
"""
```

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT * FROM config_view
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

---
## Create a "Join view" in Athena
```sql
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
CREATE OR REPLACE VIEW flowlogs_config_join_view AS 
SELECT 
  flowlogs.action,
  flowlogs.sourceaddress,
  flowlogs.destinationaddress,
  flowlogs.interfaceid, 
  flowlogs.numbytes,
  from_unixtime(flowlogs.starttime) as startdatetime,
  config_view.vpcid
FROM flowlogs
     JOIN config_view ON config_view.resourceId = flowlogs.interfaceid
"""
```

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT * FROM flowlogs_config_join_view
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT vpcid, sum(numbytes) as sum_numbytes FROM flowlogs_config_join_view GROUP BY vpcid
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

---
## Clean Up

### Cleanup database
```
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

# Delete database
aws athena start-query-execution --query-string "DROP DATABASE analytics_database CASCADE" --work-group "Data_Analyst_Group"

# Delete Workgroup
aws athena delete-work-group --work-group "Data_Analyst_Group" --recursive-delete-option

# Delete result bucket
aws s3 rm s3://athena-query-results-$ACCOUNT_NUMBER-eu-west-1/ --recursive
aws s3 rb s3://athena-query-results-$ACCOUNT_NUMBER-eu-west-1
```

## Cleanup buckets
```
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
```

