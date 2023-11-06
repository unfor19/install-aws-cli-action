# Use the official Ubuntu 20.04 base image
FROM ubuntu:20.04

# Update the package list and install the necessary dependencies
RUN apt-get update -y && apt-get install -y wget unzip python3

# Set the working directory within the container to /app/
WORKDIR /app/

# Copy the contents of the current directory (your host machine) to /app/ in the container
COPY . .

# Define the entry point command to run when the container starts
ENTRYPOINT ["./entrypoint.sh"]
