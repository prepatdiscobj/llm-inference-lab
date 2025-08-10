# LLM Inference Lab

A comprehensive research environment for Large Language Model inference experiments with self-hosted MLflow tracking.

## Features

- **Multi-Hardware Support**: GPU, CPU, and mixed inference capabilities
- **Self-Hosted MLflow**: Complete experiment tracking with PostgreSQL backend and MinIO artifact storage
- **PyCharm Integration**: Professional IDE setup with proper project configuration
- **Docker-Based Services**: Containerized MLflow stack for easy management
- **Virtual Environment**: Isolated Python environment preventing system conflicts

## Quick Start

### 1. **Setup Environment**
```bash
# Run complete environment setup
./scripts/setup_environment.sh


### 2. **Start MLflow Services**
```bash
# Start self-hosted MLflow stack
./scripts/setup_mlflow.sh


### 3. **Run Your First Experiment**
```bash
# Ensure virtual environment is active
source .venv/bin/activate


### 4. **Open in PyCharm**
```bash
# Open project in PyCharm Professional
pycharm-professional .


## Project Structure


## Important Notes

- **Always activate virtual environment** before running Python code: `source .venv/bin/activate`
- **MLflow UI**: http://localhost:5000
- **MinIO Console**: http://localhost:9001 (mlflow/mlflow_password)
- **Virtual environment** prevents system Python conflicts
- **Docker services** can be stopped with: `cd mlflow && docker-compose down`

## Troubleshooting

### Virtual Environment Issues
```bash
# Recreate virtual environment if corrupted
rm -rf .venv
python3.10 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

