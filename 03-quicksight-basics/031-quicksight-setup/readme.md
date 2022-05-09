# QuickSight Access Setup


- #### Search and click on QuickSight in the AWS console


![](images/01-quicksight-search.png)

- #### Click on "Sign up for QuickSight"

![](images/02-quicksight-signup.png)

- #### Click on "Standard Edition"

![](images/03-quicksight-standard.png)

- #### Configure account parameters

    - Select a region (e.g Ireland)
    - Give the account a name (e.g. MyQuickSightAccount)
    - Give a notification email (e.g. you@domain.com)
    - Leave default values for the rest

![](images/04-quicksight-account-info.png)

- #### Click on "Go to Amazon QuickSight"

![](images/05-quicksight-congratulations.png)

- #### A page like this one should appear

![](images/06-quicksight-landing-page.png)

# QuickSight S3 Permissions Setup

- #### Access QuickSight management 

- #### Click on "Manage QuickSight" (Top Right Menu)

![](images/10-quicksight-manage.png)

- #### Click on "Security and permissions" then click on "Manage"

![](images/11-quicksight-manage-security-and-permissions.png)

- #### Click on "Select S3 Buckets" then click on "Manage"

![](images/12-quicksight-select-S3-buckets.png)

- #### You should select "read" for the buckets you want to read

- #### You should select "write" for query result bucket (the one used by you athena workgroup) 

- #### Click on "Finish"

![](images/13-quicksight-s3-buckets-permissions.png)

- #### Click on "Save"

![](images/14-quicksight-s3-bucket-permissions-save.png)