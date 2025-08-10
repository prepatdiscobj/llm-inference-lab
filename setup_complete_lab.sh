#!/bin/bash
set -e

echo "🚀 Setting up complete LLM Inference Lab..."
echo "This will install system prerequisites, Docker, and set up the Python environment"
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "⚠️  This script is designed for Ubuntu. Proceed with caution on other distributions."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Install system prerequisites
echo "📋 Step 1: Installing system prerequisites..."
./scripts/install_system_prerequisites.sh

# Apply docker group changes
echo "🔄 Applying Docker group permissions..."
newgrp docker << 'NEWGRP_EOF'

# Step 2: Set up Python environment
echo "📋 Step 2: Setting up Python environment..."
./scripts/setup_environment.sh

# Step 3: Set up MLflow
echo "📋 Step 3: Setting up MLflow services..."
./scripts/setup_mlflow.sh

# Step 4: Run tests
echo "📋 Step 4: Running setup verification..."
./scripts/test_setup.sh

echo ""
echo "🎉 Complete LLM Inference Lab setup finished!"
echo ""
echo "🔗 Access points:"
echo "   📊 MLflow UI: http://localhost:5000"
echo "   🗄️  MinIO Console: http://localhost:9001 (mlflow/mlflow_password)"
echo ""
echo "🚀 Quick start:"
echo "   source .venv/bin/activate"
echo "   cd experiments/mlflow_experiments"
echo "   python gpu_benchmark.py"

NEWGRP_EOF
