% NAME:
% FourthOrderApprox - approximates fish body curvature of fish with fourth order
% polynomial for a smoothing effect
%
% INPUTS:
% myY is a column vector
%
% OUTPUTS:
% myY_fourth is column vector that is a fourth order approximation of myX

function myY_fourth = fourthOrderApprox(myY)

myY_sub = myY(2:end); % exclude the first point as this will be the head of the fish
                      % the second point will start at/near the swim
                      % bladder
myXmax = size(myY_sub, 1); % get size of column vector
myX = (1:1:myXmax)'; % create a column vector of x values
myXs = [myX.^4, myX.^3, myX.^2, myX, ones(myXmax,1)]; % create a matrix of x values with fourth order
myCoeffs = myXs\myY_sub; % find the coefficients for the polynomial fit with pseudoinversion
myY_sub_fifth = myXs*myCoeffs; % compute the fitted curve
myY_fourth = [myY(1);myY_sub_fifth]; % incorporated the first value into the fitted values
