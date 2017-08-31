opt_train = {
   data = opt.train_data_path,
   dataset = 'folder',       
   batchSize = opt.batchSize,
   loadSize = 256,
   nThreads = opt.threads,           -- #  of data loading threads to use
   labels_path = opt.train_labels_path,
   num_traj_pts = 15
}

opt_test = {
   data = opt.test_data_path,
   dataset = 'folder',       
   batchSize = opt.batchSize,
   loadSize = 256,
   nThreads = opt.threads,           -- #  of data loading threads to use
   labels_path = opt.test_labels_path,
   num_traj_pts = 15
}

-- creating data loaders
local DataLoader = paths.dofile('../utils/data.lua')
trainData = DataLoader.new(opt_train.nThreads, opt_train.dataset, opt_train)
testData = DataLoader.new(opt_test.nThreads, opt_test.dataset, opt_test)
img_mean = torch.load(opt.img_mean_path)
