% NAME:
% fishBodyPlotter
% Plots the results of fish tracking performed by the other functions. Will
% plot a figure which will have the original image with the tracked body of
% the fish overlaid in blue.
%
% REQUIRED INPUTS:
% fishMovieDir          a string which has the directory or folder with all
%                       frames of the fish motion capture. The data must be
%                       in frames. The code will not find a video file. 
% 
% imgExt                a string that identifies the extension of the
%                       image. E.g. 'tif' or 'jpg'. 
%
% smoothFish            a smoothed output of fish body tracking. This is
%                       the output of fishBodySmoother.m
%
% OUTPUTS:
% N/A
%            
% 
% NOTE:
% Please function only displays figures and has no numerical output.  
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
%           fishBodyPlotter(myFiles(1).name, 'tif', smoothFish)
% Please note above that fishPosTracker and fishBodyTracker are called first.

function fishBodyPlotter(fishMovieDir, imgExt, fishBodyPts)

myImgs = dir([fishMovieDir '/*.' imgExt]); % find all images in this folder

resizRat = 0.5; % resize image to display faster
fishBodyPts = resizRat*fishBodyPts; % scale body tracking to resizing ratio

figure
for ii = 1:size(fishBodyPts, 3) % for every frame
    thisImg = imread([fishMovieDir '/' myImgs(ii).name]); % load in image
    thisImg = imresize(thisImg, resizRat);
    clf
    imshow(thisImg)
    hold on
    for gg = 1:size(fishBodyPts, 4) % for every fish 
        plot(fishBodyPts(:,1,ii,gg), fishBodyPts(:,2,ii,gg), 'b-', 'LineWidth', 2)
    end
    title(['Frame number ' num2str(ii) ' out of ' num2str(size(fishBodyPts, 3))])
    pause(0.01)
end