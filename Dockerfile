FROM mongo:latest

# Expose the default MongoDB port
EXPOSE 27017

# Start MongoDB without TLS
CMD ["mongod"]
