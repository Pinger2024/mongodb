FROM mongo:latest

# Install openssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory
RUN mkdir -p /var/run/sshd

# Configure SSH: Enable root login and password authentication
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set a default root password for SSH (for testing; use SSH keys in production)
RUN echo 'root:yourpassword' | chpasswd

# Copy MongoDB config and startup script into the container
COPY mongod.conf /etc/mongod.conf
COPY start.sh /start.sh

# Make the script executable
RUN chmod +x /start.sh

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Override the default entrypoint to run the startup script directly
ENTRYPOINT ["/start.sh"]