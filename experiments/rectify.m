%% Code for rectifying image

function [] = rectify(results_root)
	
	subfolder_list = dir([results_root 'all_results/']);

	xvector = 1:15;
	xvector = xvector*18 -17;
	xvector = xvector';
	pred_vector_upsample = zeros(256,2);
	
	flag = 1;
	
	for i=3:length(subfolder_list)
		if(strcmp(subfolder_list(i).name,'allimgs')==1)
			continue;
		end;
		
		
	  img = imread([results_root 'all_results/' subfolder_list(i).name '/input.jpg']);

	  
	  [nrows,ncols,tmp] = size(img);
	  img = double(img);
	  pred_vector = csvread([results_root 'all_results/' subfolder_list(i).name '/trans_vector.csv']);
	  p_tx = polyfit(xvector,pred_vector(1,:)',2);
	  p_rz = polyfit(xvector,pred_vector(2,:)',2);
	  H = [];
	  for j=1:256
		pred_vector_upsample(j,1) = p_tx(1)*j*j + p_tx(2)*j + p_tx(3);
		pred_vector_upsample(j,2) = p_rz(1)*j*j + p_rz(2)*j + p_rz(3);
		tx = pred_vector_upsample(j,1);
		t = pred_vector_upsample(j,2);
		thisH = [cos(t),sin(t),tx;-sin(t),cos(t),0;0,0,1];
		H = [H thisH];
	  end
	  tmp_output = rsRect(img,H,[nrows/2,ncols/2],1,nrows);

	  output = uint8(tmp_output(:,:,1:size(img,3)));
	  
	  
	  imwrite(output,[results_root 'all_results/' subfolder_list(i).name '/output.jpg']);
	  imwrite(output,[results_root 'rectified_imgs/' subfolder_list(i).name '.png']);
	end;
  
