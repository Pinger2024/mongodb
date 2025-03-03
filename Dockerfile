FROM mongo:latest

# Install openssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory
RUN mkdir -p /var/run/sshd

# Generate SSH host keys
RUN ssh-keygen -A

# Create the user for Render SSH with your service ID
RUN useradd -m -s /bin/bash srv-cv0sdd9u0jms73alp910
RUN mkdir -p /home/srv-cv0sdd9u0jms73alp910/.ssh
# Add your public key
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" > /home/srv-cv0sdd9u0jms73alp910/.ssh/authorized_keys
RUN chown -R srv-cv0sdd9u0jms73alp910:srv-cv0sdd9u0jms73alp910 /home/srv-cv0sdd9u0jms73alp910/.ssh
RUN chmod 700 /home/srv-cv0sdd9u0jms73alp910/.ssh
RUN chmod 600 /home/srv-cv0sdd9u0jms73alp910/.ssh/authorized_keys

# Copy MongoDB config and startup script into the container
COPY mongod.conf /etc/mongod.conf
COPY start.sh /start.sh

# Make the script executable
RUN chmod +x /start.sh

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Set the entrypoint to run the startup script
ENTRYPOINT ["/start.sh"]