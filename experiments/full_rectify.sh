#!/bin/bash

# Specify the paths of model and data

DATA_PATH="../data/test_set/cvpr17_test_dataset/buildings_caltech/rs_affected/"
MODEL_PATH="../train/results/model.net"
RESULTS_PATH="results/"
MEAN_PATH='../datagen/oxford/img_mean.dat'

th run_CNN.lua $DATA_PATH $RESULTS_PATH $MODEL_PATH $MEAN_PATH
matlab -nodisplay -nodesktop -r "rectify $RESULTS_PATH; quit;"
