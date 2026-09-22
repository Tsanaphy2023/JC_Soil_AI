#!/bin/bash
# ==============================================================================
# Fast Launcher for Ollama + Local Video AI Generation
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$HOME/ai_video_env"

if [ ! -d "$ENV_PATH" ]; then
  echo "❌ Error: Python virtual environment not found at $ENV_PATH"
  exit 1
fi

source "$ENV_PATH/bin/activate"
python3 "$SCRIPT_DIR/ollama_video_generator.py" "$@"
