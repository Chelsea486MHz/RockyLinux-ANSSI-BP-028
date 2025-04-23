FROM rockylinux:9

# Install required dependencies
RUN dnf -y install \
    createrepo \
    dnf-utils \
    genisoimage \
    isomd5sum \
    syslinux \
    xorriso \
    && dnf clean all

# Set up working directory
WORKDIR /app

# Copy all project files
COPY . /app/

# Make the build script executable
RUN chmod +x /app/build.sh

# Create volume mount points
RUN mkdir -p /app/build

# Default command
CMD ["/bin/bash", "-c", "/app/build.sh"]