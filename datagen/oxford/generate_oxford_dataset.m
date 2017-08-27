%% Script for downloading and generating oxford dataset
clear all;
clc;
close all;

addpath('../');
OXFORD_IMAGES_URL = 'http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/oxbuild_images.tgz';
OXFORD_GTRUTH_URL = 'http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/gt_files_170407.tgz';
TEST_SET_URL = 'http://www.ee.iitm.ac.in/~ee11d035/cvpr17_test_dataset.zip';

mkdirp('../../data');
mkdirp('../../data/oxford');

SAVE_PATH = '../../data/oxford/';

fprintf('Downloading Oxford building dataset ...\n');
websave([SAVE_PATH 'oxbuild_images.tgz'], OXFORD_IMAGES_URL);
fprintf('Downloading Oxford building dataset - GT files ...\n');
websave([SAVE_PATH 'gt_files_170407.tgz'], OXFORD_GTRUTH_URL);

fprintf('Extracting ...\n');
untar([SAVE_PATH 'oxbuild_images.tgz'], [SAVE_PATH 'oxbuild_images']);
untar([SAVE_PATH 'gt_files_170407.tgz'], [SAVE_PATH 'gt_files_170407']);

fprintf('Obtaining cleaned Oxford images ...\n');

IMG_PATH = [SAVE_PATH 'oxbuild_images/'];
GT_PATH = [SAVE_PATH 'gt_files_170407/'];
DEST_IMG_PATH = [SAVE_PATH 'oxbuild_images_cleaned/'];

oxford_clean(IMG_PATH, GT_PATH, DEST_IMG_PATH);

fprintf('Generating Rolling Shutter dataset ...\n');
generate_dataset(DEST_IMG_PATH, SAVE_PATH);

fprintf('Downloading test sets... \n');
TEST_SET_SAVE_PATH = '../../data/test_set/';
mkdirp(TEST_SET_SAVE_PATH);
websave([TEST_SET_SAVE_PATH 'cvpr17_test_dataset.zip'], TEST_SET_URL);
unzip([TEST_SET_SAVE_PATH 'cvpr17_test_dataset.zip'], [TEST_SET_SAVE_PATH 'cvpr17_test_dataset']);
