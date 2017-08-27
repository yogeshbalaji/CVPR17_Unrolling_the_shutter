function transform_targets(targets)
	
	targets_new = targets:clone()
	targets_new[{{}, {1, 15}}] = targets_new[{{}, {1, 15}}]/100
	return targets_new
end

function test()
	local time = sys.clock()
	model:evaluate()
	
	local mserror = 0
	local count = 0
	for i = 1, testData:size(), opt_test.batchSize do
		xlua.progress(i, testData:size())
		input, __, target = testData:getBatch()
		for i=1,input:size()[1] do
			input[i] = input[i] - img_mean
		end
		target = transform_targets(target)
		input, target = cast(input), cast(target)
		local pred = model:forward(input)
		local err = criterion:forward(pred, target)
		mserror = mserror+err
		count = count+1
	end
	mserror = mserror/count

	-- printing statistics
	time = sys.clock() - time
	time = time / testData:size()
	print("\n==> Time to test 1 sample = " .. (time*1000) .. 'ms')
	print("Validation Mean Squared Error = " .. mserror)
	testLogger:add{['% Validation Mean Squared Error'] = mserror}  
end
