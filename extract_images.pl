#!/usr/bin/perl

sub extract_img  {

my ($mp4name) = @_;

#determine if Front or Rear camera is used
$mp4name =~ /^REC_.*(F|R)\.MP4/;
my $FR = $1;

#get the prefix if the file
$mp4name =~ /^REC_(.*)\.MP4/;
my $prefix = $1;

#remove and recreate temporary subtitle file containing GPS and gsensor data
unlink 'tmp.srt';
my $srtcmd = "avconv -nostats -loglevel 0 -i $mp4name -an -vn -scodec copy tmp.srt";
system($srtcmd);

#new line separator
local $/ = chr(0);

open my $fh, '<', 'tmp.srt' or die;

$n=0;

while (my $row = <$fh>) {
	chomp $row;

#gsensor frames each 100ms and gps frames every second
#check from NMEA RMC sentence to detect GPS frame
	if ($row =~ /^[A-Z](.*RMC.*)\*/) {
		$n++;
		my $tocsum = $1;

		my ($sentence,$time,$status,$lat,$latNS,$lon,$lonWE,$speedKN,$orientation,$date,$magnet,$mag2,$csum) = split (/,/, $row);

		$lat =~ s/^([0-9][0-9])(.*)/$1 $2/;
		$lon =~ s/^([0-9][0-9][0-9])(.*)/$1 $2/;
		$time =~ s/^([0-9]{2})([0-9]{2})([0-9]{2})/$1:$2:$3/;
		$date =~ s/^([0-9]{2})([0-9]{2})([0-9]{2})$/20$3:$2:$1/;

#for rear view, we add 180° to the orientation
		if ($FR eq 'R') {
			$orientation =~ /^([0-9]+)\.([0-9]+)/;
			$orientation = sprintf("%03u.%02u",($1+180)%360,$2);
		}

#calculate NMEA checksum
		$csum =~ s/.*\*([0-9A-F][0-9A-F]).*\r\n+/$1/;
		my $uff; $uff ^= $_ for unpack 'C*', $tocsum;
		my $calccsum = sprintf "\U%x", $uff;
		
		if ($csum eq $calccsum) {
			my $fn = sprintf("%s/%s_%02d.jpg",$FR,$prefix,$n);
			print "$fn\n";
#extract 1 frame as jpg each second
			my $extractcmd = "avconv -nostats -loglevel 0 -noaccurate_seek -ss $n -i $mp4name -frames:v 1 -f image2 'img/".$fn."'";
			system ($extractcmd);

#tag the jpg file with EXIF GPS data
			my $exifcmd = "exiftool -q -overwrite_original -exif:datetimeoriginal='$date $time' -exif:gpslatitude='$lat' -exif:gpslatituderef=$latNS -exif:gpslongitude='$lon' -exif:gpslongituderef=$lonWE -exif:gpsimgdirection=$orientation -exif:gpsstatus#=$status -exif:gpstimestamp=$time -exif:gpsdatestamp=$date img/$fn";
			system ($exifcmd);
			
		} else {
			print "Invalid GPS checksum\n";
		}


	}
}
}


chdir('/media/Downloads/dashcam');
my $data_dir='.'; opendir( DATA_DIR, $data_dir) || die "Cannot open $data_dir\n";
my @files = sort readdir(DATA_DIR);

while ( my $name = shift @files ) {
        if ($name =~ /^REC_.*(F|R).MP4/) {
#                print "$name : $1\n";
		extract_img($name);

        }
}


$ENV{MAPILLARY_SIGNATURE_HASH}='';
$ENV{MAPILLARY_PERMISSION_HASH}='';
$ENV{MAPILLARY_USERNAME}='';
$ENV{MAPILLARY_EMAIL}='';
$ENV{MAPILLARY_PASSWORD}='';


my $dedupcmd = "/usr/bin/python /home/pi/dashcam/map/mapillary_tools/python/remove_duplicates.py /media/Downloads/dashcam/img/F/ /media/Downloads/dashcam/dup/";
print "$dedupcmd\n";
#system ($dedupcmd);

my $upcmd = "/home/pi/dashcam/mapillary_tools/python/upload_with_authentication.py /home/pi/dashcam/img/";
print "$upcmd\n";
#system ($upcmd);

