#!/bin/bash
set -e

# Extract cluster name from STDIN
eval "$(jq -r '@sh "CLUSTER_NAME=\(.cluster_name)"')"

# Retrieve token with AWS IAM Authenticator
export AWS_PROFILE=mediware
TOKEN=$(aws-iam-authenticator token -i $CLUSTER_NAME --token-only)

# Output token as JSON
jq -n --arg token "$TOKEN" '{"token": $token}'
