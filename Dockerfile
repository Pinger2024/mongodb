FROM mongo:latest

# Install openssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Create the SSH run directory
RUN mkdir /var/run/sshd

# Create a non-root user (e.g., "appuser") with an interactive shell and set a password
RUN useradd -m -s /bin/bash appuser && \
    echo "appuser:yourpassword" | chpasswd

# (Optional) If you need to modify an existing non-root user to ensure it has shell access,
# you can use usermod. For example:
# RUN usermod -s /bin/bash appuser

# Configure SSH to allow password authentication and allow root login if desired
# (Note: In production, consider using SSH keys instead of passwords.)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Copy a custom MongoDB configuration if you want to suppress logs, etc.
# (Make sure mongod.conf is in your repository.)
COPY mongod.conf /etc/mongod.conf

# Expose both MongoDB (27017) and SSH (22) ports
EXPOSE 27017 22

# Start SSH service and then start MongoDB using your custom configuration
CMD service ssh start && mongod --config /etc/mongod.conf
