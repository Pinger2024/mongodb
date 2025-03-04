FROM mongo:latest

# Install openssh-server and ensure bash is available
RUN apt-get update && \
    apt-get install -y openssh-server bash && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory with correct permissions
RUN mkdir -p /var/run/sshd && \
    chmod 755 /var/run/sshd

# Generate SSH host keys
RUN ssh-keygen -A

# Create the Render service user with a verified shell
RUN useradd -m -s /bin/bash srv-cv2rs8t6l47c739hee00

# Set up SSH directory with correct permissions
RUN mkdir -p /home/srv-cv2rs8t6l47c739hee00/.ssh && \
    chmod 700 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Add your SSH public key
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" > /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chmod 600 /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chown -R srv-cv2rs8t6l47c739hee00:srv-cv2rs8t6l47c739hee00 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Configure SSH server: Disable PAM, max debug logging, ensure session compatibility
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "LogLevel DEBUG3" >> /etc/ssh/sshd_config && \
    echo "PermitTTY yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers srv-cv2rs8t6l47c739hee00" >> /etc/ssh/sshd_config

# Copy MongoDB config
COPY mongod.conf /etc/mongod.conf

# Expose ports
EXPOSE 27017 22

# Run SSH in foreground with debug, then MongoDB
CMD ["/bin/bash", "-c", "/usr/sbin/sshd -D -e && mongod --config /etc/mongod.conf"]