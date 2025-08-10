#!/bin/bash
set -e

# Ensure virtual environment is activated
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
fi

echo "Setting up self-hosted MLflow..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker compose is available (try both commands)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Error: Neither 'docker-compose' nor 'docker compose' command found."
    echo "Please install Docker Compose:"
    echo "  Ubuntu: sudo apt install docker-compose-plugin"
    echo "  Or: pip install docker-compose"
    exit 1
fi

echo "Using Docker Compose command: $DOCKER_COMPOSE_CMD"

cd mlflow

# Start MLflow services
echo "Starting MLflow services..."
$DOCKER_COMPOSE_CMD up -d

echo "MLflow is starting up..."
echo "Web UI will be available at: http://localhost:5000"
echo "MinIO Console will be available at: http://localhost:9001"

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Function to check if service is ready
check_service() {
    local service_name=$1
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if $DOCKER_COMPOSE_CMD exec -T $service_name echo "Service ready" > /dev/null 2>&1; then
            echo "✓ $service_name is ready"
            return 0
        fi
        echo "Waiting for $service_name... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    echo "✗ $service_name failed to start after $max_attempts attempts"
    return 1
}

# Check if services are ready
echo "Checking service health..."
check_service "postgres" || exit 1
check_service "minio" || exit 1
check_service "mlflow" || exit 1

# Create MinIO bucket
echo "Setting up MinIO bucket..."
cd ..

python -c "
import time
import subprocess
import sys
import os

# Determine docker compose command
docker_compose_cmd = os.environ.get('DOCKER_COMPOSE_CMD', 'docker compose').split()

max_retries = 10
for i in range(max_retries):
    try:
        print(f'Attempt {i+1}/{max_retries}: Setting up MinIO alias...')
        result = subprocess.run(
            docker_compose_cmd + ['-f', 'mlflow/docker-compose.yml', 
            'exec', '-T', 'minio', 'mc', 'alias', 'set', 
            'local', 'http://localhost:9000', 'mlflow', 'mlflow_password'],
            capture_output=True, text=True, timeout=30
        )
        
        if result.returncode == 0:
            print('✓ MinIO alias set successfully')
            
            # Create bucket
            bucket_result = subprocess.run(
                docker_compose_cmd + ['-f', 'mlflow/docker-compose.yml',
                'exec', '-T', 'minio', 'mc', 'mb', 'local/mlflow-artifacts'],
                capture_output=True, text=True, timeout=30
            )
            
            if bucket_result.returncode == 0:
                print('✓ MinIO bucket created successfully!')
                break
            else:
                print(f'Bucket creation failed: {bucket_result.stderr}')
        else:
            print(f'Alias setup failed: {result.stderr}')
            
        time.sleep(5)
    except subprocess.TimeoutExpired:
        print(f'Attempt {i+1}/{max_retries} timed out, retrying...')
        time.sleep(5)
    except Exception as e:
        print(f'Attempt {i+1}/{max_retries} failed: {e}')
        time.sleep(5)
else:
    print('⚠ Failed to setup MinIO after all retries')
    print('You can manually create the bucket later via MinIO console')
" DOCKER_COMPOSE_CMD="$DOCKER_COMPOSE_CMD"

# Final health check
echo "Performing final health check..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✓ MLflow server is healthy"
else
    echo "⚠ MLflow server health check failed, but services are running"
fi

echo ""
echo "🎉 MLflow setup complete!"
echo "📊 MLflow UI: http://localhost:5000"
echo "🗄️  MinIO Console: http://localhost:9001 (mlflow/mlflow_password)"
echo ""
echo "To stop services: cd mlflow && $DOCKER_COMPOSE_CMD down"
echo "To view logs: cd mlflow && $DOCKER_COMPOSE_CMD logs -f"
