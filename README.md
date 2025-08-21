# RunPod Ollama + Open WebUI Template

Dieses Template deployt Ollama + Open WebUI in einem Container, optimiert für Nvidia A40 (48GB VRAM), 50GB RAM, 9 vCPU.

## Features

- Ollama LLM-Server (`ollama serve`)
- Open WebUI (https://github.com/open-webui/open-webui)
- Keine lokalen Setups nötig, alles via GitHub Actions
- Ein Container, kein Docker-in-Docker, kein docker-compose

## Quickstart

1. **Forke dieses Repo oder erstelle die Dateien über GitHub**
2. **Passe ggf. das Dockerfile an (z.B. gewünschte ollama-Version oder andere WebUI)**
3. **Push auf main** → Das Dockerimage wird automatisch auf  
   `ghcr.io/<dein-github-user>/runpod-ai-template:latest` gebaut und veröffentlicht.

## RunPod Deployment

1. Wähle als Image:  
   `ghcr.io/<dein-github-user>/runpod-ai-template:latest`
2. Setze als Hardware:  
   - Nvidia A40, 48GB VRAM
   - min. 50GB RAM
   - min. 9 vCPU
3. Setze die Ports:  
   - 11434 (Ollama API)
   - 8080 (WebUI)
4. **Kein lokales Setup nötig!**  
   Alles läuft direkt im Container.

## Zugang

- Open WebUI: `http://<endpoint>:8080`
- Ollama API: `http://<endpoint>:11434`

## Anpassungen

- Für andere WebUIs: Passe das Dockerfile und supervisor config an.