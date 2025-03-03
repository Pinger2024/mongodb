FROM mongo:latest

# Install openssl (if not already available)
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Generate CA key and certificate, and generate server key and certificate signed by the CA.
RUN openssl genrsa -out /etc/ssl/ca.key 4096 && \
    openssl req -x509 -new -nodes -key /etc/ssl/ca.key -sha256 -days 365 -out /etc/ssl/ca.crt -subj "/CN=MyMongoCA" && \
    openssl genrsa -out /etc/ssl/mongodb.key 4096 && \
    openssl req -new -key /etc/ssl/mongodb.key -out /etc/ssl/mongodb.csr -subj "/CN=localhost" && \
    openssl x509 -req -in /etc/ssl/mongodb.csr -CA /etc/ssl/ca.crt -CAkey /etc/ssl/ca.key -CAcreateserial -out /etc/ssl/mongodb.crt -days 365 -sha256 && \
    cat /etc/ssl/mongodb.key /etc/ssl/mongodb.crt > /etc/ssl/mongodb.pem

EXPOSE 27017

# Start MongoDB with TLS enabled using the generated certificates.
CMD ["mongod", "--tlsMode", "requireTLS", "--tlsCertificateKeyFile", "/etc/ssl/mongodb.pem", "--tlsCAFile", "/etc/ssl/ca.crt"]
