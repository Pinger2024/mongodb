FROM mongo:latest

# Set GLIBC tunable environment variable
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install dropbear instead of openssh-server (critical for Docker!)
RUN apt-get update && \
    apt-get install -y dropbear supervisor numactl && \
    rm -rf /var/lib/apt/lists/*

# Dropbear keys are already generated during install, just ensure directory exists
RUN mkdir -p /etc/dropbear

# Create SSH directory for root
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Copy configurations
COPY mongod.conf /etc/mongod.conf

# Create a new supervisord config with dropbear
RUN echo '[supervisord]' > /etc/supervisor/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/supervisord.conf && \
    echo 'logfile=/var/log/supervisord.log' >> /etc/supervisor/supervisord.conf && \
    echo 'loglevel=debug' >> /etc/supervisor/supervisord.conf && \
    echo '' >> /etc/supervisor/supervisord.conf && \
    echo '[program:dropbear]' >> /etc/supervisor/supervisord.conf && \
    echo 'command=dropbear -F -E -w -s -g -p 22' >> /etc/supervisor/supervisord.conf && \
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

# Expose ports
EXPOSE 27017 22

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]