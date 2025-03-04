FROM mongo:latest

# Install openssh-server and bash
RUN apt-get update && \
    apt-get install -y openssh-server bash && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory with correct permissions
RUN mkdir -p /var/run/sshd && chmod 755 /var/run/sshd

# Generate SSH host keys
RUN ssh-keygen -A

# Create the Render service user with a valid shell and home directory not on the persistent volume
RUN useradd -m -d /home/srv-cv2rs8t6l47c739hee00 -s /bin/bash srv-cv2rs8t6l47c739hee00

# Set up the SSH directory for the new user with correct permissions
RUN mkdir -p /home/srv-cv2rs8t6l47c739hee00/.ssh && chmod 700 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Add your SSH public key (remove extra text and leading whitespace)
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" \
    > /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chmod 600 /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chown -R srv-cv2rs8t6l47c739hee00:srv-cv2rs8t6l47c739hee00 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Configure SSH server:
# - Disable root login
# - Ensure pubkey authentication is on
# - Enable PAM (do not disable it)
# - Set a high debug level (for troubleshooting) – you can remove or lower this later
# - Allow TTY allocation and restrict login to our user
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "LogLevel DEBUG3" >> /etc/ssh/sshd_config && \
    echo "PermitTTY yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers srv-cv2rs8t6l47c739hee00" >> /etc/ssh/sshd_config

# Adjust PAM configuration so that pam_loginuid is optional (prevents immediate logout)
RUN sed -i 's/^session\s\+required\s\+pam_loginuid.so/session optional pam_loginuid.so/' /etc/pam.d/sshd

# Copy MongoDB configuration and the startup script into the image
COPY mongod.conf /etc/mongod.conf
COPY start.sh /start.sh

# Make the startup script executable
RUN chmod +x /start.sh

# Expose MongoDB and SSH ports
EXPOSE 27017 22

# Use the startup script as the entrypoint
ENTRYPOINT ["/start.sh"]
