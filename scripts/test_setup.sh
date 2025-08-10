#!/bin/bash
set -e

echo "🧪 Testing complete setup..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Running setup..."
    ./scripts/setup_environment.sh
fi

# Activate virtual environment
source .venv/bin/activate

# Verify Python environment
echo "🐍 Python version: $(python --version)"
echo "📍 Python path: $(which python)"
echo "🏠 Virtual env: $VIRTUAL_ENV"

# Test PyTorch installation
echo "🔥 Testing PyTorch installation..."
python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}: {torch.cuda.get_device_name(i)}')
else:
    print('Running in CPU mode')
"

# Test MLflow installation
echo "📊 Testing MLflow installation..."
python -c "
import mlflow
print(f'MLflow version: {mlflow.__version__}')
"

# Check if MLflow services are already running
echo "🔍 Checking MLflow services status..."
cd mlflow

# Determine docker compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose not found"
    exit 1
fi

# Check if services are already running
SERVICES_RUNNING=false
if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
    echo "✅ MLflow services are already running"
    SERVICES_RUNNING=true
else
    echo "🚀 Starting MLflow services..."
    $DOCKER_COMPOSE_CMD up -d
    
    # Wait for services to start
    echo "⏳ Waiting for services to start..."
    sleep 30
fi

cd ..

# Wait for MLflow to be fully ready
echo "⏳ Waiting for MLflow to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "✅ MLflow is ready!"
        break
    fi
    echo "Waiting for MLflow... (attempt $attempt/$max_attempts)"
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ MLflow failed to start properly"
    echo "Check logs with: cd mlflow && $DOCKER_COMPOSE_CMD logs"
    exit 1
fi

# Test MLflow connection
echo "🔗 Testing MLflow connection..."
python -c "
import mlflow
import requests

try:
    mlflow.set_tracking_uri('http://localhost:5000')
    # Try to create a test experiment (only if it doesn't exist)
    try:
        experiment_id = mlflow.create_experiment('test_connection')
        print('✅ MLflow connection successful')
        print(f'Test experiment created with ID: {experiment_id}')
    except mlflow.exceptions.MlflowException as e:
        if 'already exists' in str(e):
            print('✅ MLflow connection successful (test experiment already exists)')
        else:
            raise e
except Exception as e:
    print(f'❌ MLflow connection failed: {e}')
    raise
"

# Setup MinIO bucket (handle existing bucket gracefully)
echo "🗄️  Setting up MinIO bucket..."
cd mlflow

# Check if bucket already exists and create only if needed
python -c "
import subprocess
import sys
import os

docker_compose_cmd = os.environ.get('DOCKER_COMPOSE_CMD', '$DOCKER_COMPOSE_CMD').split()

try:
    # Check if bucket exists
    result = subprocess.run(
        docker_compose_cmd + ['-f', 'docker-compose.yml', 'exec', '-T', 'minio', 'mc', 'ls', 'local/'],
        capture_output=True, text=True, timeout=30
    )
    
    if 'mlflow-artifacts' in result.stdout:
        print('✅ MinIO bucket already exists')
    else:
        print('📦 Creating MinIO bucket...')
        # Set up alias first
        subprocess.run(
            docker_compose_cmd + ['-f', 'docker-compose.yml', 'exec', '-T', 'minio', 'mc', 'alias', 'set', 
            'local', 'http://localhost:9000', 'mlflow', 'mlflow_password'],
            check=True, timeout=30
        )
        
        # Create bucket
        subprocess.run(
            docker_compose_cmd + ['-f', 'docker-compose.yml', 'exec', '-T', 'minio', 'mc', 'mb', 'local/mlflow-artifacts'],
            check=True, timeout=30
        )
        print('✅ MinIO bucket created successfully')
        
except subprocess.CalledProcessError as e:
    if 'already exists' in e.stderr or 'Your previous request' in e.stderr:
        print('✅ MinIO bucket already exists (from previous run)')
    else:
        print(f'⚠️  MinIO setup warning: {e.stderr}')
        print('Bucket may already exist or be accessible')
except Exception as e:
    print(f'⚠️  MinIO setup warning: {e}')
    print('Continuing with test...')
" DOCKER_COMPOSE_CMD="$DOCKER_COMPOSE_CMD"

cd ..

# Run test experiment
echo "🧪 Running test experiment..."
cd experiments/mlflow_experiments
python gpu_benchmark.py

echo ""
echo "🎉 All tests passed!"
echo "📊 MLflow UI: http://localhost:5000"
echo "🗄️  MinIO Console: http://localhost:9001"
echo "🔧 To stop services: cd mlflow && $DOCKER_COMPOSE_CMD down"
