%% Code for obtaining cleaned Oxford dataset

function oxford_clean(IMG_PATH, GT_PATH, DEST_IMG_PATH)

% We shall extract good and ok images and ignore junk images from Oxford
% building dataset

mkdirp(DEST_IMG_PATH);
filelist_good = dir([GT_PATH '*_good.txt']);
filelist_ok = dir([GT_PATH '*_ok.txt']);

for i = 1:length(filelist_good)
    files = textread([GT_PATH filelist_good(i).name], '%s');
    for j = 1:length(files)
        copyfile([IMG_PATH files{j} '.jpg'], [DEST_IMG_PATH files{j} '.jpg']);
    end
end

for i = 1:length(filelist_ok)
    files = textread([GT_PATH filelist_ok(i).name], '%s');
    for j = 1:length(files)
        copyfile([IMG_PATH files{j} '.jpg'], [DEST_IMG_PATH files{j} '.jpg']);
    end
end
