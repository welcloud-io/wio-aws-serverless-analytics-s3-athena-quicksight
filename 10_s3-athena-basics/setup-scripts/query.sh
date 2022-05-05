#!/usr/bin/bash

# ------------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------------
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
