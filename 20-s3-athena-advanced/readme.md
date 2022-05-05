### Create Athena Table Partitions

... to be completed

### Convert date format

... to be completed

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
