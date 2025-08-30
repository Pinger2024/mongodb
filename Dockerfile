FROM mongo:latest

# Set GLIBC tunable environment variable
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install dropbear (lightweight SSH that works in Docker)
RUN apt-get update && \
    apt-get install -y dropbear supervisor numactl && \
    rm -rf /var/lib/apt/lists/*

# Setup directories for dropbear
RUN mkdir -p /etc/dropbear && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    # CRITICAL: Also create dropbear's expected authorized_keys location
    touch /etc/dropbear/authorized_keys && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /etc/dropbear/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Copy configurations
COPY mongod.conf /etc/mongod.conf

# Create supervisord config with dropbear allowing ALL connections
RUN echo '[supervisord]' > /etc/supervisor/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/supervisord.conf && \
    echo 'logfile=/var/log/supervisord.log' >> /etc/supervisor/supervisord.conf && \
    echo 'loglevel=debug' >> /etc/supervisor/supervisord.conf && \
    echo '' >> /etc/supervisor/supervisord.conf && \
    echo '[program:dropbear]' >> /etc/supervisor/supervisord.conf && \
    echo 'command=dropbear -F -E -B -p 22' >> /etc/supervisor/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/supervisord.conf && \
    echo 'stderr_logfile=/var/log/dropbear.log' >> /etc/supervisor/supervisord.conf && \
    echo 'stdout_logfile=/var/log/dropbear.log' >> /etc/supervisor/supervisord.conf && \
    echo '' >> /etc/supervisor/supervisord.conf && \
    echo '[program:mongod]' >> /etc/supervisor/supervisord.conf && \
    echo 'command=numactl --interleave=all /usr/bin/mongod --config /etc/mongod.conf' >> /etc/supervisor/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/supervisord.conf && \
    echo 'stderr_logfile=/var/log/mongod.log' >> /etc/supervisor/supervisord.conf && \
    echo 'stdout_logfile=/var/log/mongod.log' >> /etc/supervisor/supervisord.conf

# Create startup script to handle key injection
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo '# Check multiple locations for SSH keys' >> /entrypoint.sh && \
    echo 'if [ -f /render/authorized_keys ]; then' >> /entrypoint.sh && \
    echo '  cp /render/authorized_keys /etc/dropbear/authorized_keys' >> /entrypoint.sh && \
    echo '  cp /render/authorized_keys /root/.ssh/authorized_keys' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'if [ -n "$SSH_PUBLIC_KEY" ]; then' >> /entrypoint.sh && \
    echo '  echo "$SSH_PUBLIC_KEY" > /etc/dropbear/authorized_keys' >> /entrypoint.sh && \
    echo '  echo "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '# Start supervisor' >> /entrypoint.sh && \
    echo 'exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Expose ports
EXPOSE 27017 22

# Use entrypoint
ENTRYPOINT ["/entrypoint.sh"]