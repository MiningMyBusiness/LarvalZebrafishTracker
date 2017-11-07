# Larval Zebrafish Tracker
Tracks points on the bodies of swimming larval zebrafish for kinematics.

## Motivation
Larval zebrafish are increasingly common in biomedical and genetics research. A close study of their behavior requires tracking their body during swimming to test if genetic or neurological manipulations resulted in the expected or unexpected outcomes. This is my effort to share an automated tracker for larval zebrafish swimming in a dish which I wrote for my research. (To read more about my research please refer to this [news release](http://www.mccormick.northwestern.edu/news/articles/2017/09/neuroscientists-explore-the-risky-business-of-self-preservation.html?utm_source=internal-newsletter-09-20-17&utm_medium=email&utm_campaign=internal-newsletter&utm_content=email-position1&lipi=urn%3Ali%3Apage%3Ad_flagship3_profile_view_base_treasury%3BLZ1jOlhkT4W4E32VTWgHTg%3D%3D).)

## Data
The intention was to track multiple points on the body of the larval zebrafish swimming a dish. This dish could have one or multiple larval fish. The vidoes below show larval zebrafish responding to the presentation of a vibration (not visible or audible). The first dish only has one fish, while the second dish has 3. 

#### One fish
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/OneFish_crop.gif "One Fish")

#### Multiple fish
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/MultipleFish_crop.gif "Multiple Fish")

These vidoes were taken at 1000 frames per second. All animated gifs on this page were made with the following [matlab code](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/gifMovieMaker.m) which is available in the [VideoAndImages](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages) subdirectory of this repository. 

## Results
The images and videos below show the result of fish tracking accomplished with the code. 

#### One fish: centroid tracking
<img src="https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/OneFish_centroid.jpg" width="300">

#### Multiple fish: centroid tracking
<img src="https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/MultipleFish_centroid.jpg" width="300">

The centroid tracking is overlaid on a combined image of the first and last frame of the video. The color of the tracking is indicative of time. Later frames are plotted in a redder color. 

#### One fish: body tracking
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/OneFish_tracked_crop.gif "One Fish")

The following shows a zoom-in on the fish above. 

![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/OneFish_zoom.gif "One Fish")

#### Multiple fish: body tracking
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/VideoAndImages/MultipleFish_tracked_crop.gif "Multiple Fish")

The body tracking is overlaid in blue on the video of the swimming fish. The code tracks 19 points along the fish body. 
