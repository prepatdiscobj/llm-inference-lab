#!/bin/bash
set -e

echo "🚀 Installing system prerequisites for LLM Inference Lab..."

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
echo "📋 Detected Ubuntu version: $UBUNTU_VERSION"

# Clean up any corrupted repository files first
echo "🧹 Cleaning up any existing repository configurations..."
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /etc/apt/sources.list.d/nvidia-docker.list
sudo rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Update system packages
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install essential system packages and Python build dependencies
echo "🔧 Installing essential packages and Python build dependencies..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    make \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# Define NVIDIA installation functions BEFORE they are called
# Function for manual NVIDIA Container Toolkit installation on Ubuntu 24.04
install_nvidia_toolkit_manual_ubuntu2404() {
    echo "🔧 Manual NVIDIA Container Toolkit installation for Ubuntu 24.04..."
    
    # Use the direct repository approach for Ubuntu 24.04
    echo "📦 Using direct repository method..."
    
    # Add NVIDIA GPG key
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    # Use the generic repository that works with Ubuntu 24.04
    echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    
    # Update package list
    sudo apt update
    
    # Install NVIDIA Container Toolkit
    if sudo apt install -y nvidia-container-toolkit; then
        # Configure Docker
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        sleep 5
        
        # Test installation
        if timeout 30 docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
            echo "✅ NVIDIA Container Toolkit manually installed and working"
            return 0
        else
            echo "⚠️  NVIDIA Container Toolkit installed but test failed - may work after reboot"
            return 0
        fi
    else
        echo "❌ Failed to install NVIDIA Container Toolkit"
        return 1
    fi
}

# Function to install NVIDIA Container Toolkit for Ubuntu 24.04
install_nvidia_toolkit_ubuntu2404() {
    echo "🔧 Installing NVIDIA Container Toolkit for Ubuntu 24.04..."
    
    # Method 1: Try the simplified approach first
    echo "📦 Trying simplified installation method..."
    
    # Add NVIDIA GPG key
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    # Use Ubuntu 22.04 repository (jammy) which is compatible with 24.04
    echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/ubuntu22.04 /" | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    
    # Update and install
    if sudo apt update && sudo apt install -y nvidia-container-toolkit; then
        # Configure Docker
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        sleep 5
        
        # Test installation
        if timeout 30 docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
            echo "✅ NVIDIA Container Toolkit installed and working"
            return 0
        fi
    fi
    
    # Method 2: Manual installation if repository method fails
    echo "⚠️  Repository method failed, trying manual installation..."
    install_nvidia_toolkit_manual_ubuntu2404
}

# Function to install NVIDIA Container Toolkit (standard method for other Ubuntu versions)
install_nvidia_toolkit_standard() {
    echo "🔧 Installing NVIDIA Container Toolkit (standard method)..."
    
    # Configure the production repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    
    # Update and install
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    
    # Configure Docker
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    sleep 5
    
    # Test installation
    if timeout 30 docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
        echo "✅ NVIDIA Container Toolkit installed and working"
    else
        echo "⚠️  NVIDIA Container Toolkit installed but test failed - may work after reboot"
    fi
}

# Install pyenv
echo "🐍 Installing pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
    
    # Add pyenv to PATH and initialize
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    
    # Also add to current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    echo "✅ pyenv installed successfully"
else
    echo "✅ pyenv already installed"
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Update pyenv to get latest Python versions
echo "🔄 Updating pyenv..."
pyenv update

# Install Python 3.10 (latest stable version)
echo "🐍 Installing Python 3.10 with pyenv..."
PYTHON_VERSION="3.10.14"

if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo "📥 Installing Python $PYTHON_VERSION (this may take a few minutes)..."
    pyenv install $PYTHON_VERSION
    echo "✅ Python $PYTHON_VERSION installed successfully"
else
    echo "✅ Python $PYTHON_VERSION already installed"
fi

# Set Python 3.10 as global default
echo "🔧 Setting Python $PYTHON_VERSION as global default..."
pyenv global $PYTHON_VERSION

# Verify Python installation
echo "🧪 Verifying Python installation..."
python --version
python -m pip --version

# Install Docker Engine (NOT Docker Desktop)
echo "🐳 Installing Docker Engine..."

# Remove any existing Docker installations
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

# Start and enable Docker service
echo "🔄 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Install NVIDIA Container Toolkit for GPU support (if NVIDIA GPU detected)
if command -v nvidia-smi &> /dev/null; then
    echo "🎮 NVIDIA GPU detected, installing NVIDIA Container Toolkit..."
    
    # Ubuntu 24.04 specific installation
    if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
        install_nvidia_toolkit_ubuntu2404
    else
        install_nvidia_toolkit_standard
    fi
    
else
    echo "ℹ️  No NVIDIA GPU detected, skipping NVIDIA Container Toolkit installation"
fi

# Verify installations
echo "🧪 Verifying installations..."

# Verify Python
echo "🐍 Python verification:"
python --version
python -c "import sys; print(f'Python executable: {sys.executable}')"

# Verify Docker
echo "🐳 Docker verification:"
docker --version
docker compose version

# Test Docker without sudo
echo "🔐 Testing Docker permissions..."
if timeout 30 docker run --rm hello-world > /dev/null 2>&1; then
    echo "✅ Docker is working correctly"
else
    echo "⚠️  Docker permissions not yet active. You may need to log out and back in."
    echo "   Or run: newgrp docker"
fi

# Create shell configuration reminder
cat > ~/.pyenv_setup_complete << 'PYENV_EOF'
# pyenv configuration is complete
# Python 3.10.13 is installed and set as global default
# To use pyenv in new shells, ensure these lines are in your ~/.bashrc:
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
PYENV_EOF

echo ""
echo "🎉 System prerequisites installation complete!"
echo ""
echo "📋 What was installed:"
echo "   ✓ pyenv (Python version manager)"
echo "   ✓ Python $PYTHON_VERSION (via pyenv)"
echo "   ✓ Docker Engine (not Desktop) for optimal performance"
echo "   ✓ Docker Compose Plugin"
echo "   ✓ Essential build tools and Python dependencies"
if command -v nvidia-smi &> /dev/null; then
    if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
        echo "   ✓ NVIDIA Container Toolkit (Ubuntu 24.04 compatible version)"
    else
        echo "   ✓ NVIDIA Container Toolkit for GPU acceleration"
    fi
fi
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "   1. You may need to log out and back in for Docker group permissions"
echo "   2. pyenv configuration has been added to ~/.bashrc"
echo "   3. For new shells, run: source ~/.bashrc"
echo "   4. Current Python version: $(python --version)"
if command -v nvidia-smi &> /dev/null; then
    echo "   5. NVIDIA GPU support enabled - may require reboot for full functionality"
    if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
        echo "   6. Using Ubuntu 22.04 compatible NVIDIA packages for Ubuntu 24.04"
    fi
fi
echo ""
echo "🔄 Next step: Run ./scripts/setup_environment.sh"
