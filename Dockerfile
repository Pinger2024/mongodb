FROM mongo:latest

# Install openssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory
RUN mkdir -p /var/run/sshd

# Generate SSH host keys (required for SSH to start)
RUN ssh-keygen -A

# Create the Render service user (matches your service ID)
RUN useradd -m -s /bin/bash srv-cv0sdd9u0jms73alp910

# Set up SSH directory with correct permissions (Render requirement)
RUN mkdir -p /home/srv-cv0sdd9u0jms73alp910/.ssh && \
    chmod 700 /home/srv-cv0sdd9u0jms73alp910/.ssh

# Add your SSH public key for key-based authentication
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" > /home/srv-cv0sdd9u0jms73alp910/.ssh/authorized_keys && \
    chmod 600 /home/srv-cv0sdd9u0jms73alp910/.ssh/authorized_keys && \
    chown -R srv-cv0sdd9u0jms73alp910:srv-cv0sdd9u0jms73alp910 /home/srv-cv0sdd9u0jms73alp910/.ssh

# Configure SSH server (optional: adjust based on needs)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Copy MongoDB config and startup script
COPY mongod.conf /etc/mongod.conf
COPY start.sh /start.sh

# Make the startup script executable
RUN chmod +x /start.sh

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Use the startup script as the entrypoint
ENTRYPOINT ["/start.sh"]