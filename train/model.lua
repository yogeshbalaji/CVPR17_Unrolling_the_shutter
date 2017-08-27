local filename = 'results/model.net'

if io.open(filename,'r') and opt.load == 1 then
	print('File found')
	model = torch.load(filename)
else
	print('Creating a new model')
	
	if opt.model == 'RowColCNN' then  
		bank1 = nn.Sequential()
		bank1:add(nn.SpatialConvolution(32,64,3,64))
		bank1:add(nn.ReLU(true))
		bank1:add(nn.SpatialConvolution(64,64,3,36))
		bank1:add(nn.ReLU(true))
		bank1:add(nn.SpatialConvolution(64,64,3,19))
		bank1:add(nn.ReLU(true))
		bank1:add(nn.View(-1, 7104))
		bank1:add(nn.Linear(7104,4096))
  
		bank2 = nn.Sequential()
		bank2:add(nn.SpatialConvolution(32,64,64,3))
		bank2:add(nn.ReLU(true))
		bank2:add(nn.SpatialConvolution(64,64,36,3))
		bank2:add(nn.ReLU(true))
		bank2:add(nn.SpatialConvolution(64,64,19,3))
		bank2:add(nn.ReLU(true))
		bank2:add(nn.View(-1, 7104))
		bank2:add(nn.Linear(7104,4096))
  
		split_net = nn.ConcatTable()
		split_net:add(bank1)
		split_net:add(bank2)
  
		model = nn.Sequential()
		model:add(nn.SpatialConvolution(3,32,11,11))
		model:add(nn.SpatialMaxPooling(2,2,2,2))
		model:add(nn.ReLU(true))
		model:add(nn.SpatialConvolution(32,32,7,7))
		model:add(nn.ReLU(true))
		model:add(split_net)
		model:add(nn.CAddTable())
		model:add(nn.Tanh())
		model:add(nn.Linear(4096,512))
		model:add(nn.Dropout(0.5))
		model:add(nn.Tanh())
		model:add(nn.Linear(512,128))
		model:add(nn.Dropout(0.5))
		model:add(nn.HardTanh())
		model:add(nn.Linear(128,30))
	
	elseif opt.model == 'VanillaCNN' then
		
		model = nn.Sequential()
		model:add(nn.SpatialConvolutionMM(3,32,11,11)) 
		model:add(nn.ReLU())
		model:add(nn.SpatialMaxPooling(2,2,2,2))
		model:add(nn.SpatialConvolutionMM(32,64,7,7))
		model:add(nn.ReLU())
		model:add(nn.SpatialMaxPooling(2,2,2,2))
		model:add(nn.SpatialConvolutionMM(64,64,5,5))
		model:add(nn.ReLU())
		model:add(nn.SpatialMaxPooling(2,2,2,2))
		model:add(nn.SpatialConvolutionMM(64,64,3,3))
		model:add(nn.ReLU())
		model:add(nn.SpatialMaxPooling(2,2,2,2))
		model:add(nn.View(-1, 9216))
		model:add(nn.Linear(9216,1024))
		model:add(nn.Tanh())
		model:add(nn.Linear(1024,256))
		model:add(nn.HardTanh())
		model:add(nn.Linear(256,30))
	else
		error('Invalid model specified')
	end
end

print('Model architecture')
print(model)

criterion = nn.MSECriterion()
