FROM mongo:latest

# Install openssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Create SSH run directory
RUN mkdir /var/run/sshd

# Configure SSH: Enable root login and password authentication (for testing)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Optionally, add your public key to root's authorized_keys if you want key-only auth
# COPY your-public-key.pub /root/.ssh/authorized_keys
# RUN chmod 600 /root/.ssh/authorized_keys

# Expose ports for MongoDB (27017) and SSH (22)
EXPOSE 27017 22

# Start both SSH and MongoDB
CMD service ssh start && mongod
