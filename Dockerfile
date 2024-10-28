FROM alpine:latest

# Update package list and install dependencies
RUN apk update && \
    apk add --no-cache curl privoxy jq python3 py3-pip

# Create and activate a virtual environment, then install awscli
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install awscli

# Add Privoxy configuration files
ADD eksconfig /etc/privoxy/config
ADD eks.action /etc/privoxy/eks.action
ADD eks.filter /etc/privoxy/eks.filter

# Set ownership for Privoxy configuration files
RUN chown -R privoxy /etc/privoxy

# Add the script that sets up EKS and Privoxy
ADD k8s-eks.sh /
RUN chmod +x /k8s-eks.sh

# Expose Privoxy port
EXPOSE 8118/tcp

# Run the script on container start
ENTRYPOINT ["/opt/venv/bin/python3", "/k8s-eks.sh"]
