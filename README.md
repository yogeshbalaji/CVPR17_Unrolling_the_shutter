# CVPR17_Unrolling_the_shutter

This repository has the source code for the project "Unrolling the Shutter: CNN to Correct Motion Distortions". The paper can be found [here](http://openaccess.thecvf.com/content_cvpr_2017/papers/Rengarajan_Unrolling_the_Shutter_CVPR_2017_paper.pdf). 

## Citing this work

If you find this work useful in your research, please consider citing:

    @inproceedings{UnrollingShutter_CVPR17,
        Author = {Vijay Rengarajan and Yogesh Balaji and A.N. Rajagopalan},
        Title = {Unrolling the Shutter: CNN to Correct Motion Distortions},
        Booktitle = {Computer Vision and Pattern Recognition (CVPR)},
        Year = {2017}
    }

## Prerequisites

- Torch
- MATLAB

## Data generation

Go to datagen/oxford/ folder and run generate_oxford_dataset.m. This script downloads Oxford Building dataset, extracts "good and ok" image subsets, and generates synthetic Rolling Shutter dataset. It also downloads the test sets that were used in our experiments. 

To download the building dataset used in our paper (comprising building images of Sun, Oxford and Zurich datasets, go to datagen/buildings and run download_and_save.sh.

To generate synthetic RS images on any other dataset, run datagen/generate_dataset.m.

## Training procedure

Once the dataset is generated, to begin training, go to train/ folder and run

	th run.lua

The default paths are set for the Oxford Building dataset generated above. For any other dataset, make sure the training and validation paths are set appropriately. The trained models will be saved in train/results/ folder.

## Experiments

To perform end-to-end rectification on a test set, go to experiments/ folder and run

	./full_rectify.sh

The default paths are set for the test sets downloaded from the Data generation script. For other test sets, make sure the data and model paths are set appropriately. 

This script performs the CNN forward pass to estimate the motion vectors, and subsequently calls a matlab script that uses this motion vector to rectify the images. The rectified images are stored in experiments/results/rectified_imgs/ folder.
