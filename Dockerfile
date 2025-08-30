FROM mongo:latest

# Set GLIBC tunable environment variable to disable unsupported rseq support.
ENV GLIBC_TUNABLES=glibc.pthread.rseq=0

# Install required packages for MongoDB (numactl for NUMA interleaving)
RUN apt-get update && \
    apt-get install -y supervisor numactl && \
    rm -rf /var/lib/apt/lists/*

# Copy configurations
COPY mongod.conf /etc/mongod.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Expose MongoDB port
EXPOSE 27017

# Run Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]