#!C:\Perl\bin\perl.exe
################################################################################
# Modules
################################################################################
#use v5.00;
use warnings;
use strict;
use POSIX qw(ceil);
use Data::Dumper;
use Hash::Util;

################################################################################
# Tunables
################################################################################
my $DEBUG = 0;                # 0 by default, any other value to enable
my $TERM_WIDTH = 80;          # 80 by default, 80x25 is standard cmd.exe size
my $DATE_FORMAT = "YYYYMMDD"; # YYYYQQ by default, valid values are listed below

################################################################################
# Constants
################################################################################
my @VALID_DATE_FORMATS = ("YYYYMMDD", "YYYYMM", "YYYYQQ", "YYYY");

################################################################################
# Variable Declarations
################################################################################
my %clients;
my @uncatagorized;

################################################################################
# Pre-Execution Checks
################################################################################

die "No files specified.\n" unless @ARGV;

my %DATE_FORMAT_CHECK = map { $_ => 1 } @VALID_DATE_FORMATS;
die "Invalid Date Format Specified: \"$DATE_FORMAT\" not valid" unless exists($DATE_FORMAT_CHECK{$DATE_FORMAT});

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


			my $date;
			if ($localTime =~ /^(\d{1,2})\/(\w{3})\/(\d{4})/i)
			{
				# Fill temporary variables based off each position pattern matched above
				my ($day, $month, $year) = ($1, $2, $3);

				# For all cases, set starting date. For YYYY case, this is it.
				$date = "$year";

				# For the by quarter-YYYYQQ case, append the quarter based on month
				if ($DATE_FORMAT =~ /^YYYYQQ$/)
				{
					for ($month)
					{
						if    (/JAN/i) { $date .= "Q1"; }
						elsif (/FEB/i) { $date .= "Q1"; }
						elsif (/MAR/i) { $date .= "Q1"; }
						elsif (/APR/i) { $date .= "Q2"; }
						elsif (/MAY/i) { $date .= "Q2"; }
						elsif (/JUN/i) { $date .= "Q2"; }
						elsif (/JUL/i) { $date .= "Q3"; }
						elsif (/AUG/i) { $date .= "Q3"; }
						elsif (/SEP/i) { $date .= "Q3"; }
						elsif (/OCT/i) { $date .= "Q4"; }
						elsif (/NOV/i) { $date .= "Q4"; }
						elsif (/DEC/i) { $date .= "Q4"; }
					}
				}

				# For the by month cases, append the numeric value of the month
				if ($DATE_FORMAT =~ /^YYYYMM$/ || $DATE_FORMAT =~ /^YYYYMMDD$/)
				{
					for ($month)
					{
						if    (/JAN/i) { $date .= "01"; }
						elsif (/FEB/i) { $date .= "02"; }
						elsif (/MAR/i) { $date .= "03"; }
						elsif (/APR/i) { $date .= "04"; }
						elsif (/MAY/i) { $date .= "05"; }
						elsif (/JUN/i) { $date .= "06"; }
						elsif (/JUL/i) { $date .= "07"; }
						elsif (/AUG/i) { $date .= "08"; }
						elsif (/SEP/i) { $date .= "09"; }
						elsif (/OCT/i) { $date .= "10"; }
						elsif (/NOV/i) { $date .= "11"; }
						elsif (/DEC/i) { $date .= "12"; }
					}
				}

				# For the full date string case, also append the two digit numeric day
				if ($DATE_FORMAT =~ /^YYYYMMDD$/)
				{
					$date .= sprintf "%02d", $day;
				}
			}
			else
			{
				# If unable to pattern match date, set to epoch start as a fallback
				$date = "19700101";
			}

			# Figure out which OS to tag as and normalize name
			for ($userAgent)
			{
				if    (/Windows NT (\d\.\d)/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT $1"}->{$date} += 1;
				}
				elsif (/Windows XP/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT 5.1"}->{$date} += 1;
				}
				elsif (/Windows NT;/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT"}->{$date} += 1;
				}
				elsif (/Windows CE;/) {
					$clients{$clientAddress}->{"os"}->{"Windows CE"}->{$date} += 1;
				}
				elsif (/Windows 2000/) {
					$clients{$clientAddress}->{"os"}->{"Windows 2000"}->{$date} += 1;
				}
				elsif (/Windows 98/) {
					$clients{$clientAddress}->{"os"}->{"Windows 98"}->{$date} += 1;
				}
				elsif (/Windows 95/) {
					$clients{$clientAddress}->{"os"}->{"Windows 95"}->{$date} += 1;
				}
				elsif (/Windows (\d\.\d)/) {
					$clients{$clientAddress}->{"os"}->{"Windows $1"}->{$date} += 1;
				}
				elsif (/Windows Phone (\d\.\d);/) {
					$clients{$clientAddress}->{"os"}->{"Windows Phone $1"}->{$date} += 1;
				}
				elsif (/Android;/) {
					$clients{$clientAddress}->{"os"}->{"Android"}->{$date} += 1;
				}
				elsif (/Android\/(\d*?\.\d*?);/ || /Android\/(\d*?\.\d*?\.\d*?) /) {
					$clients{$clientAddress}->{"os"}->{"Android $1"}->{$date} += 1;
				}
				elsif (/iPad;/) {
					$clients{$clientAddress}->{"os"}->{"iPad"}->{$date} += 1;
				}
				elsif (/iPhone;/) {
					$clients{$clientAddress}->{"os"}->{"iPhone"}->{$date} += 1;
				}
				elsif (/X11;/ || /Linux;/) {
					$clients{$clientAddress}->{"os"}->{"Linux"}->{$date} += 1;
				}
				elsif (/Mac OS X (\d*?)\.(\d*?);/ || /Mac OS X (\d*?)_(\d*?)/) {
					$clients{$clientAddress}->{"os"}->{"Mac OS X $1.$2"}->{$date} += 1;
				}
				elsif (/bingbot/ || /Baiduspider/ || /MJ12bot/ || /SeznamBot/ ||
				      /CCBot/ || /Googlebot/ || /YandexBot/ || /Cliqzbot/ ||
				      /Yahoo! Slurp/ || /archive\.org_bot/ || /NerdyBot/ ||
				      /AhrefsBot/ || /Sogou web spider/ || /sukibot_heritrix/ ||
				      /MediaBot/ || /Mail\.RU_Bot/ || /DotBot/ || /Exabot/ ||
				      /DomainTunoCrawler/ || /rogerbot/ || /memoryBot/ ||
				      /Microsoft-WebDAV-MiniRedir/ || /AdsBot-Google/) {
					next; # ignore these
				}
				else {
					push @uncatagorized, $userAgent;
				}
			}

			# Figure out which browser to tag as and normalize name
			for ($userAgent)
			{
				if    (/MSIE (\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"MSIE $1"}->{$date} += 1;
				}
				elsif ((/rv:11/) && (/Trident\/7.0/)) {
					$clients{$clientAddress}->{"browser"}->{"MSIE 11"}->{$date} += 1;
				}
				elsif (/Microsoft Internet Explorer\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"MSIE $1"}->{$date} += 1;
				}
				elsif (/Chrome\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Chrome $1"}->{$date} += 1;
				}
				elsif (/Firefox\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Firefox $1"}->{$date} += 1;
				}
				elsif (/Opera\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Opera $1"}->{$date} += 1;
				}
				elsif (/Opera (\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Opera $1"}->{$date} += 1;
				}
				elsif (/Safari\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Safari $1"}->{$date} += 1;
				}
				elsif (/bingbot/ || /Baiduspider/ || /MJ12bot/ || /SeznamBot/ ||
				      /CCBot/ || /Googlebot/ || /YandexBot/ || /Cliqzbot/ ||
				      /Yahoo! Slurp/ || /archive\.org_bot/ || /NerdyBot/ ||
				      /AhrefsBot/ || /Sogou web spider/ || /sukibot_heritrix/ ||
				      /MediaBot/ || /Mail\.RU_Bot/ || /DotBot/ || /Exabot/ ||
				      /DomainTunoCrawler/ || /rogerbot/ || /memoryBot/ ||
				      /Microsoft-WebDAV-MiniRedir/ || /AdsBot-Google/) {
					next; # ignore these
				}
				else {
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

# With source data read only, call dumping them to a file if $DEBUG is set
if ($DEBUG) { debug_dump_hash("DEBUG.txt", \%clients); }
if ($DEBUG) { debug_dump_array("UNCATAGORIZED.txt", \@uncatagorized); }

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
	if ($DEBUG) { debug_dump_hash("$dumpfile", \%workingHash); }
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

sub debug_dump_array
{
	# Quit unless correct number of arguments passed, else assign them
	die "ERROR: Wrong number of arguments in subroutine" unless @_ == 2;
	my $dumpfile   = $_[0];
	my @refToArray = @{$_[1]};

	print "DEBUG: array dumpfile		= $dumpfile\n";
	open my $fh, ">", "$dumpfile" or die $?;
	foreach (@refToArray) { print $fh "$_\n"; }
	close $fh;
}

sub debug_dump_hash
{
	# Quit unless correct number of arguments passed, else assign them
	die "ERROR: Wrong number of arguments in subroutine" unless @_ == 2;
	my $dumpfile  = $_[0];
	my %refToHash = %{$_[1]};

	print "DEBUG: data structure dumpfile	= $dumpfile\n";
	open my $fh, ">", "$dumpfile" or die $?;
	print $fh Data::Dumper->Dump([\%refToHash]);
	close $fh;
}
