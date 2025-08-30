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
RUN bash -c 'cat > /etc/ssh/sshd_config << "EOF"
Port 22
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Default secure settings
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# CRITICAL: Allow Render internal proxy without authentication
# The 10.214.x.x range is Render internal network
Match Address 10.214.0.0/16
    PermitRootLogin without-password
    PubkeyAuthentication yes
    PasswordAuthentication yes
    PermitEmptyPasswords yes
    AuthenticationMethods none
    
# Also allow from other potential Render internal ranges
Match Address 10.0.0.0/8
    PermitRootLogin without-password
    PubkeyAuthentication yes
    PasswordAuthentication yes
    PermitEmptyPasswords yes
EOF'

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