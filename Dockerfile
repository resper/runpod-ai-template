FROM nvidia/cuda:12.2.0-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# System- und Entwickler-Tools installieren
RUN apt-get update && \
    apt-get install -y curl git ca-certificates sudo python3.11 python3.11-venv python3.11-distutils python3-pip supervisor && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Ollama installieren
RUN curl -fsSL https://ollama.com/install.sh | bash

# Open WebUI (Python Backend) installieren
RUN pip3 install --upgrade pip && \
    pip3 install open-webui

# Supervisor-Konfiguration hinzufügen
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Ports freigeben
EXPOSE 8080 11434

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]