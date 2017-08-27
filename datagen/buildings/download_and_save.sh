#!/bin/bash

mkdir -p ../../data/
mkdir -p ../../data/buildings/

wget -P ../../data/buildings/ http://www.ee.iitm.ac.in/~ee11d035/building.tar.gz
tar -xvzf ../../data/buildings/building.tar.gz -C ../../data/buildings/

mv ../../data/buildings/building_trans_rot_extended/train ../../data/buildings/building_trans_rot_extended/images
mkdir -p ../../data/buildings/building_trans_rot_extended/train
mv ../../data/buildings/building_trans_rot_extended/images ../../data/buildings/building_trans_rot_extended/train/.
mv ../../data/buildings/building_trans_rot_extended/train_labels.csv ../../data/buildings/building_trans_rot_extended/train/train_labels.csv

mv ../../data/buildings/building_trans_rot_extended/test ../../data/buildings/building_trans_rot_extended/images
mkdir -p ../../data/buildings/building_trans_rot_extended/test
mv ../../data/buildings/building_trans_rot_extended/images ../../data/buildings/building_trans_rot_extended/test/.
mv ../../data/buildings/building_trans_rot_extended/test_labels.csv ../../data/buildings/building_trans_rot_extended/test/test_labels.csv

