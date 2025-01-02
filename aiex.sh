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
ECS_CLUSTER_NAME="music-listings-aws-${ENVIRONMENT}"
CONTAINER_NAME="music-listings-aws-${ENVIRONMENT}"

# Fetch the ECS Task ARN
AWS_TASK_ARN=$(aws ecs list-tasks --cluster "${ECS_CLUSTER_NAME}" | jq -r '.taskArns[]')

# Check if a task ARN was returned
if [ -z "${AWS_TASK_ARN}" ]; then
  echo "Error: No tasks found for cluster '${ECS_CLUSTER_NAME}'."
  exit 1
fi

# Extract the Task ID from the ARN
AWS_TASK_ID=$(basename "${AWS_TASK_ARN}")

# Execute the command on the ECS container
aws ecs execute-command \
  --cluster "${ECS_CLUSTER_NAME}" \
  --task "${AWS_TASK_ID}" \
  --container "${CONTAINER_NAME}" \
  --interactive \
  --command "/bin/sh -c 'bin/music_listings remote'"
