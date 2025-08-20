# Basis-Image mit CUDA Support
FROM nvidia/cuda:12.1.0-base-ubuntu22.04

# Umgebungsvariablen
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# System-Updates und Basis-Pakete
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    docker.io \
    docker-compose \
    supervisor \
    nginx \
    htop \
    nvtop \
    tmux \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Ollama Installation
RUN curl -fsSL https://ollama.com/install.sh | sh

# Docker Compose installieren (neueste Version)
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Arbeitsverzeichnis
WORKDIR /workspace

# Docker Compose Datei kopieren
COPY docker-compose.yml /workspace/docker-compose.yml

# Start-Skript kopieren
COPY start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

# Volumes für Persistenz
VOLUME ["/root/.ollama", "/workspace/data"]

# Ports
EXPOSE 3000 11434 8888

# RunPod spezifische Umgebungsvariablen
ENV PUBLIC_KEY=""
ENV JUPYTER_PASSWORD=""

# Start-Befehl
CMD ["/workspace/start.sh"]