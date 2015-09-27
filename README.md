# PupilTest_iOS
Detecting size of pupil on video
-------------
The algorithm:|
------------- |
1. Load the source image from video|
2. Invert it |
3. Convert to grayscale |
4. Convert to binary image by thresholding it |
5. Find all blobs |
6. Remove noise by filling holes in each blob |
7. Get blob which is big enough and has round shape |

