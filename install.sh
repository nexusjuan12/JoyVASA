sudo apt update && sudo apt install -y build-essential gcc g++ make cmake python3 python3-pip python3-venv ffmpeg \
    libsndfile1 portaudio19-dev python3-dev unrar p7zip-full libgl1-mesa-glx libasound2-dev ninja git git-lfs

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

# Clone repository and install dependencies
sudo apt update
sudo apt install -y nvidia-cuda-toolkit

git clone https://github.com/nexusjuan12/JoyVASA.git
cd JoyVASA
mkdir -p assets/examples/imgs
touch assets/examples/imgs/joyvasa_006.png
pip install -r requirements.txt

# Build XPose dependencies
cd src/utils/dependencies/XPose/models/UniPose/ops
pip install torch torchvision torchaudio  # Ensure torch dependencies are installed
python setup.py build install
cd -  # Return to JoyVASA root

apt update && apt install -y imagemagick
mkdir -p assets/examples/imgs
convert -size 512x512 xc:transparent assets/examples/imgs/joyvasa_006.png


