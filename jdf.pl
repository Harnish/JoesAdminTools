#!/usr/bin/perl
#################################################################################################
#	Author:		Joseph Harnish								#
#	Date:		2/2/2007								#
#												#	
#	Description:	This is my mod of df and bdf so I can get the functionality out of it   #
#			that I want insted of each *nix vendor's junk.				#
#################################################################################################
use strict;

my $human = 0;
my $search = '';
my $final_size = '';
##############################
#  Get command line options  #
##############################
foreach my $opts (@ARGV){
	if ($opts eq '-h'){
		$human = 1;
	} elsif ($opts eq '-?'){
		Usage();
	} elsif ($opts eq '-M'){
		$final_size = 'M';
	} elsif ($opts eq '-K'){
		$final_size = 'K';
	} elsif ($opts eq '-G'){
		$final_size = 'G';
	} else {
		$search = $opts;
	}

}
my $return_from_server;
###############################################
# Get server type and use appropriate command #
###############################################
my $server_type = `uname`;
chomp($server_type);  #  Removes the new line

if($server_type eq 'HP-UX'){
#	print "Found HP-UX\n";
	$return_from_server = `bdf -l`;
} elsif ($server_type eq 'Linux'){
#	print "Found Linux\n";
	$return_from_server = `df -l`;
} else {
	print "I am $server_type and I am not supported yet!!\n";
}

#################################################
# Process the output of the server's command	#
#################################################	
my @sizes = (0, 0, 0, 0, 0, 0);
my @server_mount_data = split(/\n/, $return_from_server);
my @output = ();
for(my $i = 0; $i <= $#server_mount_data; $i++){
	my @mount_split = split(/\s+/, $server_mount_data[$i]);
	if($#mount_split == 0){
		####################################################
		#  If this is true the line is split to 2 lines    #
		#  this brings it up to on line but > than 80 cols #
		####################################################
                $i++;
                $server_mount_data[$i] =~ s/^\s+//;
                my @temp_arr = split(/\s+/, $server_mount_data[$i]);
                push(@mount_split, @temp_arr);
	}
	#1-3
	if($human){
		####################################################
		#  This converts the different columns into human  #
		#  readable numbers				   #
		####################################################
		if($i == 0){
			$mount_split[1] = "Total";	
		} else { 
			$mount_split[1] = ConvertToHuman($mount_split[1]);
			$mount_split[2] = ConvertToHuman($mount_split[2]);
			$mount_split[3] = ConvertToHuman($mount_split[3]);
		}
	}

	#################################################
	# Search for any strings passed to this script  #
	#################################################
	my $found = 0;
	for (my $i = 0; $i < 6; $i++){
		$found = 1 if($mount_split[$i] =~ m/$search/);
		$sizes[$i] = length($mount_split[$i]) +2 if($sizes[$i] < length($mount_split[$i]) +2);      	
        }
	next if ((! $found) && ((! $human) || ($i > 0) ));
	$output[$i] = \@mount_split;
}

#########################################
# Print the final output		#
#########################################
foreach my $line (@output){
	my $i = 0;
	next if($#$line < 5);
	foreach my $val (@$line){
		print $val;
		for(my $j = 0; $j < ($sizes[$i] - length($val)); $j++){
			print " ";
		}
		$i++;
	}
	print "\n";
}


#################################################################
# This function could be a recursive funtion with a dictionary	#
# but with a current max of 3 iterations really wasn't required #
# 								#
# This takes one number in k and converts it to the highest 	#
# denomination 							#
################################################################# 
sub ConvertToHuman {
	my $number = shift;
	my $return_number = $number;
	if(($number / 1024 > .89) && ($final_size ne 'K')){
		#megs
		$return_number = $number/1024;
		$return_number = ((int($return_number * 100))/100);
		$return_number .= 'M';
		if((($number / (1024 * 1024)) > .89) && ($final_size ne 'M')){
			#gig
			$return_number = $number / (1024 * 1024);
			$return_number = ((int($return_number * 100))/100);
			$return_number .= 'G';
			if((($number / (1024 * 1024 * 1024)) > .89) && ($final_size ne 'G')){
                        #TB
                                $return_number = $number / (1024 * 1024 * 1024);
                                $return_number = ((int($return_number * 100))/100);
                                $return_number .= 'T';                                                                                            
			}
                }
	}
	
	while (length($return_number) < 7){
		$return_number = " $return_number";
	}
	return $return_number;
}


#################################################################
# This function prints the usage page and exits.  Not too much  #
#  fun.								#
#################################################################

sub Usage {

print <<EODUMP;

jdf

	Usage: jdf [options] [search]

	-h 	Human readble

	-K      Return KB as the highest size denomination	

	-M 	Return MB as the highest size denomination

	-G 	Return GB as the highest size denomination

	-?	Prints this page

	
EODUMP

exit;

}
