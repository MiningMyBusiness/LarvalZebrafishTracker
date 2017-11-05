% NAME:
% gifMovieMaker
% Creates an animated gif from sequential Matlab figures. Saves a file 
%
% REQUIRED INPUTS:
% fishMovieDir          a string which has the directory or folder with all
%                       frames of the fish motion capture. The data must be
%                       in frames. The code will not find a video file. 
% 
% imgExt                a string that identifies the extension of the
%                       image. E.g. 'tif' or 'jpg'. 
%
% filename              the file name the animated gif should be saved as.
%
% useFishTracking       logical indicating if the function should load fish
%                       tracking data and overlay on the images
%
% OUTPUTS:
% N/A                               
% 
% NOTE:
% This function uses the result from FishTracker.m if the user decides to
% use fish tracking (useFishTracking = 1). 
%
% AUTHOR:
% Kiran D. Bhattacharyya (bhattacharyykiran12@gmail.com)
%
% License: MIT License 
%
% Example use: 
%           myFiles = dir('*Trial*');
%           trackedFish = FishTracker(myFiles(1).name, 'tif', 108, 1000, [], 0, 0);
%           gifMovieMaker(myFiles(1).name, 'tif', 'FishwTracking.gif', 1);


function gifMovieMaker(fishMovieDir, imgExt, filename, useFishTracking)

myImgs = dir([fishMovieDir '/*.' imgExt]); % find all images in this folder

resizRat = 0.5; % resize image to display faster

if useFishTracking % if the user wants to overlay fish tracking on the gif
    load([fishMovieDir '/trackedFish.mat']); % load the tracked fish files
    trackedFish = trackedFish*resizRat; % scale fish tracking
end

h = figure;
endFrame = size(myImgs, 1); % specify end frame
for ii = 500:endFrame % for every frame
    thisImg = imread([fishMovieDir '/' myImgs(ii).name]); % load in image
    thisImg = imresize(thisImg, resizRat); % resize image
    clf
    imshow(thisImg) % show image
    if useFishTracking % if the user wants fish tracking
        hold on 
        for jj = 1:size(trackedFish, 4) % for each fish
            plot(trackedFish(:,1,ii,jj), trackedFish(:,2,ii,jj), 'b-', 'LineWidth', 2) % plot fish tracking
        end
    end
    title(['Frame number ' num2str(ii) ' out of ' num2str(size(myImgs, 1))])
    frame = getframe(h); 
    im = frame2im(frame); 
    [imind,cm] = rgb2ind(im,256); 

    % Write to the GIF File 
    if ii == 500 
      imwrite(imind,cm,filename,'gif','DelayTime',0,'Loopcount',inf); 
    else 
      imwrite(imind,cm,filename,'gif','DelayTime',0,'WriteMode','append'); 
    end 
end