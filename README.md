# Larval Zebrafish Tracker
Tracks points on the bodies of swimming larval zebrafish for kinematics.

## Motivation
Larval zebrafish are increasingly common in biomedical and genetics research. A close study of their behavior requires tracking their body during swimming to test if genetic or neurological manipulations resulted in the expected or unexpected outcomes. This is my effort to share an automated tracker for larval zebrafish swimming in a dish which I wrote for my research. <sub><sup>(To read more about my research please refer to this recent [news release](http://www.mccormick.northwestern.edu/news/articles/2017/09/neuroscientists-explore-the-risky-business-of-self-preservation.html?utm_source=internal-newsletter-09-20-17&utm_medium=email&utm_campaign=internal-newsletter&utm_content=email-position1&lipi=urn%3Ali%3Apage%3Ad_flagship3_profile_view_base_treasury%3BLZ1jOlhkT4W4E32VTWgHTg%3D%3D).)</sup></sub>

## Data
The intention was to track multiple points on the body of the larval zebrafish swimming a dish. This dish could have one or multiple larval fish. The vidoes below show larval zebrafish responding to the presentation of a vibration (not visible or audible). The first dish only has one fish, while the second dish has 3. 

#### One fish
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/OneFish_crop.gif "One Fish")

#### Multiple fish
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/MultipleFish_crop.gif "Multiple Fish")

These vidoes were taken at 1000 frames per second.

## Results
The images and videos below show the result of fish tracking accomplished with the code. 

#### One fish: centroid tracking
<img src="https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/OneFish_centroid.jpg" width="300">

#### Multiple fish: centroid tracking
<img src="https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/MultipleFish_centroid.jpg" width="300">

#### One fish: body tracking
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/OneFish_tracked_crop.gif "One Fish")

#### Multiple fish: body tracking
![alt text](https://github.com/MiningMyBusiness/LarvalZebrafishTracker/raw/master/MultipleFish_tracked_crop.gif "Multiple Fish")
