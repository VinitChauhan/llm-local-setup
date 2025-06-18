# llm-local-setup

This project provides a local setup for running Large Language Models (LLMs) using Docker Compose on a Mac Intel machine. It includes the Ollama LLM server and Open WebUI for easy interaction with models like phi3:mini.

## Features
- **Ollama LLM Server**: Local LLM inference server.
- **Open WebUI**: User-friendly web interface for model interaction.
- **Persistent Storage**: Model and data volumes for persistence.
- **Environment Variables**: Uses a `.env` file for sensitive configuration like `WEBUI_SECRET_KEY`.

## Getting Started

### Prerequisites
- Docker and Docker Compose installed on your Mac (Intel).

### Setup Steps
1. **Clone this repository** and navigate to the project directory.
2. **Create a `.env` file** in the `models` directory and set your `WEBUI_SECRET_KEY`:
   ```sh
   python3 -c "import secrets; print(secrets.token_urlsafe(32))"
   ```
   Copy the output and set it in `.env`:
   ```env
   WEBUI_SECRET_KEY=your_generated_secret_key
   ```
3. **Start the services:**
   ```sh
   docker compose up -d
   ```
4. **Access the Web UI:**
   - Open [http://localhost:3000](http://localhost:3000) in your browser.

## Model Usage
- By default, Ollama starts without a specific model loaded. To pull and run `phi3:mini`, use:
  ```sh
  docker exec -it phi3-ollama ollama pull phi3:mini
  ```
- You can then use the WebUI or API to interact with the model.

## File Structure
- `docker-compose.yml` — Docker Compose configuration for all services.
- `.env` — Environment variables (not committed to version control).
- `models/` — Directory for model files and persistent data.

## Troubleshooting
- If you see errors about arguments in the Ollama logs, ensure the `command:` line is removed from the `docker-compose.yml` for the Ollama service.
- For any issues, check the container logs:
  ```sh
  docker compose logs ollama
  docker compose logs ollama-webui
  ```

## Credits
- [Ollama](https://ollama.com/)
- [Open WebUI](https://github.com/open-webui/open-webui)

---
Feel free to customize this setup for your own LLM workflows!