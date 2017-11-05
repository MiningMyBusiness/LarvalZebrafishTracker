# Code explained
This folder contains all of the code files needed to perform the fish tracking shown on the first page of this github repository. 

## General process and structure
FishTracker.m is the main function file which calls all other function files in this folder. All other function files serve as sub-processes within this main function. 

The fish tracking is done in four steps: 
1. The centroid of fish are tracked using blob detection. The code identifies how many fish there are in the first frame and tracks only those fish. If a fish is not visible in the first frame of the motion capture, it will not be tracked. 
2. Nans are removed and interpolated. Fish centroid tracking is smoothed with a Kalman filter. 
3. The results from centroid tracking are then used to track the body length of the fish. This is done by 
* cropping the image around the tracked fish centroid for each frame to only include the fish in the cropped image. 
* identifying the fish eyes and the swim bladder with blob detection in this cropped image.
* using the center of the head and the center of swim bladder as the first two tracked points on the body.
* using the vector from the center of the head to the swim bladder to start a line following algorithm to track the rest of the tail (17 additional points are tracked along the tail). 
4. Spurious body tracking results and nans are removed and interpolated. Fish body tracking is smoothed with a Kalman filter and fitted with a fourth order polynomial. 

## Function descriptions
The following are brief descriptions of each function in this file. There are detailed comments available in every function file. Please open those directly for more information on how to use them. 

#### FishTracker.m
This the main function file that calls all other functions in this folder. 

#### fishPosTracker.m
This function tracks the centroid of the fish and smooths the results. Specifically, it performs Steps 1 and 2 in the process description found above. 

#### fishBodyTracker.m 
This function tracks the body of the fish with the help of the centroid tracking performed by the previous function. It performs Step 3 from the list above. 

#### fishBodySmoother.m 
This function smooths the results from fish body tracking. It performs Step 4 from the list above. 

#### InterpNans.m
This function interpolates any number of nans sandwiched between real values in any vector. Nans found in the beginning or end of the vector will not be interpolated. Other functions in this folder call this function to do that task. This function spans a wide a breadth of use outside of fish tracking.

#### fourthOrderApprox.m
This function outputs a fourth order approximation to any vector input. It is called by fishBodySmoother.m to do that task. 
