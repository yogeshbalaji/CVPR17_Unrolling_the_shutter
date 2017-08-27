%% Function to generate synthetic RS samples for a given image

function [labels, count] = generate_rs_samples(save_path, f, f_clean, labels, count, image_params)
	
    init_crop = image_params.init_crop;
    sr = image_params.sr;
    sc = image_params.sc;
    nrowsfin = image_params.nrowsfin;
    ncolsfin = image_params.ncolsfin;
    num_rs_per_image = image_params.num_rs_per_image;
        
	for l=1:num_rs_per_image
	
		nrows = size(f,1);
		ncols = size(f,2);
	  
		temp_labels = zeros(1, init_crop);		  
		H = [];
		
		% Parameters for generating random polynomials
		% Polynomial for tx: alpha1*x^2 + beta1*x + gamma1
		% Polynomial for t:  alpha2*x^2 + beta2*x + gamma2

		alpha1 = (rand(1)-0.5)*6;
		beta1 = (rand(1)-0.5)*12;
		gamma1 = 0;	

		alpha2 = (rand(1)-0.5)*0.8;
		beta2 = (rand(1)-0.5)*0.8;
		gamma2 = 0;
		
        num_trans = floor(num_rs_per_image/6);
        num_rot = num_trans;

		% We include some images with pure translation (no rotation) and some with pure rotation (no translation)
		if(l<=num_trans)
			alpha2 = 0;
			beta2 = 0;
			gamma2 = 0;
		end;
	  
		if(l>num_trans && l<=num_rot)
			alpha1 = 0;
			beta1 = 0;
			gamma1 = 0;
		end;
		
		% Computing the motion vector for the start row so as to subtract later. This is to ensure that after
		% cropping the RS image, the cropped image has 0 translation and 0 rotation in the first row (as reference)
		
		tx_start = (alpha1*((sr*5/nrows)^2)+beta1*(sr*5/nrows)+gamma1);
		t_start = (alpha2*((sr/nrows)^2)+beta2*(sr/nrows)+gamma2)*(pi/8);
	  
			
		for i = 1:nrows
				  
			tx = (alpha1*((i*5/nrows)^2)+beta1*(i*5/nrows)+gamma1) - tx_start;
			t = (alpha2*((i/nrows)^2)+beta2*(i/nrows)+gamma2)*(pi/8) - t_start;
			temp_labels(1,i) = tx;
			temp_labels(2,i) = t;
			ty = 0;
			thisH = [cos(t),sin(t), tx; -sin(t), cos(t), 0; 0, 0, 1];
			H = [H thisH];
		end

		g = rsImage(f,H,[sr+nrowsfin/2,sc+ncolsfin/2]);
		g = uint8(g);
		g = g(50:305,50:305,:);
		file_name = [save_path num2str(count) '.png'];
		imwrite(g,file_name);  
		labels(2*count-1,:) = temp_labels(1,:);
		labels(2*count,:) = temp_labels(2,:);    
		count = count+1;

	end;
	
	file_name = [save_path num2str(count) '.png'];
	f_clean = f_clean(50:305,50:305,:);
	imwrite(f_clean,file_name);
	temp_labels = zeros(2,356);
	labels(2*count-1,:) = temp_labels(1,:);
	labels(2*count,:) = temp_labels(2,:);
	count = count+1;

end
