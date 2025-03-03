# Use the latest official MongoDB image (adjust the version if desired)
FROM mongo:latest

# Copy TLS certificate files into the image.
# Ensure that these files (mongodb.pem and ca.crt) are in your repository.
# mongodb.pem should contain your server’s private key and certificate.
COPY mongodb.pem /etc/ssl/mongodb.pem
COPY ca.crt /etc/ssl/ca.crt

# Expose the default MongoDB port
EXPOSE 27017

# Start mongod with TLS enabled
CMD ["mongod", "--tlsMode", "requireTLS", "--tlsCertificateKeyFile", "/etc/ssl/mongodb.pem", "--tlsCAFile", "/etc/ssl/ca.crt"]
