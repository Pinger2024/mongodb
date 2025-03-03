FROM mongo:latest

# Install openssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory
RUN mkdir -p /var/run/sshd

# Configure SSH: Enable root login and password authentication
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set a default root password for SSH (for testing only; use keys in production)
RUN echo 'root:yourpassword' | chpasswd

# Copy MongoDB config file into the container
COPY mongod.conf /etc/mongod.conf

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Start SSH and MongoDB in the background
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D & mongod --config /etc/mongod.conf"]