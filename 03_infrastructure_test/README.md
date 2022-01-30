# INFRASTRUCTURE TEST

## Deployment
* Runs a Docker Image, build on top of the latest stable Hasicorp Terraform image (1.1.4 at commit time). See [here](https://hub.docker.com/r/hashicorp/terraform/tags) 
* Terraform to deploy following resource (List is not exhaustive).
    * 2 Lambdas
    * IAM Roles 
    * Cloudwatch Event Triggers

## Network Topology
![This](https://github.com/JamesCampbellIDBS/interview-test-devops/blob/master/Network_Topology.png?raw=true)
