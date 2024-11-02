# Stage 1: Builder
FROM python:3.9-slim as builder

# Human Tasks:
# 1. Ensure NVIDIA drivers are installed on host machine
# 2. Configure AWS credentials for model downloads
# 3. Verify GPU compatibility with CUDA 12.0
# 4. Set up model bucket access permissions
# 5. Configure TensorRT paths if using TensorRT optimization

# Set Python environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
# Requirement: AI/ML Infrastructure - System dependencies for ML frameworks
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cuda-toolkit-12-0 \
    libcudnn8 \
    tensorrt \
    nvidia-container-toolkit \
    libopencv-dev \
    libgomp1 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash mluser

# Create necessary directories
RUN mkdir -p /app/models /app/cache \
    && chown -R mluser:mluser /app

WORKDIR /app

# Install Python packages
# Requirement: AI Model Specifications - Deep learning frameworks installation
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    # TensorFlow with GPU support
    tensorflow-gpu==2.12.0 \
    # PyTorch for YOLO and FastAI
    torch==2.0.1 \
    torchvision==0.15.2 \
    # FastAI for high-level ML operations
    fastai==2.7.12 \
    # OpenCV for image processing
    opencv-python-headless==4.8.0.76

# Copy model files and configurations
COPY --chown=mluser:mluser ./models/ /app/models/
COPY --chown=mluser:mluser ./config/ /app/config/
COPY --chown=mluser:mluser ./health_check.py /app/

# Stage 2: Production
FROM python:3.9-slim

# Set environment variables for GPU and ML configuration
# Requirement: AI/ML Infrastructure - Environment configuration
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    WORKDIR=/app \
    MODEL_PATH=/app/models \
    CUDA_VISIBLE_DEVICES=0 \
    TF_ENABLE_GPU=1 \
    TF_CUDA_PATHS=/usr/local/cuda \
    TF_TENSORRT_PATH=/usr/lib/tensorrt \
    MODEL_SERVER_CONFIG_FILE=/app/config/models.config

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-toolkit-12-0 \
    libcudnn8 \
    tensorrt \
    nvidia-container-toolkit \
    libopencv-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash mluser

# Create necessary directories
RUN mkdir -p /app/models /app/cache /app/config \
    && chown -R mluser:mluser /app

WORKDIR /app

# Copy built artifacts from builder stage
COPY --from=builder --chown=mluser:mluser /app/models/ /app/models/
COPY --from=builder --chown=mluser:mluser /app/config/ /app/config/
COPY --from=builder --chown=mluser:mluser /app/health_check.py /app/

# Switch to non-root user
USER mluser

# Set up volumes for models and cache
VOLUME ["/app/models", "/app/cache"]

# Expose ports for TensorFlow Serving
EXPOSE 8501 8500

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python health_check.py || exit 1

# Set NVIDIA runtime
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Start TensorFlow Serving
CMD ["tensorflow_model_server", \
     "--port=8500", \
     "--rest_api_port=8501", \
     "--model_config_file=${MODEL_SERVER_CONFIG_FILE}", \
     "--enable_batching=true", \
     "--tensorflow_gpu_memory_fraction=0.8", \
     "--tensorflow_session_parallelism=4"]