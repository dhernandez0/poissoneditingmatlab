function [res] = poison_draw_imgs(src, dst)
	% The user should choose the points to create the polygon
	fprintf('Choose points to cut mask \n');
	
	% Show the image
	imshow(src);
	hold on;

	xs = [];
	ys = [];
	while(true)
		[x, y, button] = ginput(1);  

		if(button==1)
			% Add the new point
			xs = [xs; floor(x)];
			ys = [ys; floor(y)];
			% And plot it
			plot(x,y,'r*');
		else
			% If the user presses enter, exit
			break;
		end;
	end

	% Finish the polygon with the first point (then, it's closed)
	xs = [xs; xs(1)];
	ys = [ys; ys(1)];
	hold off;

	% Show the destination image
	imshow(dst);

	% Initialise
	oldx = size(dst,2)/2;
	oldy = size(dst,1)/2;
	lastscale = 1;

	% Crop the source getting the surrounding rectangle of the polygon
	[croppedSrc, ~] = cropROI(src, [ys, xs], 0);

	% Ask the user for the point where the polygon will be
	fprintf('Select the position of the mask. Press + or - to zoom it \n');
	while(true)
		[x, y, button] = ginput(1);

		if(button==1) % User chooses a new point
			[xo,yo] = calcAndShow(xs, ys, x, y, croppedSrc, dst);
			oldx=x;
			oldy=y;
		elseif (button==43) % + key -> zoom in
			xs = floor(xs*1.05);
			ys = floor(ys*1.05);
			lastscale = lastscale*1.05;
			[xo,yo] = calcAndShow(xs, ys, oldx, oldy, croppedSrc, dst);
		elseif (button==45) % - key -> zoom out
			xs = floor(xs*0.95);
			ys = floor(ys*0.95);
			lastscale = lastscale*0.95;
			[xo,yo] = calcAndShow(xs, ys, oldx, oldy, croppedSrc, dst);
%		elseif (button==28) % left arrow key
%			xs = xs*cosd(5) - ys*sind(5);
%			ys = xs*sind(5) + ys*cosd(5);
%			
%			[xo,yo] = calcAndShow(xs, ys, oldx, oldy, croppedSrc, dst);
%		elseif (button==29) % right arrow key
%			
		else
			% The user pressed enter, exit
			break; 
		end;
	end;

	% Resize the image to the appropiate size
	src = imresize(src, lastscale);

	% Execute Poisson Editing
	params.src = src;
	params.dest = dst;
	params.pts_src = [ys, xs];
	params.pts_dst = [yo, xo];
	params.max_iter = 10^5;
	params.tol = 10^-4;
	params.verbose = 0;
	params.omega = 1.8;
	params.mix_gradients = 0;
	res = PoissonEditing(params);
end

% Function to show the destination image with the polygon from source inside
% and calculate the destination polygon
function [xo, yo] = calcAndShow(xs, ys, x, y, croppedSrc, dst)
	minx = min(xs);
	miny = min(ys);

	% Destination polygon
	xo = xs - minx + floor(x);
	yo = ys - miny + floor(y);

	% Polygon mask
	mask = poly2mask(xo, yo, size(dst,1), size(dst,2));        

	% Crop the source rectangle (needed because we need to scale)
	minxo = min(xo)+1;
	minyo = min(yo)+1;
	maxxo = max(xo);
	maxyo = max(yo);
	croppedSrc = imresize(croppedSrc, [maxyo-minyo+1 maxxo-minxo+1]);

	% Put the rectangle in the show image
	show = zeros(size(dst));
	show(minyo:maxyo,minxo:maxxo,1) = croppedSrc(:,:,1);
	show(minyo:maxyo,minxo:maxxo,2) = croppedSrc(:,:,2);
	show(minyo:maxyo,minxo:maxxo,3) = croppedSrc(:,:,3);

	% Use the mask to remove the parts of the rectangle that don't coincide with the polygon
	show(:,:,1) = dst(:,:,1).*(1-mask) + show(:,:,1).*(mask);
	show(:,:,2) = dst(:,:,2).*(1-mask) + show(:,:,2).*(mask);
	show(:,:,3) = dst(:,:,3).*(1-mask) + show(:,:,3).*(mask);
	imshow(show)
end
