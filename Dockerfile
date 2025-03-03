FROM mongo:latest

# Copy the custom configuration file into the image
COPY mongod.conf /etc/mongod.conf

# Expose the default MongoDB port
EXPOSE 27017

# Start MongoDB using our custom configuration
CMD ["mongod", "--config", "/etc/mongod.conf"]
