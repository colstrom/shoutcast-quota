#!/usr/bin/env perl

###########################################################
# SCQuota, a ShoutCast quota tracking / enforcing script. #
###########################################################
#
# Copyright 2006-2011 Chris Olstrom
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
