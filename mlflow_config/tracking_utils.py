import mlflow
import mlflow.pytorch
import torch
import psutil
import GPUtil
from typing import Dict, Any
import time

class LLMExperimentTracker:
    def __init__(self, tracking_uri: str, experiment_name: str):
        mlflow.set_tracking_uri(tracking_uri)
        mlflow.set_experiment(experiment_name)
        
    def start_run(self, run_name: str = None):
        return mlflow.start_run(run_name=run_name)
    
    def log_system_metrics(self):
        """Log system performance metrics"""
        mlflow.log_metric("cpu_percent", psutil.cpu_percent())
        mlflow.log_metric("memory_percent", psutil.virtual_memory().percent)
        
        if torch.cuda.is_available():
            gpus = GPUtil.getGPUs()
            for i, gpu in enumerate(gpus):
                mlflow.log_metric(f"gpu_{i}_utilization", gpu.load * 100)
                mlflow.log_metric(f"gpu_{i}_memory_percent", gpu.memoryUtil * 100)
    
    def log_inference_metrics(self, metrics: Dict[str, Any]):
        for key, value in metrics.items():
            mlflow.log_metric(key, value)
    
    def log_model_info(self, model_name: str, model_params: Dict[str, Any]):
        mlflow.log_param("model_name", model_name)
        for key, value in model_params.items():
            mlflow.log_param(key, value)
