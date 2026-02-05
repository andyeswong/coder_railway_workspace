FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && \
    apt-get install -y \
    sudo \
    curl \
    git \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create coder user with proper permissions first
ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER} && \
    mkdir -p /home/${USER} && \
    chown -R ${USER}:${USER} /home/${USER}

# Pre-install Coder CLI to speed up agent startup
RUN curl -fsSL https://coder.com/install.sh | sh

# Pre-install code-server to speed up agent startup
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Run the code-server in port 13337 wihth no-auth for Coder to manage authentication
RUN mkdir -p /home/${USER}/.config/code-server && \
    echo "bind-addr: 0.0.0.0:13337" > /home/${USER}/.config/code-server/config.yaml && \
    echo "auth: none" >> /home/${USER}/.config/code-server/config.yaml && \
    chown -R ${USER}:${USER} /home/${USER}/.config


# Copy Railway config and entrypoint script
COPY railway.json /railway.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ${USER}

# set env variables for coder agent, url is http://coder:3000 by default in coder self-hosted
ENV CODER_AGENT_URL=http://coder:3000

# Execute the Coder agent init script via entrypoint
ENTRYPOINT ["/entrypoint.sh"]