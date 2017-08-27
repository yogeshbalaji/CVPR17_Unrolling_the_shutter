# CVPR17_Unrolling_the_shutter

This repository has the source code for the project "Unrolling the Shutter: CNN to Correct Motion Distortions". The paper can be found [here](http://openaccess.thecvf.com/content_cvpr_2017/papers/Rengarajan_Unrolling_the_Shutter_CVPR_2017_paper.pdf). 

## Citing this work

If you find this work useful in your research, please consider citing:

    @inproceedings{UnrollingShutter_CVPR17,
        Author = {Vijay Rengarajan and Yogesh Balaji and A.N. Rajagopalan},
        Title = {Deep Metric Learning via Lifted Structured Feature Embedding},
        Booktitle = {Computer Vision and Pattern Recognition (CVPR)},
        Year = {2017}
    }

## Prerequisites

- Torch
- MATLAB

## Data generation

Go to datagen/oxford and run generate_oxford_dataset.m. This script downloads Oxford Building dataset, extracts "good and ok" subsets of images, and generates synthetic Rolling Shutter dataset. It also downloads the test sets that were used in our experiments. To generate synthetic RS images on any other dataset, run datagen/generate_dataset.m.

## Training procedure

Once the dataset is generated, to begin training, go to train/ and run

	th run.lua

The default paths are set for the Oxford Building dataset generated above. For any other dataset, make sure the training and validation paths are set appropriately. The models are stored in train/results/ folder.

## Experiments

To perform end-to-end rectification on a test set, go to experiments/ folder and run

	./full_rectify.sh

The default paths are set for the test sets downloaded from the Data generation script. For other datasets, set the paths appropriately. This script performs the CNN forward pass and extracts the estimated motion vector, and subsequently calls a matlab script that uses the motion vector to rectify the images. The rectified images are stored in experiments/results/rectified_imgs/ folder.
