#!C:\Perl\bin\perl.exe
################################################################################
# Modules
################################################################################
use v5.14;
use warnings;
use strict;
use POSIX qw(ceil);
use Data::Dumper;
use Hash::Util;

################################################################################
# Tunables
################################################################################
my $DEBUG = 1;
my $TERM_WIDTH = 80;

################################################################################
# Variable Declarations
################################################################################
my %clients;
my @uncatagorized;

################################################################################
# Pre-Execution Checks
################################################################################

die "No files specified.\n" unless @ARGV;

################################################################################
# Main Program
################################################################################
foreach my $arg (@ARGV)
{
	my @files = glob $arg;
	foreach my $file (@files)
	{
		open(FH, "<", $file) or die "Unable to open $file";
		while (<FH>)
		{
			# Strip newline and extra spaces
			chomp; s/\s+/ /go;

			# Support NCSA extended/combined log format described by
			# http://httpd.apache.org/docs/2.2/mod/mod_log_config.html
			my ($clientAddress,     $identdLogname, $username,
			    $localTime,         $httpRequest,   $statusCode,
			    $bytesSentToClient, $referer,       $userAgent) =
			    /^(\S+) (\S+) (\S+) \[(.+)\] \"(.+)\" (\S+) (\S+) \"(.*?)\" \"(.*?)\"/o;


			# Set to epoch by default
			my $date = 19700101;
			given ($localTime)
			{
				when (/^(\d{1,2})\/JAN\/(\d{4})/i) {
					$date = "$2" . "01" . "$1";
				}
				when (/^(\d{1,2})\/FEB\/(\d{4})/i) {
					$date = "$2" . "02" . "$1";
				}
				when (/^(\d{1,2})\/MAR\/(\d{4})/i) {
					$date = "$2" . "03" . "$1";
				}
				when (/^(\d{1,2})\/APR\/(\d{4})/i) {
					$date = "$2" . "04" . "$1";
				}
				when (/^(\d{1,2})\/MAY\/(\d{4})/i) {
					$date = "$2" . "05" . "$1";
				}
				when (/^(\d{1,2})\/JUN\/(\d{4})/i) {
					$date = "$2" . "06" . "$1";
				}
				when (/^(\d{1,2})\/JUL\/(\d{4})/i) {
					$date = "$2" . "07" . "$1";
				}
				when (/^(\d{1,2})\/AUG\/(\d{4})/i) {
					$date = "$2" . "08" . "$1";
				}
				when (/^(\d{1,2})\/SEP\/(\d{4})/i) {
					$date = "$2" . "09" . "$1";
				}
				when (/^(\d{1,2})\/OCT\/(\d{4})/i) {
					$date = "$2" . "10" . "$1";
				}
				when (/^(\d{1,2})\/NOV\/(\d{4})/i) {
					$date = "$2" . "11" . "$1";
				}
				when (/^(\d{1,2})\/DEC\/(\d{4})/i) {
					$date = "$2" . "12" . "$1";
				}
			}

			# Figure out which OS to tag as and normalize name
			given ($userAgent)
			{
				when (/Windows NT (\d\.\d)/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT $1"}->{$date} += 1;
				}
				when (/Windows XP/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT 5.1"}->{$date} += 1;
				}
				when (/Windows NT;/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT"}->{$date} += 1;
				}
				when (/Windows CE;/) {
					$clients{$clientAddress}->{"os"}->{"Windows CE"}->{$date} += 1;
				}
				when (/Windows 2000/) {
					$clients{$clientAddress}->{"os"}->{"Windows 2000"}->{$date} += 1;
				}
				when (/Windows 98/) {
					$clients{$clientAddress}->{"os"}->{"Windows 98"}->{$date} += 1;
				}
				when (/Windows 95/) {
					$clients{$clientAddress}->{"os"}->{"Windows 95"}->{$date} += 1;
				}
				when (/Windows (\d\.\d)/) {
					$clients{$clientAddress}->{"os"}->{"Windows $1"}->{$date} += 1;
				}
				when (/Windows Phone (\d\.\d);/) {
					$clients{$clientAddress}->{"os"}->{"Windows Phone $1"}->{$date} += 1;
				}
				when (/Android;/) {
					$clients{$clientAddress}->{"os"}->{"Android"}->{$date} += 1;
				}
				when (/Android\/(\d*?\.\d*?);/ || /Android\/(\d*?\.\d*?\.\d*?) /) {
					$clients{$clientAddress}->{"os"}->{"Android $1"}->{$date} += 1;
				}
				when (/iPad;/) {
					$clients{$clientAddress}->{"os"}->{"iPad"}->{$date} += 1;
				}
				when (/iPhone;/) {
					$clients{$clientAddress}->{"os"}->{"iPhone"}->{$date} += 1;
				}
				when (/X11;/ || /Linux;/) {
					$clients{$clientAddress}->{"os"}->{"Linux"}->{$date} += 1;
				}
				when (/Mac OS X (\d*?)\.(\d*?);/ || /Mac OS X (\d*?)_(\d*?)/) {
					$clients{$clientAddress}->{"os"}->{"Mac OS X $1.$2"}->{$date} += 1;
				}
				when (/bingbot/ || /Baiduspider/ || /MJ12bot/ || /SeznamBot/ ||
				      /CCBot/ || /Googlebot/ || /YandexBot/ || /Cliqzbot/ ||
				      /Yahoo! Slurp/ || /archive\.org_bot/ || /NerdyBot/ ||
				      /AhrefsBot/ || /Sogou web spider/ || /sukibot_heritrix/ ||
				      /MediaBot/ || /Mail\.RU_Bot/ || /DotBot/ || /Exabot/ ||
				      /DomainTunoCrawler/ || /rogerbot/ || /memoryBot/ ||
				      /Microsoft-WebDAV-MiniRedir/ || /AdsBot-Google/) {
					next; # ignore these
				}
				default {
					push @uncatagorized, $userAgent;
				}
			}

			# Figure out which browser to tag as and normalize name
			given ($userAgent)
			{
				when (/MSIE (\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"MSIE $1"}->{$date} += 1;
				}
				when ((/rv:11/) && (/Trident\/7.0/)) {
					$clients{$clientAddress}->{"browser"}->{"MSIE 11"}->{$date} += 1;
				}
				when (/Microsoft Internet Explorer\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"MSIE $1"}->{$date} += 1;
				}
				when (/Chrome\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Chrome $1"}->{$date} += 1;
				}
				when (/Firefox\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Firefox $1"}->{$date} += 1;
				}
				when (/Opera\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Opera $1"}->{$date} += 1;
				}
				when (/Opera (\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Opera $1"}->{$date} += 1;
				}
				when (/Safari\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Safari $1"}->{$date} += 1;
				}
				when (/bingbot/ || /Baiduspider/ || /MJ12bot/ || /SeznamBot/ ||
				      /CCBot/ || /Googlebot/ || /YandexBot/ || /Cliqzbot/ ||
				      /Yahoo! Slurp/ || /archive\.org_bot/ || /NerdyBot/ ||
				      /AhrefsBot/ || /Sogou web spider/ || /sukibot_heritrix/ ||
				      /MediaBot/ || /Mail\.RU_Bot/ || /DotBot/ || /Exabot/ ||
				      /DomainTunoCrawler/ || /rogerbot/ || /memoryBot/ ||
				      /Microsoft-WebDAV-MiniRedir/ || /AdsBot-Google/) {
					next; # ignore these
				}
				default {
					push @uncatagorized, $userAgent;
				}
			}
		}
		close(FH);
	}
}

# Make read-only to prevent programming errors during access from tampering with contents
# Without this, size of %clients can increase 10-fold if care isn't taken when accessing it below
Hash::Util::lock_hash_recurse(%clients);

sort_trends('Distribution By OS', 'os', 'osHash.txt');
sort_trends('Distribution By Browser', 'browser', 'browserHash.txt');

sub sort_trends
{
	# Quit unless correct number of arguments passed, else assign them
	die "ERROR: Wrong number of arguments in subroutine" unless @_ == 3;
	my $title = $_[0];
	my $field = $_[1];
	my $dumpfile = $_[2];

	# Allocate temporary variables
	my %workingHash;

	# Extract total counts
	foreach my $clientAddress ( keys %clients )
	{
		if(exists($clients{$clientAddress}->{$field}))
		{
			while ( my ($key, $value) = each %{ $clients{$clientAddress}->{$field} } )
			{
				foreach my $dateCount ( values %{ $value } )
				{
					$workingHash{$key} += $dateCount;
				}
			}
		}
	}

	# Pass a reference to hash to print_trend subroutine for printing
	print_trends("$title: ALL", \%workingHash);

	# Extract by date distribution for each unique $field
	foreach my $newkey ( sort keys %workingHash )
	{
		# Allocate temporary variables in this scope
		my %tempHash;

		# Extract total counts for each unique $field by date
		foreach my $clientAddress ( keys %clients )
		{
			if(exists($clients{$clientAddress}->{$field}) && exists($clients{$clientAddress}->{$field}->{$newkey}))
			{
				while ( my ($key, $value) = each %{ $clients{$clientAddress}->{$field}->{$newkey} } )
				{
					$tempHash{$key} += $value;
				}
			}
		}

		# Pass a reference to hash to print_trend subroutine for printing
		print_trends("$title: $newkey", \%tempHash);
	}

	# Save working hash structure to text file if debugging is set
	if ($DEBUG)
	{
		print "DEBUG: data structure dumpfile	= $dumpfile\n";
		open my $fh, ">", "$dumpfile" or die $?;
		print $fh Data::Dumper->Dump([\%workingHash]);
		close $fh;
	}
}

sub print_trends
{
	# Quit unless correct number of arguments passed, else assign them
	die "ERROR: Wrong number of arguments in subroutine" unless @_ == 2;
	my $title = $_[0];
	my %refToHash = %{$_[1]};

	# Allocate temporary variables
	my $lftLongestKey = 0;
	my $rgtMaxValue = 0;
	my $ctrUsableCols;
	my $divisor;

	# Iterate through resulting dataset to strlen of text and biggest value
	while ( my ($key, $value) = each %refToHash )
	{
		$lftLongestKey = length($key) unless length($key) < $lftLongestKey;
		$rgtMaxValue = $value unless $value < $rgtMaxValue;
	}

	# Calc columns by subtracting TERM_WIDTH w/longest key, 3 (printf whitespace), and longest value
	$ctrUsableCols = $TERM_WIDTH - $lftLongestKey - 3;
	$ctrUsableCols -= length($rgtMaxValue) >= length("COUNT") ? length($rgtMaxValue) : length("COUNT");

	# Calc integer divisor based off max value divided by usable columns
	$divisor = $rgtMaxValue > $ctrUsableCols ? POSIX::ceil($rgtMaxValue / $ctrUsableCols) : 1;

	# TODO: Print the below to a file as well and mention in debug
	# Print header
	printf("%s\n", "=" x $TERM_WIDTH);
	printf("%-${TERM_WIDTH}s\n", $title);
	printf("%s\n", "=" x $TERM_WIDTH);
	printf("%${lftLongestKey}s  %-.${ctrUsableCols}s %s\n",
		("VALUE", "--- DISTRIBUTION " . "-" x ${ctrUsableCols}), "COUNT");

	# Print data
	foreach my $key ( sort keys %refToHash )
	{
		printf("%${lftLongestKey}s |%-${ctrUsableCols}s %s\n",
			$key, ("@" x int $refToHash{$key} / $divisor), $refToHash{$key});
	}

	# Print resulting values if debugging is set
	if ($DEBUG)
	{
		print "DEBUG: lftLongestKey		= $lftLongestKey\n";
		print "DEBUG: rgtMaxValue		= $rgtMaxValue\n";
		print "DEBUG: ctrUsableCols		= $ctrUsableCols\n";
		print "DEBUG: divisor			= $divisor\n";
	}
}

if ($DEBUG)
{
	# Dump the processed data structure into a file for review
	open DEBUGFILE, ">", "DEBUG.txt" or die $?;
	print DEBUGFILE Data::Dumper->Dump([\%clients]);
	close DEBUGFILE;

	# Dump the uncatagorized data into a file for review
	open UNCATAGORIZED, ">", "UNCATAGORIZED.txt" or die $?;
	foreach (@uncatagorized) { print UNCATAGORIZED "$_\n"; }
	close UNCATAGORIZED;
}
