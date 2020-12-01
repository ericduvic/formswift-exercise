#!/usr/bin/env bash
set -euo pipefail

echo "==========================="
echo "End-to-End Integration Test"
echo "==========================="

echo "- Cleaning up any existing terraform artifacts"
pushd ../infra/example

if [ -f terraform.tfstate ]; then
    echo "  Error, terraform.tfstate file present"
    exit 1
fi

if [ -d .terraform ]; then
    echo "  Removing .terraform directory"
    rm -rf .terraform
fi

echo "- Deploying infrastructure and retrieving relevant output"

terraform init -upgrade
terraform plan
terraform apply -auto-approve

REGION=$(terraform output region)
CLUSTER_ARN=$(terraform output cluster_arn)
SERVICE_ARN=$(terraform output service_arn)
ENDPOINT_URL=$(terraform output lb_address)
ECR_URL=$(terraform output ecr_address)
ECR_LOGIN_URL=$(echo "${ECR_URL}" | cut -d'/' -f1)

popd

echo "- Retrieving AWS credentials for ECR"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_LOGIN_URL

echo "- Docker build, tag, and push"
pushd ../app

docker build -t local_image .
docker tag local_image:latest $ECR_URL:latest
docker push $ECR_URL:latest

popd

echo "- Waiting for service to be stable"
aws ecs wait services-stable --cluster $CLUSTER_ARN --services $SERVICE_ARN --region $REGION
TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_ARN --service $SERVICE_ARN --region $REGION --output json)
TASKS=$(echo $TASK_ARNS | jq -r '.taskArns | map(. | split("/")[2]) | join(" ")')
echo "~~~~~~~~~"
echo $TASKS

echo "- Waiting for tasks to start running"
aws ecs wait tasks-running --cluster $CLUSTER_ARN --tasks $TASKS --region $REGION

echo "- Givin' it a few more seconds... Ok a minute"
sleep 1m

# Normally we'd run the python integration test here, but just going to use CURL to keep things simple
echo "- Test URL"
RESPONSE=$(curl -s $ENDPOINT_URL)
if [ "$RESPONSE" = "Hello World!" ]; then
    echo "Success!"
    status="- Status: Success!"
    code=0
else
    echo "Test failed! Response was $RESPONSE"
    status="- Status: Failed :("
    code=1
fi

echo "- Cleaning up infrastructure"
pushd ../infra/example

terraform destroy -auto-approve
rm -f ./terraform.tfstate

popd

echo ""
echo "===================="
echo "End-to-End Finished!"
echo "===================="
echo $status
exit $code
