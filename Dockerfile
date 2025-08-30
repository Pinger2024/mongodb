FROM mongo:latest

# Set GLIBC tunable environment variable
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install dropbear instead of openssh-server (critical for Docker!)
RUN apt-get update && \
    apt-get install -y dropbear supervisor numactl && \
    rm -rf /var/lib/apt/lists/*

# Setup dropbear SSH (much simpler than OpenSSH)
RUN mkdir -p /etc/dropbear && \
    # Generate host keys for dropbear
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key && \
    dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key && \
    dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key

# Create SSH directory for root
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Copy configurations
COPY mongod.conf /etc/mongod.conf

# Create a new supervisord config with dropbear
RUN cat > /etc/supervisor/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
loglevel=debug

[program:dropbear]
command=dropbear -F -E -w -s -g -p 22
autostart=true
autorestart=true
stderr_logfile=/var/log/dropbear.log
stdout_logfile=/var/log/dropbear.log

[program:mongod]
command=numactl --interleave=all /usr/bin/mongod --config /etc/mongod.conf
autostart=true
autorestart=true
stderr_logfile=/var/log/mongod.log
stdout_logfile=/var/log/mongod.log
EOF

# Expose ports
EXPOSE 27017 22

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]