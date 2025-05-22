#!/bin/bash
# JoyVASA Installation Script - Fixed for CUDA issues

set -e  # Exit on any error

echo "=== JoyVASA Installation Script ==="

# Update system and install basic dependencies
echo "Installing system dependencies..."
sudo apt update && sudo apt install -y build-essential gcc g++ make cmake python3 python3-pip python3-venv ffmpeg \
    libsndfile1 portaudio19-dev python3-dev unrar p7zip-full libgl1-mesa-glx libasound2-dev ninja-build git git-lfs

# Check if CUDA is properly installed
echo "Checking CUDA installation..."
if ! command -v nvcc &> /dev/null; then
    echo "CUDA compiler (nvcc) not found. Installing CUDA Toolkit..."
    
    # Install CUDA 12.1 specifically
    wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-12-1
    
    # Set up CUDA environment
    export CUDA_HOME=/usr/local/cuda-12.1
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
    
    # Add to bashrc for persistence
    echo 'export CUDA_HOME=/usr/local/cuda-12.1' >> ~/.bashrc
    echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
else
    echo "CUDA compiler found at: $(which nvcc)"
    nvcc --version
    
    # Set CUDA_HOME to existing installation
    CUDA_PATH=$(dirname $(dirname $(which nvcc)))
    export CUDA_HOME=$CUDA_PATH
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
fi

# Install Miniconda if not present
if ! command -v conda &> /dev/null; then
    echo "Installing Miniconda..."
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3
    rm Miniconda3-latest-Linux-x86_64.sh
    
    # Initialize Conda
    eval "$(~/miniconda3/bin/conda shell.bash hook)"
    ~/miniconda3/bin/conda init bash
    source ~/.bashrc
fi

# Source conda
source ~/miniconda3/etc/profile.d/conda.sh

# Create and activate Conda environment
echo "Creating conda environment..."
conda create -n joyvasa python=3.10 -y
conda activate joyvasa

# Verify CUDA setup
echo "=== CUDA Environment Check ==="
echo "CUDA_HOME: $CUDA_HOME"
echo "nvcc location: $(which nvcc)"
echo "nvcc version:"
nvcc --version

# Install PyTorch with matching CUDA version
echo "Installing PyTorch with CUDA 12.1..."
pip install torch==2.2.2 torchvision==0.17.2 torchaudio==2.2.2 --index-url https://download.pytorch.org/whl/cu121

# Verify PyTorch CUDA installation
echo "=== PyTorch CUDA Verification ==="
python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'CUDA version: {torch.version.cuda}')
if torch.cuda.is_available():
    print(f'GPU device: {torch.cuda.get_device_name(0)}')
    print(f'GPU count: {torch.cuda.device_count()}')
"

# Clone repository and set up directories
echo "Cloning JoyVASA repository..."
if [ ! -d "JoyVASA" ]; then
    git clone https://github.com/nexusjuan12/JoyVASA.git
fi
cd JoyVASA

# Create necessary directories
mkdir -p assets/examples/imgs assets/examples/audios

# Install requirements
echo "Installing Python requirements..."
pip install -r requirements.txt

# Install ImageMagick for image processing
echo "Installing ImageMagick..."
sudo apt update && sudo apt install -y imagemagick

# Create placeholder image
convert -size 512x512 xc:transparent assets/examples/imgs/joyvasa_006.png

# Build XPose dependencies with proper CUDA setup
echo "Building XPose MultiScaleDeformableAttention..."
cd src/utils/dependencies/XPose/models/UniPose/ops

# Verify environment before building
echo "Pre-build environment check:"
echo "Current directory: $(pwd)"
echo "CUDA_HOME: $CUDA_HOME"
echo "nvcc path: $(which nvcc)"
python -c "import torch; print(f'PyTorch CUDA: {torch.version.cuda}')"

# Set additional environment variables for the build
export TORCH_CUDA_ARCH_LIST="6.0;6.1;7.0;7.5;8.0;8.6"
export FORCE_CUDA=1

# Build with verbose output for debugging
echo "Building MultiScaleDeformableAttention..."
python setup.py build_ext --inplace
python setup.py build install

# Return to JoyVASA root
cd ../../../../../../

echo "=== Installation completed successfully! ==="
echo ""
echo "To activate the environment in future sessions:"
echo "  conda activate joyvasa"
echo ""
echo "To test the installation:"
echo "  python -c \"import torch; print('CUDA available:', torch.cuda.is_available())\""
echo ""
echo "To run JoyVASA:"
echo "  python inference.py -r assets/examples/imgs/your_image.png -a assets/examples/audios/your_audio.wav --animation_mode human --cfg_scale 2.0"
