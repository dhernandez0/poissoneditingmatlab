%%% HOW DOES IT WORK??
% Choose the source image.
% Choose the destination image.
% Choose the points to create a mask, press ENTER to confirm;
% Choose the position of the mask, press + or - buttons to scale image,
%    press ENTER to confirm.

% Load source file
[FileName,PathName] = uigetfile({'*.jpg;*.png','Select source image'});
src = double(imread([PathName '/' FileName]))/255;

% Load destination file
[FileName,PathName] = uigetfile({'*.jpg;*.png','Select destination image'});
dest = double(imread([PathName '/' FileName]))/255;

% Execute Poisson editing
tic
res = poison_draw_imgs(src, dest);
toc
figure; imshow(res);

% Save result to disk
[FileName,PathName] = uiputfile({'*.png';'*.jpg'},'Save results to disk');
if isequal(FileName,0) || isequal(PathName,0)
	disp('User selected Cancel')
else
	imwrite(res, [PathName '/' FileName]);
	disp('Image saved to disk');
end
