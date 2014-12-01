% Reference: http://www.cs.jhu.edu/~misha/Fall07/Papers/Perez03.pdf
function res = PoissonEditing(params)
	% Create the polygon mask
	dest_mask = poly2mask(params.pts_dst(:,2), params.pts_dst(:,1), size(params.dest,1), size(params.dest,2));
	% Crop the mask with the surrounding rectangle of the polygon
	[dest_mask, dest_r] = cropROI(dest_mask, params.pts_dst, 0);

	% The result is the destination modified
	res = params.dest;
	niter = zeros(size(params.src,3),1); % Used to add all the iterations (one element per image channel)
    result_f = cell(3,1);
    
	% Let's execute it for each channel
	parfor l=1:size(params.src,3)
		% Crop the source image (l channel), with one pixel more in each border (w+2 and h+2) for boundary conditions
		g = cropROI(params.src(:,:,l), params.pts_src, 1);
		% The same but with the destination and also return the rectangle
		f = cropROI(params.dest(:,:,l), params.pts_dst, 1);

		% Initialise
		orig_f = f;
		old_f = f;
		diff = intmax;
		ni = 0;

		% Compute g gradients
		g_x = conv2(g, [1;-1], 'same');
		g_y = conv2(g, [1,-1], 'same');

		% If the user wants to mix gradients
		if (params.mix_gradients)
			% Calculate f gradients
			f_x = conv2(f, [1;-1], 'same');
			f_y = conv2(f, [1,-1], 'same');

			% Calculate norm
			f_mod = sqrt(f_x.^2 + f_y.^2);
			g_mod = sqrt(g_x.^2 + g_y.^2);

			% Keep the strongest gradient
			mix_mask = g_mod > f_mod;

			g_x = g_x.*mix_mask + f_x.*(~mix_mask);
			g_y = g_y.*mix_mask + f_y.*(~mix_mask);
		end
		g_div = div(g_x,g_y);

		% Iterate until convergence or maximum iterations
		while diff > params.tol && ni < params.max_iter
			if params.verbose
				imshow(f);
				pause(0.001);
			end

			% Boundary condition for non-rectangular mask
			% recover the from original the part that is outside of the polygon
			% but inside the rectangle 
			f(2:end-1, 2:end-1) = f(2:end-1, 2:end-1) .* dest_mask + orig_f(2:end-1, 2:end-1).* (1-dest_mask) ;

			% Execute the Poisson Image Editing algorithm
			f = OmegaRelaxation(f, g_div, params.omega);
			
			% Get the maximum
			diff = norm(abs(old_f-f),inf);
			
			% Reset old_f and increment iteration
			old_f = f;
			ni = ni + 1;
		end
		% Remove the extra pixels used for boundary conditions
		f = f(2:end-1, 2:end-1);
		result_f{l} = f;

% 		x = r(1);
% 		y = r(2);
% 		w = r(3);
% 		h = r(4);
% 
% 		% Get the original rectangle from the image (dest)
% 		orig = res(y:y+h,x:x+w,l);
% 
% 		% Use only the pixels inside the polygon
% 		res(y:y+h,x:x+w,l) = f.*dest_mask + orig.*(~dest_mask);

		niter(l) = ni;
    end
    for l=1:size(params.src,3)
        f = result_f{l};
        x = dest_r(1);
        y = dest_r(2);
        w = dest_r(3);
        h = dest_r(4);
        res(y:y+h,x:x+w,l) = f.*dest_mask + res(y:y+h,x:x+w,l).*(~dest_mask);
    end
    % Show number of iterations
    if params.verbose
        sum(niter)
    end
end


% Omega relaxation discretisation, if omega is 1, this is equivalent to Gauss Seidel
% if it's <1 it's for numerical stability but slower
% if it's >1 it's faster but *could* "jump" solutions
function f = OmegaRelaxation(f, g_div, omega)
	% Seamless cloning formula (10) 
	for i = 2 : size(f,1)-1
		for j = 2 : size (f,2)-1
			f(i,j) = (1-omega)*f(i,j) + omega*(f(i-1, j) + f(i,j-1) + f(i+1,j) + f(i,j+1) - g_div(i,j))/4;
		end
	end
end
