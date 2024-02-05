wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O ~/anaconda.sh
bash ~/anaconda.sh -b -p $HOME/anaconda
eval "$(~/anaconda/bin/conda shell.bash hook)"
conda init

conda create -y -n cg anaconda python=3.10
conda activate cg
