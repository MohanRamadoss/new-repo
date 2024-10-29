#!/bin/sh

set -o errexit
set -o pipefail
set -o nounset

# Logging function for consistent output
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log_message "Starting k8s-eks.sh script"

# Set proxy settings
export http_proxy=http://squid-globalprod.amz.visa.com:3128
export https_proxy=http://squid-globalprod.amz.visa.com:3128
export no_proxy=169.254.169.254

log_message "Proxy settings configured"

# Ensure required environment variables are set
: "${CLUSTER_NAME:?CLUSTER_NAME is not set}"
: "${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION is not set}"
: "${AWS_ROLE_ARN:?AWS_ROLE_ARN is not set}"
: "${AWS_WEB_IDENTITY_TOKEN_FILE:?AWS_WEB_IDENTITY_TOKEN_FILE is not set}"

log_message "Required environment variables are set"
log_message "Using cluster name: $CLUSTER_NAME"

# Activate the virtual environment
. /opt/venv/bin/activate
log_message "Activated virtual environment"

# Fetch the internal EKS endpoint and hostname
EKS_ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.endpoint" --output text)
EKS_HOSTNAME=$(echo "$EKS_ENDPOINT" | awk -F[/:] '{print $4}')

log_message "Internal endpoint IP: $EKS_ENDPOINT"
log_message "Cluster hostname: $EKS_HOSTNAME"

# Replace placeholders in Privoxy filter and action files with actual EKS endpoint values
sed -i "s|CLUSTER_IP|${EKS_ENDPOINT}|g" /etc/privoxy/k8s-rewrite-internal.filter
sed -i "s|CLUSTER_DNS|${EKS_HOSTNAME}|g" /etc/privoxy/k8s-rewrite-internal.filter
sed -i "s|CLUSTER_IP|${EKS_HOSTNAME}|g" /etc/privoxy/k8s-only.action

log_message "Updated Privoxy configuration files"

# Start Privoxy without daemonizing
log_message "Starting Privoxy"
privoxy --no-daemon /etc/privoxy/config