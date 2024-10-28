FROM alpine:latest

# Update package list and install dependencies
RUN apk update && \
    apk add --no-cache curl privoxy jq python3 py3-pip

# Create and activate a virtual environment, then install awscli
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install awscli

# Create necessary directories and set permissions
RUN mkdir -p /etc/privoxy && \
    chown -R privoxy /etc/privoxy

# Add Privoxy configuration files
ADD eksconfig /etc/privoxy/config
ADD eks.action /etc/privoxy/eks.action
ADD eks.filter /etc/privoxy/eks.filter

# Add the k8s-eks.sh script and make it executable
ADD k8s-eks.sh /
RUN chmod +x /k8s-eks.sh

# Expose Privoxy port
EXPOSE 8118/tcp

# Set ENTRYPOINT to the script
ENTRYPOINT ["/k8s-eks.sh"]
