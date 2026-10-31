FROM docker.n8n.io/n8nio/n8n:latest

# Set working directory
WORKDIR /home/node

# Copy any custom configuration files if needed
# COPY custom-config/ /home/node/.n8n/

# Expose the n8n port
EXPOSE 5678

# Use the default n8n entrypoint and command
CMD ["n8n"]
