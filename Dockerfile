FROM mongo:latest

# Install required packages: openssh-server, supervisor (no need for bash if we use /bin/sh)
RUN apt-get update && \
    apt-get install -y openssh-server supervisor && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory with correct permissions
RUN mkdir -p /var/run/sshd && chmod 755 /var/run/sshd

# Generate SSH host keys
RUN ssh-keygen -A

# Create the Render service user with a dedicated home directory (not on /data/db)
# Use /bin/sh as the login shell
RUN useradd -m -d /home/srv-cv2rs8t6l47c739hee00 -s /bin/sh srv-cv2rs8t6l47c739hee00

# Set up the SSH directory for the new user with correct permissions
RUN mkdir -p /home/srv-cv2rs8t6l47c739hee00/.ssh && chmod 700 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Add your SSH public key (ensure the key line is exact—no extra spaces or text)
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" \
    > /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chmod 600 /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chown -R srv-cv2rs8t6l47c739hee00:srv-cv2rs8t6l47c739hee00 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Configure SSH server:
# - Disable root login
# - Enable public key authentication
# - Increase log level for debugging
# - Allow TTY allocation and restrict login to our user
# - Force a login shell (/bin/sh -l) so that an interactive shell is always spawned
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "LogLevel DEBUG3" >> /etc/ssh/sshd_config && \
    echo "PermitTTY yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers srv-cv2rs8t6l47c739hee00" >> /etc/ssh/sshd_config && \
    echo "ForceCommand /bin/sh -l" >> /etc/ssh/sshd_config

# Adjust PAM so that pam_loginuid is optional (avoiding session termination issues)
RUN sed -i 's/^session\s\+required\s\+pam_loginuid.so/session optional pam_loginuid.so/' /etc/pam.d/sshd

# Copy MongoDB configuration file (suppresses logs, etc.)
COPY mongod.conf /etc/mongod.conf

# Copy Supervisor configuration file
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Start Supervisor (which will manage both sshd and mongod)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
