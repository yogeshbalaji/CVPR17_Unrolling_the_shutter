%% Function to compute the initial crop
	
function f_orig = center_crop(src_img, image_params)
	
    init_crop = image_params.init_crop;
    sz_src = size(src_img);
	if(sz_src(1)>sz_src(2))
		f_orig = imresize(src_img, init_crop/sz_src(2));
		tmp_cen = floor(size(f_orig,1)/2);
		f_orig = f_orig(tmp_cen-init_crop/2 +1:tmp_cen+init_crop/2,:,:);
	
	else
		f_orig = imresize(src_img,init_crop/sz_src(1));
		tmp_cen = floor(size(f_orig,2)/2);
		f_orig = f_orig(:,tmp_cen-init_crop/2 +1:tmp_cen+init_crop/2,:);    
	end;
	
	f_orig = imresize(f_orig,[init_crop, init_crop]);

end
