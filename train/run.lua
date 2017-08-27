require 'torch'
require 'xlua'    
require 'optim' 
require 'image'
require 'nn'  

cmd = torch.CmdLine()
cmd:option('-seed', 1, 'fixed input seed for repeatable experiments')
cmd:option('-threads', 4, 'number of threads')
cmd:option('-save', 'results/', 'subdirectory to save/log experiments in')
cmd:option('-learningRate', 0.5, 'learning rate at t=0')
cmd:option('-batchSize', 64, 'mini-batch size (1 = pure stochastic)')
cmd:option('-weightDecay', 1e-4, 'weight decay (SGD only)')
cmd:option('-load', 1, 'option for loading')
cmd:option('-momentum', 0.9, 'momentum (SGD only)')
cmd:option('-lrd', 0, 'Learning rate decay')
cmd:option('-nepochs', 60, 'Number of epochs to train')
cmd:option('-type', 'cuda', 'type: double | float | cuda')
cmd:option('-ngpu', 1, 'GPU number to use')
cmd:option('-model', 'RowColCNN', 'Model to use| Options: RowColCNN, VanillaCNN')
cmd:option('-train_data_path', '../data/oxford/train/', 'Training data path')
cmd:option('-test_data_path', '../data/oxford/test/', 'Test data path')
cmd:option('-train_labels_path', '../data/oxford/train/train_labels.csv', 'Training label path')
cmd:option('-test_labels_path', '../data/oxford/test/test_labels.csv', 'Test label path')
cmd:option('-img_mean_path', '../datagen/oxford/img_mean.dat', 'Test label path')
cmd:text()
opt = cmd:parse(arg or {})

if opt.type == 'float' then
   torch.setdefaulttensortype('torch.FloatTensor')
elseif opt.type == 'cuda' then
   require 'cunn'
   require 'cutorch'
   require 'cudnn'
   torch.setdefaulttensortype('torch.CudaTensor')
   cutorch.setDevice(opt.ngpu)
end
torch.setnumthreads(opt.threads)
torch.manualSeed(opt.seed)

dofile 'data.lua'
dofile 'model.lua'
dofile 'train.lua'
dofile 'test.lua'

-- Log results to files
trainLogger = optim.Logger(paths.concat(opt.save, 'train.log'))
testLogger = optim.Logger(paths.concat(opt.save, 'test.log'))

if model then
   parameters,gradParameters = model:getParameters()
end

----------------------------------------------------------------------
print '==> configuring optimizer'

optimState = {
  learningRate = opt.learningRate,
  weightDecay = opt.weightDecay,
  momentum = opt.momentum,
  lrd = opt.lrd
}

if opt.type == 'cuda' then
   model = cudnn.convert(model, cudnn)
   model:cuda()
   criterion:cuda()
end

----------------------------------------------------------------------
print '==> training!'

for i=1,100 do
   train(i)
   test()
end
