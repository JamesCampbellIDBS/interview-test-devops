# INFRASTRUCTURE TEST

## Deployment
* Runs a Docker Image, build on top of the latest stable Hasicorp Terraform image (1.1.4 at commit time). See [here](https://hub.docker.com/r/hashicorp/terraform/tags) 
* Terraform to deploy following resource (List is not exhaustive).
    * 2 Lambdas
    * IAM Roles 
    * Cloudwatch Event Triggers

## Network Topology
![This](https://github.com/JamesCampbellIDBS/interview-test-devops/blob/master/03_infrastructure_test/backup-topology.png?raw=true)

## Executing
The pipeline can be executed locally, with Docker:

```bash
$ docker build -t rds-backup .
$ docker run -e 'DEPLOYMENT_NAME=euw1' \
             -e 'DEPLOYMENT_VAR_FILE=dev-euw1.tfvars' \
             -e 'DEPLOYMENT_TYPE=dev' \
             rds-backup
```
## Result
Terraform will output the arn's of the resources created.
The lambdas will execute on the scheduled crons. And can be tested via the Lambda console.

# TODO!!
* Testing: the deployment end to end. Not able to test in AWS, as I don't have an account.
* Improvements: Lambda Terraform code duplicated a little, due to there being multiple Lambda's. Consider breaking out into TF Modules.
