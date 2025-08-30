FROM mongo:latest

# Set GLIBC tunable environment variable
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install required packages  
RUN apt-get update && \
    apt-get install -y openssh-server supervisor numactl && \
    rm -rf /var/lib/apt/lists/*

# Setup SSH 
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A

# Configure SSH to accept connections from Render's internal network
# The key insight: Render's proxy (10.214.x.x) needs special treatment
RUN echo 'Port 22' > /etc/ssh/sshd_config && \
    echo 'HostKey /etc/ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /etc/ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /etc/ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config && \
    echo '' >> /etc/ssh/sshd_config && \
    echo '# Default secure settings' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'UsePAM no' >> /etc/ssh/sshd_config && \
    echo 'X11Forwarding no' >> /etc/ssh/sshd_config && \
    echo 'PrintMotd no' >> /etc/ssh/sshd_config && \
    echo 'AcceptEnv LANG LC_*' >> /etc/ssh/sshd_config && \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server' >> /etc/ssh/sshd_config && \
    echo '' >> /etc/ssh/sshd_config && \
    echo '# CRITICAL: Allow Render internal proxy without authentication' >> /etc/ssh/sshd_config && \
    echo '# The 10.214.x.x range is Render internal network' >> /etc/ssh/sshd_config && \
    echo 'Match Address 10.214.0.0/16' >> /etc/ssh/sshd_config && \
    echo '    PermitRootLogin without-password' >> /etc/ssh/sshd_config && \
    echo '    PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo '    PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo '    PermitEmptyPasswords yes' >> /etc/ssh/sshd_config && \
    echo '    AuthenticationMethods none' >> /etc/ssh/sshd_config && \
    echo '' >> /etc/ssh/sshd_config && \
    echo '# Also allow from other potential Render internal ranges' >> /etc/ssh/sshd_config && \
    echo 'Match Address 10.0.0.0/8' >> /etc/ssh/sshd_config && \
    echo '    PermitRootLogin without-password' >> /etc/ssh/sshd_config && \
    echo '    PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo '    PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo '    PermitEmptyPasswords yes' >> /etc/ssh/sshd_config

# Create SSH directory and set up for key injection
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    # Set empty password for root to allow passwordless login from internal network
    passwd -d root

# Copy configurations
COPY mongod.conf /etc/mongod.conf
COPY supervisord.withSSH /etc/supervisor/supervisord.conf

# Expose ports
EXPOSE 27017 22

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]