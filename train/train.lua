local inputs, targets, mserror

function cast(x)
	if opt.type == 'double' then
		x = x:double()
	elseif opt.type == 'cuda' then
		x = x:cuda()
	else
		x = x:float()
	end
	return x
end

local feval = function(x)

	if x ~= parameters then
		parameters:copy(x)
	end
	gradParameters:zero()

	local output = model:forward(inputs)
	local err = criterion:forward(output, targets)
	local df_do = criterion:backward(output, targets)
	model:backward(inputs, df_do)
	mserror = mserror+err
	return err, gradParameters
end

function transform_targets(targets)
	
	targets_new = targets:clone()
	targets_new[{{}, {1, 15}}] = targets_new[{{}, {1, 15}}]/100
	return targets_new
end

function train(iter_num)

	local time = sys.clock()
	mserror = 0
	local count = 0
	model:training()
	
	if iter_num%15 == 1 and iter_num>1 then
		opt.learningRate = opt.learningRate/10
		optimState = {
			learningRate = opt.learningRate,
			weightDecay = opt.weightDecay,
			momentum = opt.momentum,
			lrd = opt.lrd
		}
		print('Learning rate changed to ' .. opt.learningRate)
	end
	
	print("==> online epoch # " .. iter_num .. ' [batchSize = ' .. opt.batchSize .. ']')

	for i = 1, trainData:size(), opt.batchSize do
		xlua.progress(i, trainData:size())
		inputs, __, targets = trainData:getBatch()
		for i=1,inputs:size()[1] do
			inputs[i] = inputs[i] - img_mean
		end
		targets = transform_targets(targets)
		inputs, targets = cast(inputs), cast(targets)
		optim.sgd(feval, parameters, optimState)
		count = count+1
	end

	-- Printing statistics
	
	time = sys.clock() - time
	time = time / trainData:size()
	print("\n==> Time to learn 1 sample = " .. (time*1000) .. 'ms')

	mserror = mserror/count
	print("Training Mean Squared Error = " .. mserror)
	trainLogger:add{['% Training Mean Squared Error'] = mserror}
   
	-- save/log current net
	
	local filename = paths.concat(opt.save, 'model.net')
	os.execute('mkdir -p ' .. sys.dirname(filename))
	print('==> saving model to '..filename)
	torch.save(filename, model:clearState())

	if iter_num%10 == 1 then
		local filename = paths.concat(opt.save, 'model_'..iter_num..'.net')
		os.execute('mkdir -p ' .. sys.dirname(filename))
		print('==> saving model to '..filename)
		torch.save(filename, model:clearState())
	end
end
