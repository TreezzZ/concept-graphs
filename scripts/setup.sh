INSTALL_ROOT="~/"
mkdir -p $INSTALL_ROOT
cd $INSTALL_ROOT

echo "Installing anaconda"
wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O $INSTALL_ROOT/anaconda.sh
bash $INSTALL_ROOT/anaconda.sh -b -p $HOME/anaconda
eval "$(~/anaconda/bin/conda shell.bash hook)"
conda init
conda create -y -n cg anaconda python=3.10
bash
conda activate cg

echo "Installing packages"
conda install -y pytorch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 pytorch-cuda=11.8 -c pytorch -c nvidia
pip install tyro open_clip_torch wandb h5py openai hydra-core distinctipy imageio==2.19.3 imageio-ffmpeg=0.4.7
conda install -y https://anaconda.org/pytorch3d/pytorch3d/0.7.4/download/linux-64/pytorch3d-0.7.4-py310_cu118_pyt201.tar.bz2

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
conda install -y -c conda-forge cudatoolkit-dev
export AM_I_DOCKER=False
export BUILD_WITH_CUDA=True
export CUDA_HOME=$HOME/anaconda/envs/cg/
python -m pip install -e segment_anything
python -m pip install -e GroundingDINO
pip install --upgrade diffusers[torch]
git clone https://github.com/xinyu1205/recognize-anything.git
pip install -r ./recognize-anything/requirements.txt
pip install -e ./recognize-anything/
git submodule init
git submodule update
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
wget https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
wget https://huggingface.co/spaces/xinyu1205/Tag2Text/resolve/main/ram_swin_large_14m.pth
wget https://huggingface.co/spaces/xinyu1205/Tag2Text/resolve/main/tag2text_swin_14m.pth
export GSA_PATH=`pwd`
cd $INSTALL_ROOT

echo "Installing LLaVA"
git clone https://github.com/3d-language-model/llava-mod.git
cd llava-mod
pip install -e .
export LLAVA_PYTHON_PATH=`pwd`
cd $INSTALL_ROOT

echo "Installing conceptgraph"
git clone https://github.com/concept-graphs/concept-graphs.git
cd concept-graphs
export CG_FOLDER=`pwd`
export REPLICA_CONFIG_PATH=${CG_FOLDER}/conceptgraph/dataset/dataconfigs/replica/replica.yaml
pip install -e .
cd $INSTALL_ROOT

echo "Downloading LLaVA weights"
python $CG_FOLDER/scripts/download_llava_weights.py
cd llava_weights
export LLAVA_MODEL_PATH=`pwd`
cd $INSTALL_ROOT

echo "Download replica dataset"
wget https://raw.githubusercontent.com/cvg/nice-slam/master/scripts/download_replica.sh
bash download_replica.sh
cd Datasets/Replica
export REPLICA_ROOT=`pwd`
cd $INSTALL_ROOT

echo "Build Open3D headless rendering"
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt install -y g++-11
apt-get install libosmesa6-dev libglu1-mesa-dev
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
