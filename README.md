# RunPod Ollama + Open WebUI Template

## 🎯 Features

- **Ollama** LLM Backend mit GPU-Beschleunigung
- **Open WebUI** als moderne Chat-Oberfläche
- Optimiert für **Nvidia A40 48GB VRAM**
- Automatische Model-Downloads
- Persistent Storage für Modelle und Chats
- Optional: Jupyter Lab Integration

## 🚀 Quick Start auf RunPod

### 1. Template erstellen

1. Gehen Sie zu [RunPod Templates](https://www.runpod.io/console/templates)
2. Klicken Sie auf "New Template"
3. Füllen Sie aus:
   - **Container Image**: `IhrDockerHubUsername/runpod-ollama-webui:latest`
   - **Container Disk**: 50 GB
   - **Expose HTTP Ports**: 3000,11434,8888
   - **Environment Variables**:
     ```
     PUBLIC_KEY=ihr-ssh-public-key (optional)
     JUPYTER_PASSWORD=ihr-jupyter-passwort (optional)
     ```

### 2. Pod deployen

1. Gehen Sie zu "Pods" → "Deploy"
2. Wählen Sie GPU: **RTX A40** (oder A100/H100)
3. Wählen Sie Ihr Template
4. Klicken Sie "Deploy"

### 3. Zugriff

Nach dem Start (ca. 2-3 Minuten):

- **Open WebUI**: `https://[pod-id]-3000.proxy.runpod.net`
- **Ollama API**: `https://[pod-id]-11434.proxy.runpod.net`
- **Jupyter Lab**: `https://[pod-id]-8888.proxy.runpod.net` (falls aktiviert)

## 📦 Verfügbare Modelle

Standardmäßig werden folgende Modelle geladen:
- `llama3.2:1b` - Schnelles, kompaktes Modell
- `phi3:mini` - Microsoft's effizientes Modell
- `mistral:7b` - Starkes Open-Source Modell

Weitere Modelle können über die WebUI oder API geladen werden.

## 🔧 Konfiguration

### Modelle hinzufügen

In der Open WebUI:
1. Klicken Sie auf das Zahnrad-Symbol
2. Gehen Sie zu "Models"
3. Geben Sie den Modellnamen ein (z.B. `llama3.1:70b`)
4. Klicken Sie "Pull"

### GPU-Optimierung

Für A40 48GB empfohlene Einstellungen:
- Max. 2-3 große Modelle (70B) gleichzeitig
- Oder 5-6 mittlere Modelle (7B-13B)
- Batch-Size: 512
- Context Length: 4096-8192

## 🛠️ Troubleshooting

### Container startet nicht
- Prüfen Sie die Logs in RunPod Console
- Stellen Sie sicher, dass genug Disk Space vorhanden ist

### Modelle laden nicht
- Prüfen Sie die Internetverbindung des Pods
- Erhöhen Sie den Container Disk Space

### Performance-Probleme
- Reduzieren Sie die Anzahl geladener Modelle
- Verwenden Sie quantisierte Modellversionen (z.B. `:Q4_K_M`)

## 📊 Ressourcenverbrauch

| Modellgröße | VRAM | RAM | Disk |
|-------------|------|-----|------|
| 7B | ~6GB | 8GB | 4GB |
| 13B | ~12GB | 16GB | 8GB |
| 70B | ~40GB | 32GB | 40GB |

## 🔐 Sicherheit

1. Ändern Sie `WEBUI_SECRET_KEY` in docker-compose.yml
2. Aktivieren Sie Authentication in Open WebUI nach dem ersten Login
3. Nutzen Sie SSH-Keys statt Passwörter
4. Regelmäßige Updates der Container-Images

## 📚 Links

- [Ollama Dokumentation](https://ollama.com/library)
- [Open WebUI Dokumentation](https://docs.openwebui.com/)
- [RunPod Dokumentation](https://docs.runpod.io/)

## 📝 Lizenz

MIT License - Frei verwendbar für kommerzielle und private Projekte.
