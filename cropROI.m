% This function crops the surrounding rectangle of a polygon
function [res, r] = cropROI(im, pts, addpixel)
	% Get min and maxs to get the surrounding rectangle
	minx = min(pts(:,2))+1-addpixel;
	miny = min(pts(:,1))+1-addpixel;
	maxx = max(pts(:,2))+addpixel;
	maxy = max(pts(:,1))+addpixel;
	
	% Surrounding rectangle
	r = [minx miny abs(maxx-minx) abs(maxy-miny)];
	
	% Crop the rectangle
    if exist('OCTAVE_VERSION', 'builtin') ~= 0
        res = imcrop2(im,r);
    else
        res = imcrop(im,r);
    end

	% Add the pixels we need
	r(1) = r(1) + addpixel;
	r(2) = r(2) + addpixel;
	r(3) = r(3) - addpixel*2;
	r(4) = r(4) - addpixel*2;
end
