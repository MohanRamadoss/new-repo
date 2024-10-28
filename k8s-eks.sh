#!/bin/sh

set -o errexit
set -o pipefail
set -o nounset

# Check if required environment variables are set
: "${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION is not set}"
: "${AWS_ROLE_ARN:?AWS_ROLE_ARN is not set}"
: "${AWS_WEB_IDENTITY_TOKEN_FILE:?AWS_WEB_IDENTITY_TOKEN_FILE is not set}"

# Activate the virtual environment
. /opt/venv/bin/activate

# Set the AWS region
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

# Get the cluster name from the first argument
export CLUSTER_NAME=$1

# Get the private EKS endpoint
INTERNAL_ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.endpoint" --output text)
# Strip https:// from the endpoint
DNSNAME=$(echo "$INTERNAL_ENDPOINT" | sed 's/https:\/\///')

# Replace placeholders in the Privoxy configuration files with actual EKS endpoint values
sed -i "s|CLUSTER_ENDPOINT|${INTERNAL_ENDPOINT}|g" /etc/privoxy/eks.filter
sed -i "s|CLUSTER_DNS|${DNSNAME}|g" /etc/privoxy/eks.filter
sed -i "s|CLUSTER_ENDPOINT|${DNSNAME}|g" /etc/privoxy/eks.action

# Start Privoxy with the specified configuration
privoxy --no-daemon /etc/privoxy/config
