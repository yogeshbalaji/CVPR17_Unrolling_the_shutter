require 'image'
require 'torch'
require 'nn'
require 'cudnn'
require 'cunn'
local lfs = require("lfs")
opt = {}
opt.network = arg[3]
opt.threads = 1
opt.batchSize = 1
opt.type = 'cuda'
opt.ngpu = 1

datapath = arg[1]
resultspath = arg[2]
os.execute('mkdir -p ' .. resultspath)
rectified_imgs_path = resultspath .. 'rectified_imgs/'
resultspath = resultspath .. 'all_results/'
os.execute('mkdir -p ' .. resultspath)
os.execute('mkdir -p ' .. rectified_imgs_path)
meanpath = arg[4]

torch.setdefaulttensortype('torch.FloatTensor')
cutorch.setDevice(opt.ngpu)

-- function for splitting data in CSV files
local function split(str, sep)
  sep = sep or ','
  fields={}
  local matchfunc = string.gmatch(str, "([^"..sep.."]+)")
  if not matchfunc then return {str} end
  for str in matchfunc do
      table.insert(fields, str)
  end
  return fields
end

-- function to write a tensor to a file
function writeTensor( infilename, intensor )
  local infile = io.open(infilename,'w')
  for i = 1,intensor:size(1) do
    for j = 1,(intensor:size(2)-1) do
      infile:write(intensor[i][j])
      infile:write(',')
    end
    infile:write(intensor[i][-1])
    infile:write('\n')
    infile:flush() 
  end
  infile:close()
end


function readCSV(filename,ht,wid)
  local csv_ten = torch.Tensor(ht,wid)
  local file = io.open(filename,"r")
  local ln=1
  for line in file:lines() do 
    if ln>ht then break end
    temp = split(line,",")
    for i=1,wid do
      csv_ten[ln][i] = tonumber(temp[i])
    end
    ln=ln+1
  end
  file:close()
  return csv_ten
end


model = torch.load(opt.network)
model = cudnn.convert(model, nn)
model = model:cuda()

local img = torch.Tensor(3,256,256)
img_mean = torch.load(meanpath)

for file in lfs.dir( datapath ) do
		if(file ~= '.' and file ~= "..") then
			input = image.load(datapath  ..	file)
			intensor = torch.zeros(1, 3, 256, 256):cuda()
			img = image.load(datapath .. file)
			img = img - img_mean
			intensor[1] = img
			local preds = model:forward(intensor)
			pred_tensor = torch.reshape(preds, 2, 15)
			pred_tensor[1] = pred_tensor[1]*100
			
			os.execute('mkdir -p ' .. resultspath .. string.sub(file,1,-5))
		
			writeTensor( resultspath .. string.sub(file,1,-5) ..'/trans_vector.csv', pred_tensor )		
			image.save(resultspath .. string.sub(file,1,-5) ..'/input.jpg',input)
		end
end

print('Torch execution done')
