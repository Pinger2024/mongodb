FROM mongo:latest

# Install OpenSSL if not already present.
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Create an OpenSSL configuration file that includes the required Subject Alternative Names.
RUN echo "\
[req]\n\
distinguished_name = req_distinguished_name\n\
req_extensions = v3_req\n\
prompt = no\n\
\n\
[req_distinguished_name]\n\
CN = localhost\n\
\n\
[v3_req]\n\
subjectAltName = @alt_names\n\
\n\
[alt_names]\n\
DNS.1 = localhost\n\
IP.1 = 127.0.0.1\n" > /tmp/openssl.cnf

# Generate CA key and certificate.
RUN openssl genrsa -out /etc/ssl/ca.key 4096 && \
    openssl req -x509 -new -nodes -key /etc/ssl/ca.key -sha256 -days 365 \
      -out /etc/ssl/ca.crt -subj "/CN=MyMongoCA"

# Generate MongoDB server key and CSR using the configuration file.
RUN openssl genrsa -out /etc/ssl/mongodb.key 4096 && \
    openssl req -new -key /etc/ssl/mongodb.key -out /etc/ssl/mongodb.csr \
      -subj "/CN=localhost" -config /tmp/openssl.cnf

# Sign the server CSR with the CA and include SANs.
RUN openssl x509 -req -in /etc/ssl/mongodb.csr -CA /etc/ssl/ca.crt -CAkey /etc/ssl/ca.key \
      -CAcreateserial -out /etc/ssl/mongodb.crt -days 365 -sha256 \
      -extfile /tmp/openssl.cnf -extensions v3_req && \
    # Combine the key and certificate into one PEM file.
    cat /etc/ssl/mongodb.key /etc/ssl/mongodb.crt > /etc/ssl/mongodb.pem && \
    rm /tmp/openssl.cnf /etc/ssl/mongodb.csr

# Expose the MongoDB port.
EXPOSE 27017

# Start MongoDB with TLS enabled.
CMD ["mongod", "--tlsMode", "requireTLS", "--tlsCertificateKeyFile", "/etc/ssl/mongodb.pem", "--tlsCAFile", "/etc/ssl/ca.crt"]
