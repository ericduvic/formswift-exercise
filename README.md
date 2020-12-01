# FormSwift Sr. Devops Engineer Bonus Exercise: `simple-fargate` Terraform Module

## Purpose
This repository is intended to fulfill a challenge exercise by FormSwift for their Senior DevOps Engineer role. It is not intended to be production-ready code - only demonstrate proficiency with Terraform:

```
Similar to the assessment in your first-round interview, we’d like you to create a Terraform module that can be used to host a simple "Hello World" Flask Python container using AWS resources. This time we’d like you to write real Terraform code that can be run to spin up this infrastructure. You may use any modules you wish and any method of getting your application hosted so long as you’re running a container on AWS resources. Assume that as inputs to your module we’ll provide VPC subnets for your application to run within and as an output we’d like an application load balancer URL to our running application. We’ll be running your module with the latest stable Terraform and AWS provider to ensure resources are built correctly without errors and then doing a curl request to verify we see a “Hello World” response.
```

The `simple-fargate` module is intended to provide a barebones container deployment to AWS Fargate. It does not support any advanced features that you would expect from a proper Fargate module.

The `helloworld` app's container is running in debug mode for simplicity's sake. In an actual production environment, this would run behind a WSGI compliant tool such as uWSGI or Gunicorn.

## Prerequisites
This module requires that public subnets exist with HTTP routing to the internet and private subnets, and private subnets exist with HTTP routing to public subnets. An application load balancer is deployed in the public subnets and a Fargate service is deployed in the private subnets. Please refer to the `infra/example` directory for an example of deployment.

## Usage
```
module "fargate" {
  source      = "../modules/simple-fargate"

  app         = var.app

  vpc_id      = var.vpc_id
  app_subnets = var.private_subnets
  lb_subnets  = var.public_subnets
}
```
### Variables
- **app**: The name of the app
- **vpc_id**: The VPC ID in which to deploy
- **app_subnets**: Subnets in which to deploy fargate
- **lb_subnets**: Subnets in which to deploy the load balancer

### Optional Variables
- **cpu**: The CPU count for each task instance. Default of `256`
- **memory**: The amount of RAM to dedicate to each task instance. Default of `512`
- **task_container_port**: The port to expose for the container. Default of `80`
- **task_container_tag**: The tag of the image to deploy. Default of `latest`
- **desired_count**: The desired number of instances. Default of `2`

### Outputs
- **cluster_arn**: The ARN of the ECS Fargate Cluster
- **service_arn**: The ARN of the deployed ECS Service
- **lb_address**: The URL for the load balancer
- **ecr_address**: The URL for the ECR image repository

## Testing
There is an end-to-end script in the `tests` subdirectory, called `end-to-end.sh`. These are the requirements:
- AWS CLI
- Terraform
- jq

You must also have your credentials set in environment variables, just like normal when using the AWS CLI or Terraform

This script will apply the Terraform manifest under the `example` directory, which will do the following:
- Deploy base networking infrastructure
- Deploy the `simple-fargate` module, which will:
    - Create an ECR repo and Fargate Cluster
    - Deploy the `helloworld` service to that cluster
- Build and push the `helloworld` Python Flask container
- Wait for services to be available
- Test the application
- Tear down infrastructure

### Notes:
- The example manifest does not use any sort of remote state, as it is an example that isn't meant to be production-ready.