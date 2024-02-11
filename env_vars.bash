#!/bin/bash
# Example script setting up the rnv variables needed for running ConceptGraphs
# Please adapt it to your own paths!

BASE_FOLDER=/scratch/shuzhao/Projects/TaskOrientedLMM/
CODE_FOLDER=$BASE_FOLDER/Code
DATA_FOLDER=$BASE_FOLDER/Data

export CG_FOLDER=$CODE_FOLDER/concept-graphs

export GSA_PATH=$CODE_FOLDER/Grounded-Segment-Anything

export REPLICA_ROOT=$DATA_FOLDER/Replica
export REPLICA_CONFIG_PATH=${CG_FOLDER}/conceptgraph/dataset/dataconfigs/replica/replica.yaml

export LLAVA_PYTHON_PATH=$CODE_FOLDER/LLaVA
export LLAVA_CKPT_PATH=$DATA_FOLDER/llava_weights