# FINALE FUNKTIONIERENDE VERSION - Ollama mit Gradio UI
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
    nano \
    htop \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Python Pakete
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir \
        jupyterlab \
        gradio \
        requests \
        uvicorn \
        fastapi

# Ollama Installation
RUN curl -fsSL https://ollama.com/install.sh | sh

# Arbeitsverzeichnis
WORKDIR /workspace

# Gradio Web UI für Ollama erstellen
RUN cat > /workspace/ollama_ui.py << 'EOF'
import gradio as gr
import requests
import json
import time

def chat_with_ollama(message, model="llama3.2:1b", history=[]):
    """Chat with Ollama API"""
    try:
        # API Call zu Ollama
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": model,
                "prompt": message,
                "stream": False
            },
            timeout=120
        )
        
        if response.status_code == 200:
            result = response.json()
            answer = result.get("response", "No response")
            history.append([message, answer])
            return history, history
        else:
            history.append([message, f"Error: {response.status_code}"])
            return history, history
    except requests.exceptions.Timeout:
        history.append([message, "Timeout - Model is processing..."])
        return history, history
    except Exception as e:
        history.append([message, f"Error: {str(e)}"])
        return history, history

def list_models():
    """List available Ollama models"""
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get("models", [])
            return [m["name"] for m in models] if models else ["llama3.2:1b"]
        return ["llama3.2:1b"]
    except:
        return ["llama3.2:1b"]

def pull_model(model_name, progress=gr.Progress()):
    """Pull a new model"""
    try:
        progress(0, desc=f"Pulling {model_name}...")
        response = requests.post(
            "http://localhost:11434/api/pull",
            json={"name": model_name},
            stream=True
        )
        
        for line in response.iter_lines():
            if line:
                try:
                    data = json.loads(line)
                    if "status" in data:
                        status = data.get("status", "")
                        if "pulling" in status.lower():
                            progress(0.5, desc=status)
                        elif "verifying" in status.lower():
                            progress(0.8, desc=status)
                except:
                    pass
        
        progress(1.0, desc="Model loaded!")
        time.sleep(1)
        return f"✅ Model {model_name} loaded successfully!", list_models()
    except Exception as e:
        return f"❌ Error loading model: {str(e)}", list_models()

# Gradio Interface
with gr.Blocks(title="Ollama Chat", theme=gr.themes.Soft()) as demo:
    gr.Markdown(
        """
        # 🦙 Ollama Chat Interface
        ### Chat with your local LLMs via Ollama
        """
    )
    
    with gr.Row():
        with gr.Column(scale=1):
            model_dropdown = gr.Dropdown(
                choices=list_models(),
                value="llama3.2:1b",
                label="Select Model",
                interactive=True
            )
            refresh_btn = gr.Button("🔄 Refresh Models", size="sm")
            
            gr.Markdown("### Add New Model")
            new_model_input = gr.Textbox(
                label="Model Name",
                placeholder="e.g., mistral:7b, llama3.1:8b",
                lines=1
            )
            pull_btn = gr.Button("📥 Pull Model", variant="primary")
            model_status = gr.Textbox(label="Status", lines=2)
        
        with gr.Column(scale=3):
            chatbot = gr.Chatbot(height=500, elem_id="chatbot")
            with gr.Row():
                msg = gr.Textbox(
                    label="Message",
                    placeholder="Type your message here and press Enter...",
                    lines=2,
                    scale=4
                )
                send_btn = gr.Button("Send", variant="primary", scale=1)
            clear = gr.Button("🗑️ Clear Chat")
    
    state = gr.State([])
    
    # Chat functions
    def respond(message, model, history):
        return chat_with_ollama(message, model, history)
    
    msg.submit(respond, [msg, model_dropdown, state], [chatbot, state]).then(
        lambda: "", None, msg
    )
    send_btn.click(respond, [msg, model_dropdown, state], [chatbot, state]).then(
        lambda: "", None, msg
    )
    clear.click(lambda: ([], []), None, [chatbot, state])
    
    # Model management
    def update_models():
        models = list_models()
        return gr.Dropdown(choices=models, value=models[0] if models else "llama3.2:1b")
    
    refresh_btn.click(update_models, None, model_dropdown)
    pull_btn.click(
        pull_model, 
        inputs=[new_model_input], 
        outputs=[model_status, model_dropdown]
    ).then(lambda: "", None, new_model_input)
    
    # Auto-refresh models on load
    demo.load(update_models, None, model_dropdown)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=3000, share=False)
EOF

# Start-Skript erstellen
RUN cat > /workspace/start.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting RunPod Ollama Environment..."
echo "========================================="

# Ollama starten
echo "🤖 Starting Ollama service..."
ollama serve &
OLLAMA_PID=$!

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
    echo "Checking Ollama process..."
    ps aux | grep ollama
    exit 1
fi

# Standard-Modelle laden
if [ "$DOWNLOAD_DEFAULT_MODELS" = "true" ]; then
    echo "📥 Pulling default model (llama3.2:1b)..."
    ollama pull llama3.2:1b
    echo "✅ Default model loaded!"
fi

# Custom Models laden
if [ ! -z "$OLLAMA_MODELS" ]; then
    echo "📥 Pulling custom models: $OLLAMA_MODELS"
    IFS=',' read -ra MODELS <<< "$OLLAMA_MODELS"
    for model in "${MODELS[@]}"; do
        model=$(echo "$model" | xargs)
        echo "   Pulling $model..."
        ollama pull "$model" || echo "   Failed to pull $model"
    done
fi

# Liste verfügbare Modelle
echo "📋 Available models:"
ollama list

# Gradio UI starten
echo "🌐 Starting Web UI on port 3000..."
python3 /workspace/ollama_ui.py &
UI_PID=$!

# Jupyter Lab (optional)
if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "📊 Starting Jupyter Lab on port 8888..."
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
        --NotebookApp.token='' --NotebookApp.password="${JUPYTER_PASSWORD:-}" \
        --NotebookApp.allow_origin='*' \
        --NotebookApp.allow_remote_access=True &
    JUPYTER_PID=$!
fi

# Warte kurz
sleep 3

echo ""
echo "✨ ========================================="
echo "✨ Setup complete!"
echo "✨ ========================================="
echo ""
echo "📍 Access points:"
echo "   🌐 Web UI: http://localhost:3000"
echo "   🔌 Ollama API: http://localhost:11434"
if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "   📓 Jupyter Lab: http://localhost:8888"
fi
echo ""
echo "💡 Tips:"
echo "   - Use the Web UI to chat with models"
echo "   - Pull new models directly in the UI"
echo "   - API endpoint: http://localhost:11434/api/generate"
echo ""
echo "📝 To test from terminal:"
echo "   curl http://localhost:11434/api/tags"
echo ""

# Container am Leben halten und auf Prozesse warten
wait $OLLAMA_PID $UI_PID $JUPYTER_PID
EOF

RUN chmod +x /workspace/start.sh

# Einfaches Test-Skript
RUN cat > /workspace/test.sh << 'EOF'
#!/bin/bash
echo "Testing Ollama..."
curl -s http://localhost:11434/api/tags | python3 -m json.tool
echo ""
echo "Testing model generation..."
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3.2:1b",
  "prompt": "Hello, how are you?",
  "stream": false
}' | python3 -m json.tool
EOF

RUN chmod +x /workspace/test.sh

# Supervisor Konfiguration
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
priority=1
EOF

# Volumes für Persistenz
VOLUME ["/root/.ollama", "/workspace/data"]

# Ports
EXPOSE 3000 11434 8888

# Umgebungsvariablen
ENV DOWNLOAD_DEFAULT_MODELS=true \
    OLLAMA_MODELS="" \
    ENABLE_JUPYTER=false \
    JUPYTER_PASSWORD="" \
    OLLAMA_HOST=0.0.0.0

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11434/api/tags || exit 1

# Start mit Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
