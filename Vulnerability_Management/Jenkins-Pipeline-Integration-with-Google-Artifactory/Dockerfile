# Use Alpine Linux version 3.16.2
FROM alpine:3.19.3

# Install busybox-extras to get the httpd command
RUN apk add --no-cache busybox-extras

# Set the working directory in the container
WORKDIR /usr/share/web

# Copy the local files to the container's working directory
COPY www .

# Expose port 8080 for the web server
EXPOSE 8080

# Start the simple http server on port 8080
CMD ["httpd", "-f", "-p", "8080"]
