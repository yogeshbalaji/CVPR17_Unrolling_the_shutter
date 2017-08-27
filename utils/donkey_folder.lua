--[[
    Copyright (c) 2015-present, Facebook, Inc.
    All rights reserved.

    This source code is licensed under the BSD-style license found in the
    LICENSE file in the root directory of this source tree. An additional grant
    of patent rights can be found in the PATENTS file in the same directory.
]]--

require 'image'
paths.dofile('dataset.lua')

local function csv_split(str, sep)
   sep = sep or ','
   fields={}
   local matchfunc = string.gmatch(str, "([^"..sep.."]+)")
   if not matchfunc then return {str} end
   for str in matchfunc do
      table.insert(fields, str)
   end
   return fields
end

function readCSV(filename, wid)
  
   local file = io.open(filename, "r")
   
   -- estimating the line count
   local num_lines = 0
   for line in file:lines() do
      num_lines = num_lines+1
   end
   file:close()
   file = io.open(filename, "r")
   
   local csv_ten = torch.Tensor(num_lines, wid)
  
   local ln=1
   for line in file:lines() do 
      temp = csv_split(line,",")
      for i=1, wid do
         csv_ten[ln][i] = tonumber(temp[i])
      end
      ln = ln+1
   end
   file:close()
   return csv_ten
end

-- This file contains the data-loading logic and details.
-- It is run by each data-loader thread.
------------------------------------------
-------- COMMON CACHES and PATHS
-- Check for existence of opt.data
opt.data = os.getenv('DATA_ROOT') or opt.data
if not paths.dirp(opt.data) then
    error('Did not find directory: ', opt.data)
end

-- a cache file of the training metadata (if doesnt exist, will be created)
local cache = "cache"
local cache_prefix = opt.data:gsub('/', '_')
os.execute('mkdir -p cache')
local trainCache = paths.concat(cache, cache_prefix .. '_trainCache.t7')

--------------------------------------------------------------------------------------------
local loadSize   = {3, opt.loadSize}

local function loadImage(path)
   local input = image.load(path, 3, 'float')
   -- find the smaller dimension, and resize it to loadSize[2] (while keeping aspect ratio)
   local iW = input:size(3)
   local iH = input:size(2)
   if iW < iH then
      input = image.scale(input, loadSize[2], loadSize[2] * iH / iW)
   else
      input = image.scale(input, loadSize[2] * iW / iH, loadSize[2])
   end
   return input
end

-- channel-wise mean and std. Calculate or load them from disk later in the script.
local mean,std
--------------------------------------------------------------------------------
-- Hooks that are used for each image that is loaded

-- function to load the image, jitter it appropriately (random crops etc.)
local trainHook = function(self, path)
   collectgarbage()
   
   local input = loadImage(path)
   out = input
   -- add mean and std values -- to be done later
   --out = input:add(-1*mean)
   return out
end

--------------------------------------
-- trainLoader
if paths.filep(trainCache) then
   print('Loading train metadata from cache')
   local tlabels = readCSV(opt.labels_path, opt.num_traj_pts)
   
   trainLoader = torch.load(trainCache)
   trainLoader.sampleHookTrain = trainHook
   trainLoader.loadSize = {3, opt.loadSize, opt.loadSize}
   trainLoader.Trajectory_labels = tlabels
else
   print('Creating train metadata')
   local tlabels = readCSV(opt.labels_path, opt.num_traj_pts)
   trainLoader = dataLoader{
      paths = {opt.data},
      loadSize = {3, opt.loadSize, opt.loadSize},
      split = 100,
      verbose = true,
      Trajectory_labels = tlabels
   }
   
   torch.save(trainCache, trainLoader)
   print('saved metadata cache at', trainCache)
   trainLoader.sampleHookTrain = trainHook
end
collectgarbage()

-- do some sanity checks on trainLoader
do
   local class = trainLoader.imageClass
   local nClasses = #trainLoader.classes
   assert(class:max() <= nClasses, "class logic has error")
   assert(class:min() >= 1, "class logic has error")
end
