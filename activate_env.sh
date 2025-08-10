#!/bin/bash

# Ensure pyenv is available
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Activate virtual environment
source .venv/bin/activate

echo "🐍 Virtual environment activated!"
echo "   Python: $(which python)"
echo "   Version: $(python --version)"
echo "   Pip: $(which pip)"
echo ""
echo "🔥 PyTorch CUDA status:"
python -c "import torch; print(f'   CUDA available: {torch.cuda.is_available()}')"
echo ""
echo "🐳 Docker status:"
docker --version
echo ""
echo "💡 Available Python versions (pyenv):"
pyenv versions
