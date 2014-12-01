function result = div(I_x, I_y)
	I_ii = conv2(I_x, [0;1;-1], 'same');
	I_jj = conv2(I_y, [0,1,-1], 'same');
	result = I_ii + I_jj;
end
