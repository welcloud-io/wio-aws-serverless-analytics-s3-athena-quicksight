## Use Case Athena Setup

#### Config

###### Config Table
```sql
CREATE EXTERNAL TABLE
config (
  configurationItems array < 
    struct <
      resourceType:string,
      resourceId:string,
      awsaccountId:string,
      configurationItemCaptureTime:string,
      resourceCreationTime:string,
      configuration:struct <
        subnetId:string,
        vpcId:string
      >,
      tags:map<string, string>
    >
  > 
) PARTITIONED BY (
    p_account string,
    p_region string,
    p_date string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://[CONFIG-BUCKET]/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.p_account.type' = 'enum',
    'projection.p_account.values' = '[list-of-aws-accounts]',
    'projection.p_date.format' = 'yyyy/M/d',
    'projection.p_date.range' = '2022/01/01,NOW',
    'projection.p_date.type' = 'date',
    'projection.p_region.type' = 'enum',
    'projection.p_region.values' = 'eu-west-1',
    'storage.location.template' = 's3://[CONFIG-BUCKET/folders]/${p_account}/Config/${p_region}/${p_date}/ConfigSnapshot'
)
```

###### Config View

```sql
CREATE OR REPLACE VIEW "config_view" AS 
SELECT
  configurationItem.configurationItemCaptureTime
, configurationItem.resourceCreationTime
, configurationItem.awsaccountId
, configurationItem.resourceType
, configurationItem.resourceid
, configurationItem.configuration.vpcid
, configurationItem.tags['name'] as name
, config.p_account
, config.p_region
, DATE(date_parse(p_date, '%Y/%m/%d')) as p_date
FROM
  (config
CROSS JOIN UNNEST(configurationitems) t (configurationItem))
```
#### Cloudtrail

###### Cloudtrail Table

```sql
CREATE EXTERNAL TABLE cloudtrail_logs (
eventversion STRING,
useridentity STRUCT<
               type:STRING,
               principalid:STRING,
               arn:STRING,
               accountid:STRING,
               invokedby:STRING,
               accesskeyid:STRING,
               userName:STRING,
sessioncontext:STRUCT<
attributes:STRUCT<
               mfaauthenticated:STRING,
               creationdate:STRING>,
sessionissuer:STRUCT<  
               type:STRING,
               principalId:STRING,
               arn:STRING, 
               accountId:STRING,
               userName:STRING>>>,
eventtime STRING,
eventsource STRING,
eventname STRING,
awsregion STRING,
sourceipaddress STRING,
useragent STRING,
errorcode STRING,
errormessage STRING,
requestparameters STRING,
responseelements STRING,
additionaleventdata STRING,
requestid STRING,
eventid STRING,
resources ARRAY<STRUCT<
               ARN:STRING,
               accountId:STRING,
               type:STRING>>,
eventtype STRING,
apiversion STRING,
readonly STRING,
recipientaccountid STRING,
serviceeventdetails STRING,
sharedeventid STRING,
vpcendpointid STRING
) PARTITIONED BY (
    p_account string,
    p_region string,
    p_date string
)
ROW FORMAT SERDE 'com.amazon.emr.hive.serde.CloudTrailSerde'
STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://[CLOUDTRAIL-BUCKET]/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.p_account.type' = 'enum',
    'projection.p_account.values' = '[list-of-aws-accounts]',
    'projection.p_date.format' = 'yyyy/M/d',
    'projection.p_date.range' = '2020/01/01,NOW',
    'projection.p_date.type' = 'date',
    'projection.p_region.type' = 'enum',
    'projection.p_region.values' = 'eu-west-1',
    'storage.location.template' = 's3://[CLOUDTRAIL-BUCKET/folders]/AWSLogs/${p_account}/CloudTrail/${p_region}/${p_date}')
```

```sql
CREATE OR REPLACE VIEW cloudtrail_view AS
SELECT 
    eventsource, 
    eventname,
    eventtime,
    useridentity.sessioncontext.sessionissuer.arn as userarn,
    CASE
    WHEN cast(json_extract(requestparameters, '$.instancesSet.items[0].instanceId') as varchar) != ''
    THEN cast(json_extract(requestparameters, '$.instancesSet.items[0].instanceId') as varchar)
    WHEN cast(json_extract(responseelements, '$.instancesSet.items[0].instanceId') as varchar)  != ''
    THEN cast(json_extract(responseelements, '$.instancesSet.items[0].instanceId') as varchar)
    END as instanceid,
	cloudtrail_logs.p_account,
	cloudtrail_logs.p_region,
	DATE(date_parse(cloudtrail_logs.p_date, '%Y/%m/%d')) as p_date
FROM cloudtrail_logs
```

#### Cost and usage report

###### Cost and usage report table

```sql

CREATE EXTERNAL TABLE hourly-report.hourly_report(
	identity_line_item_id STRING,
	identity_time_interval STRING,
	bill_invoice_id STRING,
	bill_invoicing_entity STRING,
	bill_billing_entity STRING,
	bill_bill_type STRING,
	bill_payer_account_id STRING,
	bill_billing_period_start_date TIMESTAMP,
	bill_billing_period_end_date TIMESTAMP,
	line_item_usage_account_id STRING,
	line_item_line_item_type STRING,
	line_item_usage_start_date TIMESTAMP,
	line_item_usage_end_date TIMESTAMP,
	line_item_product_code STRING,
	line_item_usage_type STRING,
	line_item_operation STRING,
	line_item_availability_zone STRING,
	line_item_resource_id STRING,
	line_item_usage_amount DOUBLE,
	line_item_normalization_factor DOUBLE,
	line_item_normalized_usage_amount DOUBLE,
	line_item_currency_code STRING,
	line_item_unblended_rate STRING,
	line_item_unblended_cost DOUBLE,
	line_item_blended_rate STRING,
	line_item_blended_cost DOUBLE,
	line_item_line_item_description STRING,
	line_item_tax_type STRING,
	line_item_legal_entity STRING,
	product_product_name STRING,
	product_availability STRING,
	product_category STRING,
	product_ci_type STRING,
	product_description STRING,
	product_durability STRING,
	product_edition STRING,
	product_endpoint_type STRING,
	product_free_query_types STRING,
	product_from_location STRING,
	product_from_location_type STRING,
	product_from_region_code STRING,
	product_group STRING,
	product_group_description STRING,
	product_location STRING,
	product_location_type STRING,
	product_logs_destination STRING,
	product_message_delivery_frequency STRING,
	product_message_delivery_order STRING,
	product_operation STRING,
	product_platopricingtype STRING,
	product_platostoragetype STRING,
	product_product_family STRING,
	product_queue_type STRING,
	product_region STRING,
	product_region_code STRING,
	product_servicecode STRING,
	product_servicename STRING,
	product_sku STRING,
	product_storage_class STRING,
	product_storage_media STRING,
	product_storage_type STRING,
	product_subscription_type STRING,
	product_to_location STRING,
	product_to_location_type STRING,
	product_to_region_code STRING,
	product_transfer_type STRING,
	product_usagetype STRING,
	product_version STRING,
	product_volume_type STRING,
	product_with_active_users STRING,
	pricing_rate_code STRING,
	pricing_rate_id STRING,
	pricing_currency STRING,
	pricing_public_on_demand_cost DOUBLE,
	pricing_public_on_demand_rate STRING,
	pricing_term STRING,
	pricing_unit STRING,
	reservation_amortized_upfront_cost_for_usage DOUBLE,
	reservation_amortized_upfront_fee_for_billing_period DOUBLE,
	reservation_effective_cost DOUBLE,
	reservation_end_time STRING,
	reservation_modification_status STRING,
	reservation_normalized_units_per_reservation STRING,
	reservation_number_of_reservations STRING,
	reservation_recurring_fee_for_usage DOUBLE,
	reservation_start_time STRING,
	reservation_subscription_id STRING,
	reservation_total_reserved_normalized_units STRING,
	reservation_total_reserved_units STRING,
	reservation_units_per_reservation STRING,
	reservation_unused_amortized_upfront_fee_for_billing_period DOUBLE,
	reservation_unused_normalized_unit_quantity DOUBLE,
	reservation_unused_quantity DOUBLE,
	reservation_unused_recurring_fee DOUBLE,
	reservation_upfront_value DOUBLE,
	savings_plan_total_commitment_to_date DOUBLE,
	savings_plan_savings_plan_a_r_n STRING,
	savings_plan_savings_plan_rate DOUBLE,
	savings_plan_used_commitment DOUBLE,
	savings_plan_savings_plan_effective_cost DOUBLE,
	savings_plan_amortized_upfront_commitment_for_billing_period DOUBLE,
	savings_plan_recurring_commitment_for_billing_period DOUBLE
)

PARTITIONED BY (
	year STRING,
	month STRING
)
         
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
WITH  SERDEPROPERTIES (
 'serialization.format' = '1'
) LOCATION 's3://[S3/Cost/And/Usage/Report/Folder]'
```

#### Flow Logs

###### Flow Logs table

```sql
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
) PARTITIONED BY (
  p_account string, 
  p_region string, 
  p_date string
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
LOCATION 's3://[FLOWLOGS-BUCKET]/' 
TBLPROPERTIES
(
'skip.header.line.count'='1',
'projection.enabled' = 'true',
'projection.p_account.type' = 'enum',
'projection.p_account.values' = '[list-of-aws-accounts]',
'projection.p_date.type' = 'date',
'projection.p_date.range' = '2020/01/01,NOW',
'projection.p_date.format' = 'yyyy/MM/dd',
'projection.p_region.type' = 'enum',
'projection.p_region.values' = 'eu-west-1',
'storage.location.template' = 's3://[FLOWLOGS-BUCKET/folders]/${p_account}/vpcflowlogs/${p_region}/${p_date}'
)
```