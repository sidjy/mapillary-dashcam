# mapillary-dashcam

Some scripts to be used with mapillary-tools to help uploading from Thinkware F770 dashcam

Prerequisites :
- mapillary_tools (see https://github.com/mapillary/mapillary_tools)
- perl
- exiftool
- avconv (see libav-tools on debian)

Usage :
- Copy all MP4 files from your dashcam to a (large) directory
- Edit and change $video_path (and create $video_path/img/F/ and $video_path/img/R/ subdirectories)
- Launch and wait : you will get geotagged images that can be uploaded to mapillary
