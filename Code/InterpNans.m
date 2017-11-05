% NAME:
% InterpNans
%
% INPUTS:
% myX is a row or column vector with nan values
%
% OUTPUTS:
% myY is a row or column vector (depending on input) with nan values
% replaced with interpolated values.
% 
% NOTE:
% Any nan values that are not between two real number values will not be
% interpolated. For instance, if myX starts with nans or ends with nans,
% these will not be interpolated.
%
% AUTHOR:
% Kiran D. Bhattacharyya (bhattacharyykiran12@gmail.com)
%
% License: MIT License 
%
% Example use:
%           myY = InterpNans(myX);

function myY = InterpNans(myX)

nanx = isnan(myX); % find nans
state = 0; % create a state variable 
iter = 0; % start an iteration counter
while state == 0 % make sure the last values are not nans (cannot extrapolate)
    if nanx(end - iter) == 1
        nanx(end - iter) = 0;
        iter = iter + 1;
    else
        state = 1;
    end
end
t = 1:numel(myX); % create increments to sample interpolated data
myX(nanx) = interp1(t(~nanx), myX(~nanx), t(nanx)); % interpolate nans in data

myY = myX;