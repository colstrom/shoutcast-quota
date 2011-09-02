#!/usr/bin/env perl

###########################################################
# SCQuota, a ShoutCast quota tracking / enforcing script. #
###########################################################
#
# Copyright (C) 2006 Chris Olstrom
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

my %config;
$config{'download_size'} = '32kb';
$config{'staff_contact'} = 'root';

# The URL listeners connect via.
my @server_url = (
	'http://radio.onetrix.net:19342/listen.pls',	# 0
);

# The bitrate allocated for this server.
my @server_quota = (
	42,						# 0
);

# Who to contact regarding this server?
my @server_contact = (
	'siliconviper',					# 0
);

open(report,">report.txt");
print report `date`;

my $quota_violations = 0;

for ( my $iCounter = 0; $iCounter < @server_url; $iCounter++ ) {

	# Download snippet, and report details.
	
	my @command_output = `icecream --stop=$config{'download_size'} $server_url[$iCounter] && mp3info -x *.mp3 2> /dev/null | head -n 3 | tail -n 1`;
	
	
	
	# Extract the bitrate from the garbage.
	
	my $bitrate_string = $command_output[2];
	chomp($bitrate_string);
	$bitrate_string =~ m/Audio:       (.+) kbps(.+)/i;
	
	
	
	# Report results.
	
	my $status;
	if ( $1 > $server_quota[$iCounter] ) {
		$status = 'HI';
	} elsif ( $1 < $server_quota[$iCounter] ) {
		$status = 'LO';
	} else {
		$status = 'EQ';
	}
	my $status_message = "[ $status ] Server ID $iCounter ( $server_url[$iCounter] ) : Bitrate ( $1 ) / Quota ( $server_quota[$iCounter] )";
	
	print "\n$status_message\n";
	print report "$status_message\n";
	if ( $status eq 'HI' ) {
		system("tail -n 1 report.txt > scquota-temp.$iCounter");
		system("mail $server_contact[$iCounter] -s \"Shoutcast Quota Exceeded\" < scquota-temp.$iCounter");
		system("rm -f scquota-temp.$iCounter");
		$quota_violations++;
	}
}

close(report);

system("mail $config{'staff_contact'} -s \"SCQuota - `date` - $quota_violations violations\" < report.txt");
system("rm -f report.txt");
