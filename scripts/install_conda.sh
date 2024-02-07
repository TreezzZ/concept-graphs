DOWNLOAD_CACHE_ROOT="/shuzhao/Projects/TaskOrientedLMM/Dataset/ConceptGraph"
echo "Installing anaconda"

if [ -d "$DOWNLOAD_CACHE_ROOT" ]; then
  cp $DOWNLOAD_CACHE_ROOT/anaconda.sh /tmp
else
  wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O /tmp/anaconda.sh
fi
bash /tmp/anaconda.sh -b -p $HOME/anaconda
eval "$(~/anaconda/bin/conda shell.bash hook)"
conda init
conda create -y -n cg anaconda python=3.10
source activate cg
