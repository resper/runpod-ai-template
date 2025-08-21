FROM nvidia/cuda:12.2.0-base-ubuntu22.04

# --- System und Tools ---
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl git ca-certificates sudo python3-pip \
    && rm -rf /var/lib/apt/lists/*

# --- Ollama installieren ---
RUN curl -fsSL https://ollama.com/install.sh | bash

# --- Open WebUI installieren ---
RUN git clone --depth=1 https://github.com/open-webui/open-webui.git /webui \
    && cd /webui && pip3 install --upgrade pip && pip3 install -r requirements.txt

# --- Ports und Entrypoint ---
EXPOSE 11434 8080

# Starte Ollama + WebUI in einem Prozess (mit Supervisor)
RUN apt-get update && apt-get install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]