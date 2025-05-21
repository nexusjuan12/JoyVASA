#!/bin/bash
# Update system and install basic dependencies
sudo apt update && sudo apt install -y build-essential gcc g++ make cmake python3 python3-pip python3-venv ffmpeg \
    libsndfile1 portaudio19-dev python3-dev unrar p7zip-full libgl1-mesa-glx libasound2-dev ninja git git-lfs

# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3

# Initialize Conda
eval "$(/root/miniconda3/bin/conda shell.bash hook)"
/root/miniconda3/bin/conda init bash
source ~/.bashrc

# Create and activate Conda environment
conda create -n joyvasa python=3.10 -y
source ~/miniconda3/etc/profile.d/conda.sh
conda activate joyvasa

# IMPORTANT: Check CUDA version first
nvcc --version
export CUDA_HOME=/usr/local/cuda

# Install PyTorch with CUDA 12.1 explicitly
pip install torch==2.2.2 torchvision==0.17.2 torchaudio==2.2.2 --extra-index-url https://download.pytorch.org/whl/cu121

# Install additional build tools
pip install ninja
apt install -y g++

# Clone repository and set up directories
git clone https://github.com/nexusjuan12/JoyVASA.git
cd JoyVASA
mkdir -p assets/examples/imgs
touch assets/examples/imgs/joyvasa_006.png

# Install requirements
pip install -r requirements.txt

# Install ImageMagick for image processing
apt update && apt install -y imagemagick
mkdir -p assets/examples/imgs
convert -size 512x512 xc:transparent assets/examples/imgs/joyvasa_006.png

# Build XPose dependencies - this part was failing
cd src/utils/dependencies/XPose/models/UniPose/ops

# Print Python and PyTorch environment info for debugging
python -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('CUDA version:', torch.version.cuda)"

# Build with explicit CUDA paths if needed
python setup.py build install

# Return to JoyVASA root
cd -

echo "Installation completed successfully!"
