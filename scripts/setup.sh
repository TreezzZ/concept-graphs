TZ="America/New_York"
INSTALL_ROOT="/CG_INSTALL_ROOT"
CUDA_VERSION="11.8"
DOWNLOAD_CACHE_ROOT="/shuzhao/Projects/TaskOrientedLMM/Dataset/ConceptGraph"

export CG_FOLDER=`pwd`

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

mkdir -p $INSTALL_ROOT
cd $INSTALL_ROOT

echo "Installing packages"
conda install -y pytorch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 pytorch-cuda=11.8 -c pytorch -c nvidia
pip install tyro open_clip_torch wandb h5py openai hydra-core distinctipy imageio==2.19.3 imageio-ffmpeg==0.4.7 faiss-gpu
conda install -y https://anaconda.org/pytorch3d/pytorch3d/0.7.4/download/linux-64/pytorch3d-0.7.4-py310_cu118_pyt201.tar.bz2
apt-get install -y libosmesa6-dev libglu1-mesa-dev libxml2-dev software-properties-common
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt install -y g++-11
cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.32 /root/anaconda/envs/cg/lib/libstdc++.so.6 # replace libstdc++

echo "Installing chamferdist"
git clone https://github.com/krrish94/chamferdist.git
cd chamferdist
pip install .
cd $INSTALL_ROOT

echo "Installing gradslam"
git clone https://github.com/gradslam/gradslam.git
cd gradslam
git checkout conceptfusion
pip install .
cd $INSTALL_ROOT

echo "Installing GroundedSAM"
git clone https://github.com/IDEA-Research/Grounded-Segment-Anything.git
cd Grounded-Segment-Anything
rm GroundingDINO/pyproject.toml # Do not use the default dependencies
#conda install -y -c conda-forge cudatoolkit-dev
export AM_I_DOCKER=False
export BUILD_WITH_CUDA=True
export CUDA_HOME=/usr/local/cuda-${CUDA_VERSION}
python -m pip install -e segment_anything
python -m pip install -e GroundingDINO
pip install --upgrade diffusers[torch]
git clone https://github.com/xinyu1205/recognize-anything.git
pip install -r ./recognize-anything/requirements.txt
pip install -e ./recognize-anything/
git submodule init
git submodule update
if [ -d "$DOWNLOAD_CACHE_ROOT" ]; then
  cp $DOWNLOAD_CACHE_ROOT/sam_vit_h_4b8939.pth ./
  cp $DOWNLOAD_CACHE_ROOT/groundingdino_swint_ogc.pth ./
  cp $DOWNLOAD_CACHE_ROOT/ram_swin_large_14m.pth ./
  cp $DOWNLOAD_CACHE_ROOT/tag2text_swin_14m.pth ./
else
  wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
  wget https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
  wget https://huggingface.co/spaces/xinyu1205/Tag2Text/resolve/main/ram_swin_large_14m.pth
  wget https://huggingface.co/spaces/xinyu1205/Tag2Text/resolve/main/tag2text_swin_14m.pth
fi
export GSA_PATH=`pwd`
cd $INSTALL_ROOT

echo "Installing LLaVA"
git clone https://github.com/3d-language-model/llava-mod.git
cd llava-mod
pip install -e .
export LLAVA_PYTHON_PATH=`pwd`
cd $INSTALL_ROOT

echo "Downloading LLaVA weights"
if [ -d "$DOWNLOAD_CACHE_ROOT" ]; then
  cp -r $DOWNLOAD_CACHE_ROOT/llava_weights ./
else
  python $CG_FOLDER/scripts/download_llava_weights.py
fi
cd llava_weights
export LLAVA_MODEL_PATH=`pwd`
cd $INSTALL_ROOT

echo "Installing conceptgraph"
cd $CG_FOLDER
export REPLICA_CONFIG_PATH=${CG_FOLDER}/conceptgraph/dataset/dataconfigs/replica/replica.yaml
pip install -e .
cd $INSTALL_ROOT

echo "Download replica dataset"
if [ -d "$DOWNLOAD_CACHE_ROOT" ]; then
  cp $DOWNLOAD_CACHE_ROOT/Replica.zip ./
else
  wget https://cvg-data.inf.ethz.ch/nice-slam/data/Replica.zip
fi
unzip Replica.zip
cd Replica
export REPLICA_ROOT=`pwd`
cd $INSTALL_ROOT

echo "Build Open3D headless rendering"
git clone https://github.com/isl-org/Open3D
cd Open3D
mkdir build && cd build
cmake -DENABLE_HEADLESS_RENDERING=ON \
                 -DBUILD_GUI=OFF \
                 -DUSE_SYSTEM_GLEW=OFF \
                 -DUSE_SYSTEM_GLFW=OFF \
                 ..
make -j$(nproc)
make install-pip-package
cd $CG_FOLDER/conceptgraph
