FROM mongo:latest

# Set GLIBC tunable environment variable to disable unsupported rseq support.
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install required packages
RUN apt-get update && \
    apt-get install -y openssh-server supervisor numactl && \
    rm -rf /var/lib/apt/lists/*

# Setup SSH for Render (without hardcoded keys)
RUN mkdir -p /var/run/sshd && \
    chmod 755 /var/run/sshd && \
    ssh-keygen -A && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Configure SSH for Render compatibility
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "StrictModes no" >> /etc/ssh/sshd_config

# Copy configurations
COPY mongod.conf /etc/mongod.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Expose necessary ports
EXPOSE 27017 22

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]