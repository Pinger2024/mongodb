FROM mongo:latest

# Install required packages
RUN apt-get update && \
    apt-get install -y openssh-server bash supervisor && \
    rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN mkdir -p /var/run/sshd && \
    chmod 755 /var/run/sshd && \
    ssh-keygen -A

# Create the Render service user with a proper home directory
RUN useradd -m -s /bin/bash srv-cv2rs8t6l47c739hee00 && \
    mkdir -p /home/srv-cv2rs8t6l47c739hee00/.ssh && \
    chmod 700 /home/srv-cv2rs8t6l47c739hee00/.ssh

# Add your SSH public key
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGh/m297KlsG8BbyuNeIqPWxgwoGMQbpeBJEuYaTHxh8 your-michael@prometheus-it.com" > /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chmod 600 /home/srv-cv2rs8t6l47c739hee00/.ssh/authorized_keys && \
    chown -R srv-cv2rs8t6l47c739hee00:srv-cv2rs8t6l47c739hee00 /home/srv-cv2rs8t6l47c739hee00

# Configure SSH settings with debug logging and permissive options
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitTTY yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers srv-cv2rs8t6l47c739hee00" >> /etc/ssh/sshd_config && \
    echo "LogLevel DEBUG3" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "StrictModes no" >> /etc/ssh/sshd_config

# Adjust PAM settings (optional since UsePAM no)
RUN sed -i 's/^session\s\+required\s\+pam_loginuid.so/session optional pam_loginuid.so/' /etc/pam.d/sshd

# Copy configurations
COPY mongod.conf /etc/mongod.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Expose necessary ports
EXPOSE 27017 22

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]