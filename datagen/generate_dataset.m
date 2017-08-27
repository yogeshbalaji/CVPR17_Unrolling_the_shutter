function generate_dataset(data_path, dest_root)

	filelist = dir(data_path);
    mkdirp([dest_root 'train/']);
    mkdirp([dest_root 'test/']);
    mkdirp([dest_root 'train/images/']);
    mkdirp([dest_root 'test/images/']);
	trainsize = floor((length(filelist)-2)*0.9);
	testsize = length(filelist)-trainsize-2;
	index_shuffle = randperm(length(filelist)-2) + 2;

	% Start with a 356X356 image, apply RS effect and crop the inner subimage. This helps avoiding boundary effects
	% We shall crop the sub image starting at (sr, sc) spanning nrowsfin rows and ncolsfin columns
    
    image_params = struct(  ...
	'init_crop', 356,		...     % initial cropsize of the image before applying RS
	'sr', 50,				...     % start row for cropping RS affected image 
	'sc', 50,				...     % start col for cropping RS affected image.
	'nrowsfin', 256,		...		% number of rows in the final image
	'ncolsfin', 256,		...		% number of cols in the final image
	'num_rs_per_image', 150);		% number of RS samples for each image


	%% Generating training images

	count = 1;
	labels = zeros(trainsize*image_params.num_rs_per_image*2, image_params.init_crop);
	
	for b=1:trainsize
		
		src_img =imread([data_path filelist(index_shuffle(b)).name]);		
		f_orig = center_crop(src_img, image_params);
		f = double(f_orig);
		f_clean = f_orig;
		save_path = [dest_root 'train/images/'];
		[labels, count] = generate_rs_samples(save_path, f, f_clean, labels, count, image_params);
	end;

	train_labels_temp = labels(:,50:305);
	train_labels_temp = train_labels_temp-train_labels_temp(:,1)*ones(1,size(train_labels_temp,2));

	%% Generating test images

	count = 1;
	labels = zeros(testsize*image_params.num_rs_per_image*2, image_params.init_crop);

	for b=trainsize+1:trainsize+testsize
		src_img =imread([data_path filelist(index_shuffle(b)).name]);
		f_orig = center_crop(src_img, image_params);
		f = double(f_orig);
		f_clean = f_orig;
		save_path = [dest_root 'test/images/'];
		[labels, count] = generate_rs_samples(save_path, f, f_clean, labels, count, image_params);
	end;

	test_labels_temp = labels(:,50:305);
	test_labels_temp = test_labels_temp-test_labels_temp(:,1)*ones(1,size(test_labels_temp,2));
	
	%% Downsampling the translation and rotation vector
	
	train_labels = zeros(size(train_labels_temp,1),15);
	test_labels = zeros(size(test_labels_temp,1),15);

	for i=1:size(train_labels,1)
	  train_labels(i,:) = downsample(train_labels_temp(i,:),18);
	end;

	for i=1:size(test_labels,1)
	  test_labels(i,:) = downsample(test_labels_temp(i,:),18);
	end;  

	csvwrite([dest_root 'train/train_labels.csv'], train_labels);
	csvwrite([dest_root 'test/test_labels.csv'], test_labels);
	
end
