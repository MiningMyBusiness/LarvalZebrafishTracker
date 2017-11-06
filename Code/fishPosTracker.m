% NAME:
% fishPosTracker
% Tracks the position (centroid) of one or more fish in a dish based on blob
% detection.
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
% displayOn             logical that indicates whether the user wants to 
%                       plot the tracked points at the end of the run or
%                       not. This overlays the tracked points on a combined
%                       image of the first and last frame of the fish
%                       motion capture video. The color of the points
%                       indicate the time - plotted with jet colormap. Blue
%                       points are towards the beggining of the movie and
%                       red points are towards the end. 
%
% OUTPUTS:
% trackedPos            the tracked position (x,y) of all fish found in the first
%                       frame of the video. This is a 3D matrix of the form
%                       Number of frames X 2 X Number of fish. 
%            
% 
% NOTE:
% This code should work on a variety of fish motion capture videos as
% long as the fish has negative contrast (is dark on a white background)
% and is swimming in clean water. The code will face issues in tracking if
% there are many fish which cross paths often. 
%
% Please note that nans are interpolated and output is kalman
% filtered. Kalman filtering takes as input estimates of prediction and
% measurement uncertainty. These values are hard-coded in this function.
% However, this may be different for different systems. In such a case, the
% user should consider manipulating these values for best results. Please
% find predSigma and measSimga in lines 239-240.
%
% AUTHOR:
% Kiran D. Bhattacharyya (bhattacharyykiran12@gmail.com)
%
% License: MIT License 
%
% Example use:
%           myFiles = dir('*Trial*');
%           trackedPos = fishPosTracker(myFiles(1).name, 'tif', 108, 1000);

function trackedPos = fishPosTracker(fishMovieDir, imgExt, avgFishLength, fps, imgLoc, displayOn)

    % image resize ratio, will resize image to save on computation time 
    imSizeRat = 0.5;

    % correct fish length for image resizing
    avgFishLength = avgFishLength*imSizeRat;

    % account for possible difference in zoom level of images (fish size in
    % image)
    mmPerPxl = 4/avgFishLength; % assume the average larval zebrafish is 4mm long
                                % and calculate mm/pxl
    mm2PerPxl = mmPerPxl^2; % mm^2/pixel

    % get upper and lower bounds of blob areas to be used later for fish
    % detection
    areaLowBound = round(0.2752/mm2PerPxl); % lower bound of the area of fish head/swim bladder
    areaUppBound = round(1.12/mm2PerPxl); % upper bound of the area of fish head/swim bladder
    smallSpecks = round(0.112/mm2PerPxl); % small specks in image to be ignored

    % calculate the most a fish can move in one frame
    fishTopSpeed = 0.93; % top speed of fish mm/ms (impossible, to account for losing the fish sometimes)
    fishTopSpeed_pxl = fishTopSpeed/mmPerPxl; % top speed in pixels
    timeBetweenFrames = 1000/fps; % time between frames in milliseconds
    maxDistByFrame = fishTopSpeed_pxl*timeBetweenFrames; % maximum distance traveled for a fish between successive frames


    strelLength = round(0.2226/mmPerPxl); % calculate length of line strel object for image dilation
    se1 = strel('line', strelLength, 0); % defining strel objects for dilating binary image
    se2 = strel('line', strelLength, 90);

    % find all images in this folder with the image extension
    myImgs = dir([fishMovieDir '/*.' imgExt]); 

    % load first image to get image size 
    thisImg = imread([fishMovieDir '/' myImgs(1).name]); % load in first image

    % get image size (account for resizing)
    n_row = floor(size(thisImg, 1)*imSizeRat);
    n_col = floor(size(thisImg, 2)*imSizeRat);

    % make sure image location of where to look for fish makes sense
    if ~exist('imgLoc','var')
        % since the user didn't pass this variable, set it to the entire image
        imgLoc = [1, 1;n_col, n_row];
    elseif isempty(imgLoc)
        imgLoc = [1, 1;n_col, n_row];
    elseif sum(imgLoc(:,1) > n_row) > 0 || sum(imgLoc(:,2) > n_col) > 0
        % user entered image location that doesn't exist, set image location to
        % the entire image
        imgLoc = [1, 1;n_col, n_row];
    elseif sum(imgLoc(:,1) < 1) > 0 || sum(imgLoc(:,2) < 1) > 0
        % user entered image location that doesn't exist, set image location to
        % the entire image
        imgLoc = [1, 1;n_col, n_row];
    end
    
    % make sure 

    % make sure displayOn variable exists
    if ~exist('displayOn','var')
        displayOn = 0;
    end

    for jj = 1:size(myImgs, 1) 
        %---- Read in image, binarize, and detect blobs ----%
        thisImg = imread([fishMovieDir '/' myImgs(jj).name]); % load in image
        thisImg_sm = imresize(thisImg, 0.5); % resize image
        if jj == 1 % store the first and last image for displaying at the end (if on)
            firstImg = thisImg;
        elseif jj == size(myImgs, 1)
            lastImg = thisImg;
        end
        thisImg_sm_filt = imgaussfilt(thisImg_sm, 1); % filter the image
        thisImg_sm_bin = imbinarize(thisImg_sm_filt); % binarize image
        thisImg_sm_bin2 = bwareaopen(~thisImg_sm_bin, smallSpecks); % get rid of small specks in binary image
        thisImg_sm_bin3 = imdilate(thisImg_sm_bin2, [se1, se2]); % dilate the image
        CC = bwconncomp(thisImg_sm_bin3); % find connected components
        S = regionprops(CC, 'Centroid'); % find centroids of connected components

        %---- If this is the first frame, then find the number of visible fish
        %     in the dish ---------------------------------------------------%
        if jj == 1 % if this is the first frame 
            numOfFish = 0; % variable to store the number of fish
            myObjectIndex = []; % variable to store the index of fish-like blobs
            for kk = 1:size(CC.PixelIdxList, 2) % loop through all blobs identified
                objectSize = size(CC.PixelIdxList{kk}, 1); % find number of pixels in each object
                objCenter = S(kk).Centroid; % get centroid location
                xLoc = objCenter(1); % get x and y values for centroid location
                yLoc = objCenter(2); 
                fishInLoc = (xLoc > imgLoc(1,2) && xLoc <= imgLoc(2,2)) && (yLoc > imgLoc(1,1) && yLoc <= imgLoc(2,1)); % is fish in image location
                if objectSize >= areaLowBound && objectSize <= areaUppBound && fishInLoc % if object is about the size of a fish and fish is in the image location
                    numOfFish = numOfFish + 1; % update the number of fish counter
                    myObjectIndex(numOfFish) = kk; % store object index
                end
            end
            fishCenter = nan(size(myImgs, 1), 2, numOfFish); % create a variable to store fish centroids
            for kk = 1:numOfFish % for each fish found 
                fishCenter(jj,:,kk) = S(myObjectIndex(kk)).Centroid; % enter their centroid in the first frame to the data variable 
            end
            h = waitbar(0,{['Found ' num2str(numOfFish) ' fish in the first frame.'], 'Tracking fish position/s in all frames...'}); % initiate progress bar
        %---- If this is not the first frame, then find the locations of fish
        %     like blobs that are close to identified fish in the last frame -%
        else % if this is not the first frame
            if numOfFish > 0 
                waitbar(jj/size(myImgs, 1)); % update wait bar to show progress
                %--- Find the number of blobs that are fish-like in this frame
                iter = 0; % initialize iteration counter 
                myObjectIndex = []; % variable to store the index of fish like objects
                for kk = 1:size(CC.PixelIdxList, 2) % loop through all objects identified
                    objectSize = size(CC.PixelIdxList{kk}, 1); % find number of pixels in object
                    if objectSize >= areaLowBound && objectSize <= areaUppBound % if object is about the size of a fish
                        iter  = iter + 1; % update the iteration counter
                        myObjectIndex(iter) = kk; % store object index
                    end
                end
                % extract centroids of fish-like blobs from struct datatype and place in a matrix for easier manipulation
                if iter > 0
                    allCenters = zeros(iter, 2); % create variable to store fish-like blob centers
                    for kk = 1:iter % for each object found
                        allCenters(kk,:) = S(myObjectIndex(kk)).Centroid; % store the center
                    end
                    % find distance between new centers and previous fish positions
                    prevFishPos = zeros(1,2,numOfFish); % create variable to populate with previous fish positions
                    for kk = 1:numOfFish
                        lastNonNan = max(find(isnan(fishCenter(:,1,kk)) == 0)); % find the last fish position that was not nan
                        prevFishPos(1,:,kk) = fishCenter(lastNonNan,:,kk); % attribute last non nan fish position as the previous position
                    end
                    myDiffs = repmat(allCenters, 1, 1, numOfFish) - repmat(prevFishPos, iter, 1, 1); % find vector differences between fish position
                    myDists = sqrt(sum(myDiffs.^2, 2)); % find pixel distances between fish positions
                    [minDists, minIndx] = min(myDists); % find min distance and index of minimum distances
                    if size(myDists, 1) == 1
                        minDists = myDists;
                        minIndx = zeros(1,1,numOfFish);
                        minIndx(1,1,:) = 1;
                    end
                    % find new fish positions by using calculated minimum distances
                    for kk = 1:numOfFish % for each fish found in the first frame
                        if minDists(:,:,kk) > maxDistByFrame % if minimum distance to any blobs in the successive frame is too high, then the fish is lost.
                            fishCenter(jj,:,kk) = nan; % then enter nans 
                        else % otherwise 
                            moreThanOneFish = find(minIndx == minIndx(:,:,kk)); % find the number of fish that are share this object
                            if size(moreThanOneFish, 1) > 1 % if more than one fish have this as their object
                                subDists = minDists(:,:,moreThanOneFish); % find distances for each fish 
                                [minDistVal, minDistIndx] = min(subDists); % find the fish that is closest
                                fishCenter(jj,:,moreThanOneFish(minDistIndx)) = allCenters(minIndx(:,:,kk),:); % give the closest fish the centroid
                                for mm = 1:size(moreThanOneFish, 1) % enter nans for all other fish
                                    if mm ~= minDistIndx
                                        fishCenter(jj,:,moreThanOneFish(mm)) = nan;
                                    end
                                end
                            else % if only one fish is close to this object then 
                                fishCenter(jj,:,kk) = allCenters(minIndx(:,:,kk),:); % attribute new center to this fish
                            end
                        end
                    end
                end
            else
               break 
            end
        end
    end
    % raw tracking is complete now nans are interpolated and tracking is
    % kalman filtered 
    if numOfFish > 0
        % interpolate nans
        fishCenter = InterpNans(fishCenter);
        % smooth fish tracking 
        predSigma = 0.15; % stdev of uncertainty in predicted position for kalman filtering (mm)
        measSigma = 0.15; % stdev of uncertainly in measured position for kalman filtering (mm)
        fishCenter = doKalman(fishCenter, predSigma, measSigma, mmPerPxl); % kalman filtering of fish tracking
        trackedPos = (1/imSizeRat)*fishCenter; % double tracked values to account for image resizing
        close(h);
        % if the display is on then plot a figure with the tracking output
        if displayOn 
            figure
            comboImg = zeros(size(firstImg, 1), size(firstImg, 2), 2); % combine first and last images
            comboImg(:,:,1) = firstImg;
            comboImg(:,:,2) = lastImg;
            comboImg = min(comboImg, [], 3);
            imagesc(comboImg) % show the combined image
            colormap(gray)
            axis equal
            axis([1 size(comboImg,1) 1 size(comboImg, 2)])
            numOfFrames = size(trackedPos, 1); % get the number of frames
            coloMat = jet(numOfFrames); % create a matrix of color values with jet colormap for point plotting
            hold on
            for ii = 1:numOfFrames % for each frame
                thisColor = coloMat(ii,:); 
                for jj = 1:size(fishCenter, 3) % for each fish
                    plot(trackedPos(ii,1,jj), trackedPos(ii,2,jj), 'o', 'MarkerSize', 2, 'MarkerEdgeColor', thisColor, 'MarkerFaceColor', thisColor)
                end
            end
            title(['Tracking for ' num2str(numOfFish) ' fish.'])
        end
    else 
        trackedPos = fishCenter;
        waitbar(1);
    end
end % end of fishPosTracker fcn


%%%%% kalman filtering of fish position tracking %%%%%%%
function trackedPos = doKalman(fishCenter, predSigma, measSigma, mmPerPxl)
    fishCenter_kalman = fishCenter; % create a variable to store kalman filtered results 
    predSigma = predSigma/mmPerPxl; % stdev of uncertainty in predicted position
    measSigma = measSigma/mmPerPxl; % stdev of uncertainty in measured position
    for jj = 1:size(fishCenter, 3) % for every fish
        for kk = 1:size(fishCenter, 2) % for every point
            vecForm = fishCenter_kalman(:,kk,jj); % get the point tracking
            for nn = 2:(size(vecForm,1)-1) % for every point starting from the second one and going to the second last
                firstDeriv = vecForm(nn) - vecForm(nn - 1); % estimate the first derivative at this point
                myPred = vecForm(nn) + firstDeriv; % my prediction for the next point
                myMeas = vecForm(nn + 1); % my measurement for the next point
                % fuse predicted and measured positions
                term1 = myPred*(measSigma^2) + myMeas*(predSigma^2); % the numerator 
                term2 = (predSigma^2) + (measSigma^2); % the denominator
                posFuse = term1/term2; % computed the fused value
                %predSigma = ((measSigma^2)*(predSigma^2))/(measSigma.^2 + predSigma.^2);
                % set the fused value for position as the value
                vecForm(nn+1) = posFuse;
            end
            fishCenter_kalman(:,kk,jj) = vecForm; % insert into the original matrix 
        end
    end
    trackedPos = fishCenter_kalman;
end