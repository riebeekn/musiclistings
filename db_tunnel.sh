#!/bin/bash

# Check if an environment is passed as an argument
if [ -z "$1" ]; then
  echo "Error: No environment provided."
  echo "Usage: $0 <environment>"
  echo "Example: $0 staging"
  exit 1
fi

# Set the environment variable
ENVIRONMENT=$1

# Variables
ECS_CLUSTER_NAME="musiclistings-${ENVIRONMENT}"
TARGET_RDS_ENDPOINT="musiclistings-${ENVIRONMENT}-database.chnsm0veqbkc.us-east-1.rds.amazonaws.com"

# Fetch the ECS Task ARN
AWS_TASK_ARN=$(aws ecs list-tasks --cluster "${ECS_CLUSTER_NAME}" | jq -r '.taskArns[]')

# Check if a task ARN was returned
if [ -z "${AWS_TASK_ARN}" ]; then
  echo "Error: No tasks found for cluster '${ECS_CLUSTER_NAME}'."
  exit 1
fi

# Describe the ECS Task
AWS_TASK=$(aws ecs describe-tasks --cluster "${ECS_CLUSTER_NAME}" --tasks "${AWS_TASK_ARN}")

# Extract runtime ID and task ID
AWS_TASK_RUNTIME_ID=$(echo "${AWS_TASK}" | jq -r '.tasks[0].containers[0].runtimeId')

if [ -z "${AWS_TASK_RUNTIME_ID}" ]; then
  echo "Error: Could not retrieve runtime ID for task '${AWS_TASK_ARN}'."
  exit 1
fi

AWS_TASK_ID=$(echo "${AWS_TASK_RUNTIME_ID}" | cut -d "-" -f 1)

# Construct the target reference for SSM
TARGET_REFERENCE="ecs:${ECS_CLUSTER_NAME}_${AWS_TASK_ID}_${AWS_TASK_RUNTIME_ID}"

# Start the SSM session
aws ssm start-session --target "${TARGET_REFERENCE}" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"portNumber\":[\"5432\"], \"host\":[\"${TARGET_RDS_ENDPOINT}\"], \"localPortNumber\":[\"5433\"]}"
