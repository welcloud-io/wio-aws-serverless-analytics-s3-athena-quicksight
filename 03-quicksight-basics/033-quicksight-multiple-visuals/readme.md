## Upload more data on s3

From <a href="https://eu-west-1.console.aws.amazon.com/cloudshell" target="_blank">AWS CloudShell</a>
or from your own local terminal configured with iam credentials, run :

```
# Create local data file
cat << EOF > moredata.csv
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 76000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 86000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.241 50.217.198.149 34144 123 17 1 96000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.241 50.217.198.140 34144 123 17 1 16000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 26000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 36000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 46000000 1652270400 1652270410 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 76000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 86000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.241 50.217.198.149 34144 123 17 1 96000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.241 50.217.198.140 34144 123 17 1 16000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 26000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 36000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 46000000 1652270400 1652270410 REJECT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 76000000 1652184000 1652184010 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.240 50.217.198.149 34144 123 17 1 86000000 1652184000 1652184010 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.241 50.217.198.149 34144 123 17 1 96000000 1652184000 1652184010 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.241 50.217.198.140 34144 123 17 1 16000000 1652184000 1652184010 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 26000000 1652184000 1652184010 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 36000000 1652184000 1652184010 ACCEPT OK
2 000111222333 eni-0000h23056c6d31kb 10.0.0.242 50.217.198.140 34144 123 17 1 46000000 1652184000 1652184010 ACCEPT OK
EOF

# Create data bucket and upload data file
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1 --region eu-west-1
aws s3 cp moredata.csv s3://serverless-analytics-demo-csv-${ACCOUNT_NUMBER}-eu-west-1

# Remove local data file
rm moredata.csv
```

- #### Refresh quicksight with new data
![](images/30-quicksight-moredata.png)

## Use filters

- #### Filter on 'ACCEPT' (Use 'Focus Only on ...' menu)
![](images/31-quicksight-add-filter.png)

- #### Select filter menu in Quicksight
![](images/32-quicksight-add-filter-result.png)

- #### Filter on date
![](images/35-quicksight-add-date-filter.png)

- #### Add filter to sheet
![](images/36-quicksight-add-filter-to-sheet.png)

- #### Add filter as control (pin to top)
![](images/37-quicksight-pin-filter-to-top.png)

- #### Select a date range
![](images/38-quicksight-select-date-in-filter.png)

## Use parameters

- #### Create a parameter
![](images/39-quicksight-create-parameter.png)

- #### Make parameter as control
![](images/40-quicksight-create-control.png)

- #### Select the content of the control
![](images/41-quicksight-create-control-with-list.png)

- #### Display control dop down list
![](images/43-quicksight-parameter-and-control-created.png)

- #### Edit Filter
![](images/44-quicksight-edit-filter.png)

- #### Use parameter in filter
![](images/45-quicksight-use-parameter-in-filter.png)

## Use actions

- #### Duplicate Visual
![](images/33-quicksight-duplicate-visual.png)

- #### Choose a pie chart and select the right fields
![](images/34-quicksight-create-pie-chart.png)

- #### Create new visual
![](images/50-quicksight-action-new-visual.png)

- #### Create action
![](images/51-quicksight-action-create.png)

- #### Test Action
![](images/52-quicksight-action-select.png)