# CODING TEST.

## RDS Backup Code:
* Code to take snapshots of AWS Oracle RDS instances at least once per day.
* Code will ONLY pick up databases with a specific naming convention. Convention set at deployment time.
* Script designed to run as a Lambda in AWS. So, this will fit nicely into my plans for the infrastructure test.  
* Output logged out to Cloudwatch. Any failures are sent to email via sns. 

## RDS Snapshot Copy Code:
* Code to get the snapshots, by RDS Instance. 
* Code will ONLY pick up databases with a specific naming convention.
* Code will copy snapshots to the 'copy_region' set as a tag on the source RDS Instance.


## Executing
Code written to run in AWS Lambda, and calls resources that are not available until all the Terraform resources deploy.
As such, recommend running the Script via the AWS Lambda Console. 