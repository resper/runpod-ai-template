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
if [ ! -z "$JUPYTER_PASSWORD" ]; then
    echo "📊 Starting Jupyter Lab..."
    pip install jupyterlab
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --NotebookApp.token='' --NotebookApp.password="$JUPYTER_PASSWORD" &
fi

# Ollama direkt starten (ohne Docker-in-Docker)
echo "🤖 Starting Ollama service..."
ollama serve &

# Warte bis Ollama bereit ist
echo "⏳ Waiting for Ollama to be ready..."
while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 2
done

echo "✅ Ollama is ready!"

# Basis-Modelle herunterladen
echo "📥 Pulling default models..."
ollama pull llama3.2:1b
ollama pull phi3:mini
ollama pull mistral:7b

# Open WebUI starten (vereinfachte Version ohne Docker Compose)
echo "🌐 Starting Open WebUI..."

# Open WebUI als Python-Anwendung installieren und starten
pip install open-webui
open-webui serve --host 0.0.0.0 --port 3000 &

echo "✨ Setup complete!"
echo "📍 Access points:"
echo "   - Open WebUI: http://localhost:3000"
echo "   - Ollama API: http://localhost:11434"
if [ ! -z "$JUPYTER_PASSWORD" ]; then
    echo "   - Jupyter Lab: http://localhost:8888"
fi

# Log-Ausgabe
tail -f /dev/null