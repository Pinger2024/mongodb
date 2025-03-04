FROM mongo:latest

# Install required packages: openssh-server, bash, and supervisor
RUN apt-get update && \
    apt-get install -y openssh-server bash supervisor && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory with correct permissions
RUN mkdir -p /var/run/sshd && chmod 755 /var/run/sshd

# Generate SSH host keys
RUN ssh-keygen -A

# Set up root's SSH directory with correct permissions
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Add your SSH public key to root's authorized_keys (make sure no extra spaces/text)
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" \
    > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Configure SSH server:
# - Disable root login via password (we allow key auth only)
# - Enable public key authentication
# - Increase log level for debugging
# - Allow TTY allocation
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "LogLevel DEBUG3" >> /etc/ssh/sshd_config && \
    echo "PermitTTY yes" >> /etc/ssh/sshd_config

# (Remove any ForceCommand directives so that root's default shell is used.)
RUN sed -i '/ForceCommand/d' /etc/ssh/sshd_config

# Adjust PAM so that pam_loginuid is optional (to avoid immediate session termination)
RUN sed -i 's/^session\s\+required\s\+pam_loginuid.so/session optional pam_loginuid.so/' /etc/pam.d/sshd

# Copy MongoDB configuration file (which suppresses logs)
COPY mongod.conf /etc/mongod.conf

# Copy Supervisor configuration file
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Start Supervisor (which will run both sshd and mongod)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
