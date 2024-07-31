#
# Dockerfile to build a microservice using the Python Alpine Linux image
#
# Sample build syntax (typically add repo prefix):  docker build -t microservice:1.0.1 .
#

# Use official Python image for Alpine Linux based on target platform
FROM --platform=linux/amd64 python:3.12.4-alpine3.20

# Define ARGs for consitency and possible parameter use
ARG APPUSRNAME=appusr
ARG APPUSRID=1101
ARG APPGRPNAME=appgrp
ARG APPGRPID=1101

# Create nonroot user and group. Combine RUN commands to reduce layers and build time
RUN addgroup -g ${APPGRPID} -S ${APPGRPNAME} \
  && adduser -u ${APPUSRID} -S ${APPUSRNAME}

# Copy the FastAPI app code into the container
COPY ./app /app

# Change ownership of the application to the app server and group
RUN chown -R ${APPUSRNAME}:${APPGRPNAME} /app

# Expose the port FastAPI will be running on
EXPOSE 8080

# Set the working directory
WORKDIR /app

# Set runtime user to the nonroot app user for security purposes
USER ${APPUSRNAME}

# Execute the following command upon container launch
CMD ["python", "/app/microservice.py"]

# Add metadata to the image
LABEL maintainer="Paul Reilly <irish.reilly@gmail.com>"

# End of Dockerfile
