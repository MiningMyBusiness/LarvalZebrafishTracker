% NAME:
% fishTracker
% Master fish tracking file which calls all relevant functions to perform larval 
% zebrafish tracking.
%
% REQUIRED INPUTS:
% fishMovieDir          a string which has the directory or folder with all
%                       frames of the fish motion capture. The data must be
%                       in frames. The code will not find a video file. 
% 
% imgExt                a string that identifies the extension of the
%                       image. E.g. 'tif' or 'jpg'. 
%
% avgFishLength         the length of the fish in pixels in this video.
%                       This can be some average length of the fish if
%                       multiple videos need to be processed. This info is
%                       used to find fish-like blobs in the image.
%
% fps                   the frames per second recording rate. This is used
%                       for estimates about fish movement based on data.
%
% OPTIONAL INPUTS
% imgLoc                the location of the fish in the first frame given as a 
%                       small box around the one or more fish of interest. 
%                       This is entered as the top left and bottom right of
%                       the box describing it in the image with x, y
%                       coordinates. 
%                       e.g. [x1, y1;x2, y2] or in image indicies
%                       [column_topLeft, row_topLeft; column_bottomRight, row_bottomRight]
%                       For instance, if you expect the fish to be in the
%                       top left of the image in a square with sides that is 100
%                       pixels long you would put [1, 1;100, 100]
%
% posTrack              logical that indicates whether the user wants to 
%                       plot the tracked position of the fish. This overlays 
%                       the tracked centroid of fish on a combined
%                       image of the first and last frame of the fish
%                       motion capture video. The color of the points
%                       indicate the time - plotted with jet colormap. Blue
%                       points are towards the beggining of the movie and
%                       red points are towards the end.
%
% bodyTrack             logical that indicates whether the user wants to 
%                       plot the tracked body of the fish. This overlays 
%                       the tracked line along the fish body/s on a video of
%                       the fish motion capture. 
%
% OUTPUTS:
% trackedFish           tracking of fish body or curvature in the motion
%                       capture video. 
%            
% 
% NOTE:
% This function calls the following functions 
% 1) fishPosTracker.m
% 2) fishBodyTracker.m
% 3) fishBodySmoother.m
% 4) fishBodyPlotter.m (optional call)
%
% AUTHOR:
% Kiran D. Bhattacharyya (bhattacharyykiran12@gmail.com)
%
% License: MIT License 
%
% Example use: 
%           myFiles = dir('*Trial*');
%           trackedFish = FishTracker(myFiles(1).name, 'tif', 108, 1000, [], 1, 1)

function trackedFish = FishTracker(fishMovieDir, imgExt, avgFishLength, fps, imgLoc, posTrack, bodyTrack)

% track fish centroid/s
trackedPos = fishPosTracker(fishMovieDir, imgExt, avgFishLength, fps, imgLoc, posTrack);

% track fish body/ies
trackedBody = fishBodyTracker(trackedPos, fishMovieDir, imgExt, avgFishLength);

% smooth tracking
smoothFish = fishBodySmoother(trackedBody, avgFishLength);

% assign output
trackedFish = smoothFish;

% save result
save([fishMovieDir '/trackedFish.mat'], 'trackedFish')

% make sure bodyTrack exists
if ~exist('bodyTrack','var') 
    bodyTrack = 0;
end

% if the user wants the visualize the output
if bodyTrack
    fishBodyPlotter(fishMovieDir, imgExt, smoothFish)
end