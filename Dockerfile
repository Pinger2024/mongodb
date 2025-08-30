FROM mongo:latest

# Set GLIBC tunable environment variable
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install required packages  
RUN apt-get update && \
    apt-get install -y openssh-server supervisor numactl bash && \
    rm -rf /var/lib/apt/lists/*

# Setup SSH with minimal configuration for Render
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A

# CRITICAL: Set up SSH to accept any keys that Render provides
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config && \
    echo "StrictModes no" >> /etc/ssh/sshd_config

# Create .ssh directory structure
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Copy configurations
COPY mongod.conf /etc/mongod.conf
COPY supervisord.withSSH /etc/supervisor/supervisord.conf

# Expose ports
EXPOSE 27017 22

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]