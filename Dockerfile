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
    python3-venv \
    supervisor \
    nginx \
    htop \
    tmux \
    nano \
    openssh-server \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Python Pakete aktualisieren
RUN pip3 install --upgrade pip setuptools wheel

# Jupyter Lab installieren
RUN pip3 install --no-cache-dir jupyterlab

# Open WebUI von GitHub installieren
RUN git clone https://github.com/open-webui/open-webui.git /opt/open-webui && \
    cd /opt/open-webui && \
    pip3 install -r requirements.txt && \
    cd backend && \
    pip3 install -e .

# Ollama Installation
RUN curl -fsSL https://ollama.com/install.sh | sh

# Arbeitsverzeichnis
WORKDIR /workspace

# Start-Skript direkt im Dockerfile erstellen
RUN cat > /workspace/start.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting RunPod Ollama + Open WebUI Environment..."

# SSH Setup (falls PUBLIC_KEY gesetzt)
if [ ! -z "$PUBLIC_KEY" ]; then
    echo "📌 Setting up SSH..."
    mkdir -p ~/.ssh
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    service ssh start
fi

# Jupyter Setup (optional)
if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "📊 Starting Jupyter Lab..."
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --NotebookApp.token='' --NotebookApp.password="${JUPYTER_PASSWORD:-}" \
        --NotebookApp.allow_origin='*' \
        --NotebookApp.allow_remote_access=True &
fi

# Ollama direkt starten
echo "🤖 Starting Ollama service..."
ollama serve &

# Warte bis Ollama bereit ist
echo "⏳ Waiting for Ollama to be ready..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo "   Attempt $attempt/$max_attempts..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Ollama failed to start!"
    exit 1
fi

# Basis-Modelle herunterladen (falls gewünscht)
if [ "$DOWNLOAD_DEFAULT_MODELS" = "true" ]; then
    echo "📥 Pulling default models..."
    ollama pull llama3.2:1b || echo "Failed to pull llama3.2:1b"
    ollama pull phi3:mini || echo "Failed to pull phi3:mini"
    echo "✅ Default models loaded!"
fi

# Custom Models herunterladen
if [ ! -z "$OLLAMA_MODELS" ]; then
    echo "📥 Pulling custom models: $OLLAMA_MODELS"
    IFS=',' read -ra MODELS <<< "$OLLAMA_MODELS"
    for model in "${MODELS[@]}"; do
        model=$(echo "$model" | xargs)  # Trim whitespace
        echo "   Pulling $model..."
        ollama pull "$model" || echo "   Failed to pull $model"
    done
fi

# Open WebUI starten
echo "🌐 Starting Open WebUI..."
export OLLAMA_BASE_URL="http://localhost:11434"
export OLLAMA_API_BASE_URL="http://localhost:11434/api"
export WEBUI_AUTH="${WEBUI_AUTH:-false}"
export WEBUI_NAME="${WEBUI_NAME:-RunPod AI}"
export ENABLE_SIGNUP="${ENABLE_SIGNUP:-true}"
export DATA_DIR="/workspace/data"
export FRONTEND_BUILD_DIR="/opt/open-webui/build"

# Open WebUI Backend starten
cd /opt/open-webui/backend
python3 -m uvicorn main:app --host 0.0.0.0 --port 3000 --forwarded-allow-ips "*" &

echo "✨ Setup complete!"
echo ""
echo "📍 Access points:"
echo "   - Open WebUI: http://localhost:3000"
echo "   - Ollama API: http://localhost:11434"
if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "   - Jupyter Lab: http://localhost:8888"
fi
echo ""
echo "💡 To add models, use the Open WebUI interface or run:"
echo "   ollama pull <model-name>"
echo ""

# Container am Leben halten und Logs ausgeben
tail -f /dev/null
EOF

# Start-Skript ausführbar machen
RUN chmod +x /workspace/start.sh

# Alternative: Einfaches Start-Skript für Tests
RUN cat > /workspace/simple-start.sh << 'EOF'
#!/bin/bash
echo "🚀 Simple Start - Ollama only..."

# Ollama starten
ollama serve &
sleep 5

# Ein kleines Modell laden
ollama pull llama3.2:1b

echo "✅ Ollama ready on port 11434"
echo "📝 You can now run: ollama run llama3.2:1b"

# Am Leben halten
tail -f /dev/null
EOF

RUN chmod +x /workspace/simple-start.sh

# Supervisor Konfiguration erstellen
RUN mkdir -p /etc/supervisor/conf.d && \
    cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:startup]
command=/workspace/start.sh
autostart=true
autorestart=false
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

# Nginx Konfiguration für Proxy (optional)
RUN cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        client_max_body_size 0;
        proxy_read_timeout 86400;
    }
    
    location /ollama/ {
        proxy_pass http://localhost:11434/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Volumes für Persistenz
VOLUME ["/root/.ollama", "/workspace/data"]

# Ports
EXPOSE 3000 11434 8888 22 80

# Umgebungsvariablen Defaults
ENV ENABLE_JUPYTER=false \
    JUPYTER_PASSWORD="" \
    DOWNLOAD_DEFAULT_MODELS=true \
    OLLAMA_MODELS="" \
    WEBUI_AUTH=false \
    WEBUI_NAME="RunPod AI" \
    ENABLE_SIGNUP=true \
    PUBLIC_KEY=""

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11434/api/tags || exit 1

# Start-Befehl - direkt das Skript ausführen
CMD ["/workspace/start.sh"]
