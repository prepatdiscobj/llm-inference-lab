#!/bin/bash
set -e

echo "🔧 Setting up LLM Inference Lab environment..."

# Ensure pyenv is available in current session
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Check if Python 3.10 is available via pyenv
if ! python --version | grep -q "3.10"; then
    echo "❌ Python 3.10 not found. Please run ./scripts/install_system_prerequisites.sh first"
    exit 1
fi

echo "✅ Python $(python --version) is available"

# Check if Docker is installed and accessible
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please run ./scripts/install_system_prerequisites.sh first"
    exit 1
fi

# Check if user can run Docker without sudo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker permissions not set up correctly."
    echo "   Please run: newgrp docker"
    echo "   Or log out and back in, then try again."
    exit 1
fi

echo "✅ Docker is available and accessible"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "🐍 Creating virtual environment with pyenv Python..."
    python -m venv .venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source .venv/bin/activate

# Verify we're using the virtual environment
echo "🧪 Virtual environment verification:"
echo "   Python: $(which python)"
echo "   Version: $(python --version)"

# Upgrade pip
echo "⬆️  Upgrading pip..."
python -m pip install --upgrade pip setuptools wheel

# Install requirements
echo "📦 Installing Python dependencies..."
python -m pip install -r requirements.txt

# Install PyTorch with CUDA support
echo "🔥 Installing PyTorch with CUDA support..."
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129

# Verify installations
echo "🧪 Verifying installations..."

# Test PyTorch
python -c "
import torch
print(f'✅ PyTorch {torch.__version__} installed')
print(f'✅ CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'✅ CUDA version: {torch.version.cuda}')
    print(f'✅ GPU count: {torch.cuda.device_count()}')
"

# Test MLflow
python -c "
import mlflow
print(f'✅ MLflow {mlflow.__version__} installed')
"

# Test other key dependencies
python -c "
import transformers, accelerate, psutil
print('✅ All key dependencies installed successfully')
"

# Create enhanced activation script
cat > activate_env.sh << 'ACTIVATE_EOF'
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
ACTIVATE_EOF

chmod +x activate_env.sh

echo ""
echo "🎉 Environment setup complete!"
echo ""
echo "📋 What's ready:"
echo "   ✓ Virtual environment in .venv/ using pyenv Python"
echo "   ✓ PyTorch with CUDA support"
echo "   ✓ MLflow and all dependencies"
echo "   ✓ Docker Engine ready for MLflow services"
echo ""
echo "🚀 Next steps:"
echo "   1. Activate environment: source .venv/bin/activate (or ./activate_env.sh)"
echo "   2. Start MLflow: ./scripts/setup_mlflow.sh"
echo "   3. Run experiments: cd experiments/mlflow_experiments && python gpu_benchmark.py"
