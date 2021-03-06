### Create Athena Table Partitions

There are 3 ways to create partitions with athena:

- Add a partition manually

```sql
ALTER TABLE [Table] ADD PARTITION (date='2015-01-01') location 's3://[BUCKET][/SUBFOLDERS]'
```

- Project a partition in the table declaration

```sql
CREATE EXTERNAL TABLE
[Table]
...
) PARTITIONED BY (
    p_account string,
    p_region string,
    p_date string
)
...
LOCATION 's3://[CONFIG-BUCKET]/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.p_account.type' = 'enum',
    'projection.p_account.values' = '[LIST_OF_ACCOUNTS]',
    'projection.p_date.format' = 'yyyy/M/d',
    'projection.p_date.range' = '2022/01/01,NOW',
    'projection.p_date.type' = 'date',
    'projection.p_region.type' = 'enum',
    'projection.p_region.values' = 'eu-west-1',
    'storage.location.template' = 's3://[CONFIG_BUCKET][/SUBFOLDERS]/AWSLogs/${p_account}/Config/${p_region}/${p_date}/ConfigSnapshot'
)
```

- Have buckets with folder names in a specific format (Hive format)

More details [here](https://docs.aws.amazon.com/athena/latest/ug/partitions.html)

### Unload table and convert data format

##### Create Data Bucket

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```
# Create parquet data bucket
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
PAR1 8????????   ???      cb```fd??? ??+?????
    ,P????????   ???      cb```f??????????????FFF?????? ??I??    >b?????????   ???      cb```f?????y????????????F????f??f)???????I ??h    (H???????   ???      cb```f????????z hdb  
R??    0T????????   ???      cb```f???????zF??????z??????z???&??? ??,???f    B?????????
   ???      cb```fd?????&???&& C??e    >??????????   ???      cb```fd??????F?? ??o????
    <????????   ???      cb```fd???????? W>??    8????????   ???      cb```fd??? 0???7??
    B?????????   ???      cb```fdX????d0       <????????   ???      cb```f??2???? ??tL
    <?????????   ???      cb```f??oR ????????
     D????????
   ???      cb```fd???A??^????! ????4    <????????   ???      cb```fd??????? ~>1d           000111222333000111222333  eni-0339h23056c6d31kbeni-0339h23056c6d31kb  
10.0.0.240
10.0.0.240  50.219.198.14950.219.198.149  3414434144  123123  1717           ?????     ?????      z4{_z4{_  ??4{_??4{_  REJECTREJECT  OKOK  f   n~   ????   ??t   ?????   ??p   ??l   ??j   ??f   ??p   ??	j   ??	j   ??
r   ??j   ??Hhive_schema %version %account% L   %interfaceid% L   %
sourceaddress% L   %destinationaddress% L   %
sourceport% L   %destinationport% L   %protocol% L   %
numpackets %numbytes %	starttime %endtime %action% L   %	logstatus% L   ??&5 versionBf&<       (           ????. &n5 accountZ~&n<000111222333000111222333 (000111222333000111222333     ?????N &??5 interfaceidl??&??<eni-0339h23056c6d31kbeni-0339h23056c6d31kb (eni-0339h23056c6d31kbeni-0339h23056c6d31kb     ?????
r &??5 
sourceaddressTt&??<
10.0.0.240
10.0.0.240 (
10.0.0.240
10.0.0.240     ????F &??5 destinationaddress^???&??<50.219.198.14950.219.198.149 (50.219.198.14950.219.198.149     ????V &??5 
sourceportLp&??<3414434144 (3414434144     ????2 &??5 destinationportHl&??<123123 (123123     ????* &??5 protocolFj&??<1717 (1717     ????& &??5 
numpacketsBf&??<       (           ????. &??5 numbytesJp&??< ?????     ?????     ( ?????     ?????         ????> &??	5 	starttimeBj&??	<z4{_z4{_ (z4{_z4{_     ????. &??	5 endtimeBj&??	<??4{_??4{_ (??4{_??4{_     ????. &??
5 actionNr&??
<REJECTREJECT (REJECTREJECT     ?????6 &??5 	logstatusFj&??<OKOK (OKOK     ????& ?? (Xparquet-mr version 1.11.1-amzn-athena-1 (build e4c8769d72fd0e21068423a0ee114afeaa85df42)??                             
  PAR1
```
