FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Coder agent
RUN curl -fsSL https://coder.com/install.sh | sh

# Create a non-root user
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER coder
WORKDIR /home/coder

# Startup script
COPY --chown=coder:coder startup.sh /home/coder/startup.sh
RUN chmod +x /home/coder/startup.sh

CMD ["/home/coder/startup.sh"]