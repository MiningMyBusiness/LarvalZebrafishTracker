% NAME:
% fishBodyTracker
% Tracks the body of one or more fish in a dish based on blob
% detection and line following.
%
% REQUIRED INPUTS:
% trackedPos            the tracked position (x,y) of all fish found in the first
%                       frame of the video. This is a 3D matrix of the form
%                       Number of frames X 2 X Number of fish. This is the
%                       output of fishPosTracker.
%
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
% OUTPUTS:
% trackedBody           a matrix containing 19 point tracked along the fish
%                       body for every fish in every frame. This matrix has
%                       the shape 19 by 2 by Number-of-frames by
%                       Number-of-fish.
%            
% 
% NOTE:
% This code should work on a variety of fish motion capture videos as
% long as the fish has negative contrast (is dark on a white background)
% and is swimming in clean water. The code will face issues in tracking if
% there are many fish which cross paths often. 
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
% Please note above that fishPosTracker is called first. 

function trackedBody = fishBodyTracker(trackedPos, fishMovieDir, imgExt, avgFishLength)

% account for possible difference in zoom level of images (fish size in
% image)
mmPerPxl = 4/avgFishLength; % assume the average larval zebrafish is 4mm long
                            % and calculate mm/pxl
mm2PerPxl = mmPerPxl^2; % mm^2/pixel

% defining strel objects for dilating binary image (to be used later)
strelDiskSize = round(0.1481/mmPerPxl);
se1 = strel('disk', strelDiskSize, strelDiskSize); 

Npxls = round(4.081/mmPerPxl); % number of pixels around the fish position to crop image
NbodyPts = 19; % number of points to track on fish body
distIncr = round(0.1484/mmPerPxl); % find distance increment to track fish body

areaLowBound = round(0.07/mm2PerPxl); % lower bound of area of fish eyes or swim bladder
areaUppBound = round(0.98/mm2PerPxl); % upper bound of area of fish eyes or swim bladder
smallSpecks = round(0.005/mm2PerPxl); % small specks in image to avoid
distFromCenter = round(1.484/mmPerPxl); % distance from the fish centroid the fish eyes or swim bladder can be

% perform image by image cropping and analysis
myImgs = dir([fishMovieDir '/*.' imgExt]); % find all images in this folder
fishBodyPts = nan(NbodyPts, 2, size(myImgs, 1), size(trackedPos, 3)); % create variable to populate with fish body points for all frames
h = waitbar(0,{['Found position tracking for ' num2str(size(trackedPos, 3)) ' fish.'], 'Tracking fish body/ies in all frames...'}); % initiate progress bar
for jj = 1:size(myImgs, 1) % for every frame
    waitbar(jj/size(myImgs, 1)); % update wait bar to show progress
    thisImg = imread([fishMovieDir '/' myImgs(jj).name]); % load in image
    for kk = 1:size(trackedPos, 3) % for every fish (for multi fish tracking)
        fishBodyPts_frm = nan(NbodyPts,2); % variable to populate with fish body position for this frame
        fishPos = round(trackedPos(jj,:,kk)); % get fish center position
        % crop image into 2N-by-2N pixel size around fish position 
        row_min = max(fishPos(2) - Npxls, 1); % find row min for cropping image
        row_max = min(fishPos(2) + Npxls, size(thisImg, 1)); % find row max for cropping image
        col_min = max(fishPos(1) - Npxls, 1); % find column min for cropping
        col_max = min(fishPos(1) + Npxls, size(thisImg, 2)); % find column max for cropping 
        cropImg = thisImg(row_min:row_max,col_min:col_max); % crop image
        % binarize cropped image to make eyes and swim bladder stand out
        cropImg_bn = edge(cropImg, 0.2); % find edges of image
        cropImg_bn2 = im2bw(cropImg, 0.23); % binarize image
        cropImg_bn3 = cropImg_bn | ~cropImg_bn2; % combine edge and threshold image
        cropImg_bn3_filt = bwareaopen(cropImg_bn3, smallSpecks);
        cropImg_bn_dil = imdilate(cropImg_bn3_filt, se1); % dilate binary image
        % find eyes and swim bladder in image
        CC = bwconncomp(cropImg_bn_dil); % find connected components 
        S = regionprops(CC, 'Centroid'); % find centroids of connected components
        numOfObjs = 0; % variable to store number of eye or bladder like objects found close to fish position
        myObjectIndex = []; % create variable to store object index
        for mm = 1:size(CC.PixelIdxList, 2) % loop through all objects identified
            objectSize = size(CC.PixelIdxList{mm}, 1); % find number of pixels in each object
            fishPos_dist = norm(S(mm).Centroid - [Npxls + 1, Npxls + 1]); % find distance of object centroid from fish position
            if objectSize >= areaLowBound && objectSize <= areaUppBound && fishPos_dist <= distFromCenter % if object the size of fish eyes or swim bladder and close to fish position
                numOfObjs = numOfObjs + 1; % update iteration counter
                myObjectIndex(numOfObjs) = mm; % store object index
            end
        end
        if numOfObjs >= 2 % if at least 2 objects were found 
            allCenters = zeros(numOfObjs, 2); % create variable to store fish eye and bladder-like object centers
            allSizes = zeros(numOfObjs, 1); % vector to store object size in pixels
            for mm = 1:numOfObjs % for each object found
                allCenters(mm,:) = S(myObjectIndex(mm)).Centroid; % store the center
                allSizes(mm) = size(CC.PixelIdxList{myObjectIndex(mm)}, 1); % store the object size 
            end
%                 figure(1) 
%                 clf
%                 imagesc(cropImg_bn_dil)
%                 colormap(gray)
%                 axis equal
%                 hold on
%                 for mmm = 1:size(allCenters,1)
%                     plot(allCenters(mmm,1), allCenters(mmm,2), 'o')
%                 end
%                 hold off
%                 pause(0.1)
            % identify the center of the head by the object size (the larger object is the eyes together) 
            [sortVals, sortIndx] = sort(allSizes); % find max size index
            if numOfObjs == 2
                headPos = allCenters(sortIndx(2),:); % store head position
                bladPos = allCenters(sortIndx(1),:); % store swim bladder position
            elseif numOfObjs == 3 % if three blobs were found (two eyes and one swim bladder, hopefully)
                if jj == 1 % if this is the first frame
                    headPos = fishPos; % set the last head position as the fish centroid position
                end
                Z = pdist2(allCenters, headPos); % find pairwise distances between blobs and last head position
                [minVal, minIndx] = min(round(Z)); % get minimum distance between blobs and last head position
                headPos = mean(allCenters(minIndx,:), 1); % store head position as the closest blob to the last head position
                if jj > 1 % if this is not the first frame
                    Z = pdist2(allCenters, bladPos); % find pairwise distnces between blobs and the last bladder position
                    [minVal, minIndx] = min(round(Z)); % get minimum distance between blobs and last bladder position
                    bladPos = mean(allCenters(minIndx,:), 1); % store swim bladder position
                else % if it is the first frame
                    [maxVal, maxIndx] = max(round(Z)); % get max distance between blobs and last head position
                    bladPos = mean(allCenters(maxIndx,:), 1); % store baldder position as the farthest blob to the last head position
                end
            end
            % track fish body 
            fishBodyPts_frm(1,:) = headPos; % save head and bladder position in fish body points matrix
            fishBodyPts_frm(2,:) = bladPos;
            headToBlad = bladPos - headPos; % find vector from head to bladder
            cropImg_mod = imgaussfilt(cropImg, 1.5);
            for mm = 3:NbodyPts
                bodyVec = fishBodyPts_frm(mm-1,:) - fishBodyPts_frm(mm-2,:); % create a body vector variable which will be updated as we move down fish body
                bodyVec_unit = bodyVec/norm(bodyVec); % make into unit vector
                guessPt = fishBodyPts_frm(mm-1,:) + distIncr*bodyVec_unit; % guess at the next point
                bodyVec_ortho = [1 -(bodyVec_unit(1)/(bodyVec_unit(2) + 0.000001))]; % find orthogonal vector to body vector
                bodyVec_ortho_unit = bodyVec_ortho/norm(bodyVec_ortho); % find unit orthogonal vector to body vector
                pxlCrossPt1 = guessPt + 5*bodyVec_ortho_unit; % find 2 points that are orthonormally distant
                pxlCrossPt2 = guessPt - 5*bodyVec_ortho_unit;
                xVals = round(linspace(pxlCrossPt1(1), pxlCrossPt2(1), 50)); % find x and y ranges between those points
                xVals(xVals <= 0) = 1;
                xVals(xVals > size(cropImg, 2)) = size(cropImg, 2);
                yVals = round(linspace(pxlCrossPt1(2), pxlCrossPt2(2), 50));
                yVals(yVals <= 0) = 1;
                yVals(yVals > size(cropImg, 1)) = size(cropImg, 1);
                if ~isnan(sum(xVals))
                    pxlVals = diag(cropImg_mod(yVals, xVals)); % find pixel values at those indices
                    pxlVals_smth = smooth(double(pxlVals), 3); % smooth pixel values
                    [minPxlVal, minPxlIndx] = min(pxlVals_smth); % find the minimum pxl value index
                    actualPt = [xVals(minPxlIndx), yVals(minPxlIndx)]; % get the actual point
                    fishBodyPts_frm(mm,:) = actualPt;
                end
            end
        fishBodyPts(:,:,jj,kk) = fishBodyPts_frm + repmat([col_min, row_min], [size(fishBodyPts, 1), 1]); % adjust for image cropping
        end
    end
end

close(h);

trackedBody = fishBodyPts;
