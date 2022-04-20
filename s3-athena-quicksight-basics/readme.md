# Serverless Analytics with S3, Athena & QuickSight

For simplicity we assume :
- You are currently logged in an AWS account with an IAM ADMIN user or role
- Your AWS account is a SANDBOX or a DEV account
- You are working in AWS Ireland Region (eu-west-1)

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

###### Open Athena Query Editor

Open <a href="https://eu-west-1.console.aws.amazon.com/athena/home?region=eu-west-1#/query-editor" target="_blank">Athena Query Editor</a>

## Query CSV files with Athena


##### Create Data bucket and upload csv file

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```
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
LOCATION 's3://serverless-analytics-demo-${ACCOUNT_NUMBER}-eu-west-1/' 
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

## Query JSON files with Athena

##### Json Document Example
```json
{
   "configurationItems":[
      {
         "resourceType":"AWS::EC2::NetworkInterface",
         "resourceId":"eni-0000h23056c6d31kb",
          "configuration":{
            "subnetId":"subnet-0b17406654b72e1f7",
            "vpcId":"vpc-0ed8c52ea2ebufda4"
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

### Create a view in Athena
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

### Create a "Join view" in Athena
```sql
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
CREATE OR REPLACE VIEW join_view AS 
SELECT 
  flowlogs.interfaceid, 
  config_view.vpcid,
  flowlogs.numbytes
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
SELECT * FROM join_view
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
SELECT vpcid, sum(numbytes) as sum_numbytes FROM join_view GROUP BY vpcid
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

### Unload table and convert data format

##### Create Data Bucket

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```
# Create data bucket
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1
```

##### Create Athena Table in Parquet Format
```sql
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
DROP TABLE IF EXISTS flowlogs_parquet
"""

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
CREATE EXTERNAL TABLE
flowlogs_parquet (
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
STORED AS PARQUET 
LOCATION 's3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1/'
"""
```

##### Unload CSV data into Parquet data

```sql
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query-string \
"""
UNLOAD (SELECT * FROM flowlogs) 
TO 's3://serverless-analytics-demo-parquet-${ACCOUNT_NUMBER}-eu-west-1/flowlogs' 
WITH (format = 'PARQUET')
"""
```

##### Query Parquet table
```sql
# Execute Query
query_execution_id=$(
aws athena start-query-execution \
    --work-group "Data_Analyst_Group" \
    --query-execution-context Database="analytics_database" \
    --query "QueryExecutionId" --output text \
    --query-string \
"""
SELECT * FROM flowlogs_parquet
"""
)

# Display result
output_location=$(aws athena get-query-execution --query-execution-id $query_execution_id --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)
aws s3 cp $output_location -
```

##### Parquet format example
```
PAR1 8¿ôœÏ   ‹      cb```fd’ Þ+‚ö
    ,P¶³¦   ‹      cb```fä’†††FFFÆÆÆ ¸IÃ    >b—¸Ê¿   ‹      cb```f’©y™ºÆÆ–FÆ¦fÉf)Æ†ÙI Ýh    (HÌÜ’   ‹      cb```fä’†z hdb  
Rö    0TóŸ   ‹      cb```fä’¦zF†–z†–z†&– ƒ,’f    B€­¾Ø
   ‹      cb```fd’Æ&†&& Cße    >“ÏŠ“   ‹      cb```fd’†FÆ ÏoîÜ
    <ÅâÀì   ‹      cb```fd’†æ W>Œ    8¦é»Â   ‹      cb```fd’ 0„7ä
    BÏÞè•   ‹      cb```fdXÝÎd0       <æõí§   ‹      cb```f¬2©Ž ¹tL
    <–ž²   ‹      cb```fœoR ³³Õ­
     DªåŠ¦
   ‹      cb```fd’A®^®Î! Ýê4    <šÏ¨Ž   ‹      cb```fd’þÞ ~>1d           000111222333000111222333  eni-0339h23056c6d31kbeni-0339h23056c6d31kb  
10.0.0.240
10.0.0.240  50.219.198.14950.219.198.149  3414434144  123123  1717           «‡     «‡      z4{_z4{_  Ÿ4{_Ÿ4{_  REJECTREJECT  OKOK  f   n~   ì   üt   ð‚   òp   âl   Îj   ¸f   žp   Ž	j   ø	j   â
r   Ôj   üHhive_schema %version %account% L   %interfaceid% L   %
sourceaddress% L   %destinationaddress% L   %
sourceport% L   %destinationport% L   %protocol% L   %
numpackets %numbytes %	starttime %endtime %action% L   %	logstatus% L   ì&5 versionBf&<       (           î¾. &n5 accountZ~&n<000111222333000111222333 (000111222333000111222333     ‚ìN &ì5 interfaceidl&ì<eni-0339h23056c6d31kbeni-0339h23056c6d31kb (eni-0339h23056c6d31kbeni-0339h23056c6d31kb     –º
r &ü5 
sourceaddressTt&ü<
10.0.0.240
10.0.0.240 (
10.0.0.240
10.0.0.240     ®¬F &ð5 destinationaddress^‚&ð<50.219.198.14950.219.198.149 (50.219.198.14950.219.198.149     ÄòV &ò5 
sourceportLp&ò<3414434144 (3414434144     ÜÈ2 &â5 destinationportHl&â<123123 (123123     òú* &Î5 protocolFj&Î<1717 (1717     ˆ¤& &¸5 
numpacketsBf&¸<       (           žÊ. &ž5 numbytesJp&ž< «‡     «‡     ( «‡     «‡         ´ø> &Ž	5 	starttimeBj&Ž	<z4{_z4{_ (z4{_z4{_     Ê¶. &ø	5 endtimeBj&ø	<Ÿ4{_Ÿ4{_ (Ÿ4{_Ÿ4{_     àä. &â
5 actionNr&â
<REJECTREJECT (REJECTREJECT     ö’6 &Ô5 	logstatusFj&Ô<OKOK (OKOK     ŒÈ& ¸ (Xparquet-mr version 1.11.1-amzn-athena-1 (build e4c8769d72fd0e21068423a0ee114afeaa85df42)ì                             
  PAR1
```