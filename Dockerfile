FROM nvidia/cuda:12.2.0-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# System-Tools & Node.js 20 (LTS)
RUN apt-get update && \
    apt-get install -y curl git ca-certificates sudo python3-pip supervisor && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Ollama installieren
RUN curl -fsSL https://ollama.com/install.sh | bash

# Open WebUI klonen & installieren
RUN git clone --depth=1 https://github.com/open-webui/open-webui.git /webui \
    && cd /webui \
    && npm ci --legacy-peer-deps \
    && npm run build

# Ports
ENV OLLAMA_HOST=0.0.0.0:11434
EXPOSE 8080 11434

# Supervisor Konfiguration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf


CMD ["/usr/bin/supervisord"]
