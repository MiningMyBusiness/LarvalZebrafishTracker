% NAME:
% fishBodySmoother
% Smooths the body tracking of one or more fish in a dish by
% 1) removing tracking errors identified through peak detection
% 2) kalman filtering of detected points
% 3) fitting a fourth order polynomial curve to detected body points
%
% REQUIRED INPUTS:
% roughFish             initial tracking of fish body or curvature (output
%                       of fishBodyTracker.m). 
% 
% avgFishLength         the length of the fish in pixels.
%                       This can be some average length of the fish if
%                       multiple videos need to be processed.
%
% OUTPUTS:
% smoothFish            a smoothed output of fish body tracking. This is
%                       the same size as the roughFish matrix.
%            
% 
% NOTE:
% Please note that this function makes certain assumptions about what
% constitutes tracking errors and about the prediction and measurement
% uncertainty of the system for kalman filtering. Unfortunately, these may
% be specific to the fish motion capture system used. The user may need to
% review the code below and find where these assumptions are being made. 
%
% The following is a good introduction to kalman filtering.
% http://www.cl.cam.ac.uk/~rmf25/papers/Understanding%20the%20Basis%20of%20the%20Kalman%20Filter.pdf
%
% AUTHOR:
% Kiran D. Bhattacharyya (bhattacharyykiran12@gmail.com)
%
% License: MIT License 
%
% Example use: 
%           myFiles = dir('*Trial*');
%           trackedPos = fishPosTracker(myFiles(1).name, 'tif', 108, 1000);
%           trackedBody = fishBodyTracker(trackedPos, myFiles(1).name, 'tif', 108);
%           smoothFish = fishBodySmoother(trackedBody, 108);
% Please note above that fishPosTracker and fishBodyTracker are called first.

function smoothFish = fishBodySmoother(roughFish, avgFishLength)

% assume the fish is 4mm in length
mmPerPxl = 4/avgFishLength; % get mm/pxl

% create new variable that will be smoothed
fishBodyPts = roughFish; 

% check to see if there are sharp deviations from the tracking in certain
% frames, if so, then fix. 
maxDeviation = round(0.1/mmPerPxl); % no point should move 100 um in 1 ms. 
for jj = 1:size(fishBodyPts, 4) % for every fish
    for kk = 1:size(fishBodyPts, 1) % for every point
        for mm = 1:size(fishBodyPts, 2) % for x and y position of that point
            for nn = 1:2 % repeat for tracked point to get rid off all peaks
                vecForm = reshape(fishBodyPts(kk,mm,:,jj), [size(fishBodyPts, 3), 1]); % reshape a single point tracking into a vector
                meanVal = nanmean(vecForm); % get the mean of the points (ignoring nans)
                vecForm = vecForm - meanVal; % subtract mean from the vector
                [pks1, locs1] = findpeaks(vecForm, 'MinPeakProminence', maxDeviation, 'MaxPeakWidth', 2); % peaks indicate sharp changes in position
                [pks2, locs2] = findpeaks(-vecForm, 'MinPeakProminence', maxDeviation, 'MaxPeakWidth', 2);
                allLocs = [locs1;locs2]; % get all locations of peaks 
                vecForm(allLocs) = (vecForm(allLocs - 1) + vecForm(allLocs + 1))/2; % replace peaks with average of values around them 
                vecForm = vecForm + meanVal; % add the mean back in
                vecForm = InterpNans(vecForm); % interpolate nans
                vecForm = reshape(vecForm , [1, 1, size(fishBodyPts, 3), 1]); % reshape the vector into the appropriate shape
                fishBodyPts(kk,mm,:,jj) = vecForm; % insert into the original matrix 
            end
        end
    end
end

% Perform post-hoc Kalman filtering
fishBody_kalman = fishBodyPts; % create a variable to store kalman filtered results 
predSigma = 0.06/mmPerPxl; % stdev of uncertainty in predicted position
measSigma = 0.08/mmPerPxl; % stdev of uncertainty in measured position
for jj = 1:size(fishBodyPts, 4) % for every fish
    for ii = 2:size(fishBodyPts, 3) - 1 % for every frame starting from the second one and going to the second last
        for kk = 1:size(fishBodyPts, 1) % for every point
            for mm = 1:size(fishBodyPts, 2) % for x and y position of that point for that frame
                thisPoint = fishBody_kalman(kk, mm, ii, jj);
                prevPoint = fishBody_kalman(kk, mm, ii-1, jj);
                firstDeriv = thisPoint - prevPoint;
                myPred = thisPoint + firstDeriv;
                myMeas = fishBody_kalman(kk, mm, ii+1, jj);
                % fuse predicted and measured positions
                term1 = myPred*(measSigma^2) + myMeas*(predSigma^2); % the numerator 
                term2 = (predSigma^2) + (measSigma^2); % the denominator
                posFuse = term1/term2; % computed the fused value
                fishBody_kalman(kk,mm,ii+1,jj) = posFuse; % insert into the original matrix 
            end
        end
        fishBody_kalman(:,1,ii+1,jj) = fourthOrderApprox(fishBody_kalman(:,1,ii+1,jj)); % do a fourth order approximation
        fishBody_kalman(:,2,ii+1,jj) = fourthOrderApprox(fishBody_kalman(:,2,ii+1,jj));
    end
end

smoothFish = fishBody_kalman;