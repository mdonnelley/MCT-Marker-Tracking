function C = correctIllumination(D)

% Uses toolbox available at http://au.mathworks.com/matlabcentral/fileexchange/41250-discrete-orthogonal-polynomial-toolbox--dopbox-version-1-8
% Implements code available at http://au.mathworks.com/matlabcentral/fileexchange/42474-2d-polynomial-data-modelling--version-1-0?focused=3789499&tab=function
%
% corrected = im2uint8(mat2gray(correctIllumination(double(inimage))));

[ny, nx] = size( D );

% Define the degree of the basis functions for the x and y directions
degreeX = 3;
degreeY = 3;

% The function call dop uses the number of basis functions not degree
noBfsX = degreeX + 1;
noBfsY = degreeY + 1;

% Generate the discrete orthogonal basis functions
Bx = dop( nx, noBfsX );
By = dop( ny, noBfsY );

% Compute the 2D Polynomial Spectrum
Sp = By' * D * Bx;

% Compute the Illumination Approximation
Z = By * Sp * Bx';

% Correct the Image Intensity
C = D - Z;