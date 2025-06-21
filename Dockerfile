FROM rockylinux:10

# Install required dependencies
RUN dnf -y install \
    epel-release \
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
COPY kickstarts/ /app/kickstarts
COPY iso-patch/ /app/iso-patch
COPY .env /app/.env
COPY packages-to-add.txt /app/packages-to-add.txt
COPY build.sh /app/build.sh

# Make the build script executable
RUN chmod +x /app/build.sh

# Create volume mount points
RUN mkdir -p /app/build

# Default command
CMD ["/bin/bash", "-c", "/app/build.sh"]