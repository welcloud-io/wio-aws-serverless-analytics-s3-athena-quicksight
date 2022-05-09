#!/usr/bin/bash

ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)

# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
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

sleep 5

# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
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
