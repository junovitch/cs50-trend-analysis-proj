#!C:\Perl\bin\perl.exe
################################################################################
# Modules
################################################################################
use v5.14;
use warnings;
use strict;
use Data::Dumper;

################################################################################
# Constants
################################################################################
my $TERM_WIDTH = 80;

################################################################################
# Variable Declarations
################################################################################
my %clients;
my @uncatagorized;

die "No files specified.\n" unless @ARGV;
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

			# Figure out which OS to tag as and normalize name
			given ($userAgent)
			{
				when (/Windows NT (\d\.\d)/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT $1"} += 1;
				}
				when (/Windows XP/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT 5.1"} += 1;
				}
				when (/Windows NT;/) {
					$clients{$clientAddress}->{"os"}->{"Windows NT"} += 1;
				}
				when (/Windows CE;/) {
					$clients{$clientAddress}->{"os"}->{"Windows CE"} += 1;
				}
				when (/Windows 2000/) {
					$clients{$clientAddress}->{"os"}->{"Windows 2000"} += 1;
				}
				when (/Windows 98/) {
					$clients{$clientAddress}->{"os"}->{"Windows 98"} += 1;
				}
				when (/Windows 95/) {
					$clients{$clientAddress}->{"os"}->{"Windows 95"} += 1;
				}
				when (/Windows (\d\.\d)/) {
					$clients{$clientAddress}->{"os"}->{"Windows $1"} += 1;
				}
				when (/Windows Phone (\d\.\d);/) {
					$clients{$clientAddress}->{"os"}->{"Windows Phone $1"} += 1;
				}
				when (/Android;/) {
					$clients{$clientAddress}->{"os"}->{"Android"} += 1;
				}
				when (/Android\/(\d*?\.\d*?);/ || /Android\/(\d*?\.\d*?\.\d*?) /) {
					$clients{$clientAddress}->{"os"}->{"Android $1"} += 1;
				}
				when (/iPad;/) {
					$clients{$clientAddress}->{"os"}->{"iPad"} += 1;
				}
				when (/iPhone;/) {
					$clients{$clientAddress}->{"os"}->{"iPhone"} += 1;
				}
				when (/X11;/ || /Linux;/) {
					$clients{$clientAddress}->{"os"}->{"Linux"} += 1;
				}
				when (/Mac OS X (\d*?)\.(\d*?);/ || /Mac OS X (\d*?)_(\d*?)/) {
					$clients{$clientAddress}->{"os"}->{"Mac OS X $1.$2"} += 1;
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
					$clients{$clientAddress}->{"browser"}->{"MSIE $1"} += 1;
				}
				when ((/rv:11/) && (/Trident\/7.0/)) {
					$clients{$clientAddress}->{"browser"}->{"MSIE 11"} += 1;
				}
				when (/Microsoft Internet Explorer\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"MSIE $1"} += 1;
				}
				when (/Chrome\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Chrome $1"} += 1;
				}
				when (/Firefox\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Firefox $1"} += 1;
				}
				when (/Opera\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Opera $1"} += 1;
				}
				when (/Opera (\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Opera $1"} += 1;
				}
				when (/Safari\/(\d*?)\./) {
					$clients{$clientAddress}->{"browser"}->{"Safari $1"} += 1;
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

# XXX FUNCTIONALIZE THIS PART WITH PRINTING SPT
my %browserHash;
foreach my $clientAddress ( keys %clients)
{
	while ( my ($key, $value) = each %{ $clients{$clientAddress}->{"browser"} } )
	{
		$browserHash{$key} += $value;
	}
}

## XXX EXPERIMENTAL
## Dtrace like printing
my %osHash;
foreach my $clientAddress ( keys %clients)
{
	while ( my ($key, $value) = each %{ $clients{$clientAddress}->{"os"} } )
	{
		$osHash{$key} += $value;
	}
}

## Get string length of longest key
my $llength = 0;
foreach my $key ( keys %osHash )
{
	$llength = length($key) unless length($key) < $llength;
}
print "DEBUG: Longest llength is $llength\n";

## Get max value of biggest value
my ($rlength, $rTotal) = 0;
foreach my $value ( values %osHash )
{
	$rlength = $value unless $value < $rlength;
	#$rTotal += $value;
}
print "DEBUG: Longest rlength is $rlength\n";

## TERM_WIDTH - string length - 1 for space is the max usable
my $rWidth = $TERM_WIDTH - $llength;

## Say it's 60 columns, calc biggest value that divides into it
my $divisor = int $rlength / $rWidth;
print ("DEBUG: Divisor is: $divisor\n");

# Print Header
printf("%${llength}s  %-.${rWidth}s %s\n",
	("VALUE", "--- DISTRIBUTION " . "-" x ${rWidth}), "COUNT");

# Print Data
foreach my $key ( sort keys %osHash )
{
	#print("$key |" . ("@" x int $value / $divisor) . "$value\n");
	printf("%${llength}s |%-${rWidth}s %s\n",
		$key, ("@" x int $osHash{$key} / $divisor), $osHash{$key});
}


# Dump the processed data structure into a file for review
open(DEBUGFILE, ">", "DEBUG.TXT") || die $?;
print DEBUGFILE Data::Dumper->Dump([\%clients]);
close(DEBUGFILE);
open(OSDEBUG, ">", "OSDEBUG.TXT") || die $?;
print OSDEBUG Data::Dumper->Dump([\%osHash]);
close(OSDEBUG);
open(BROWSER, ">", "BROWSER.TXT") || die $?;
print BROWSER Data::Dumper->Dump([\%browserHash]);
close(BROWSER);

# Dump the uncatagorized data into a file for review
open(UNCATAGORIZED, ">", "UNCATAGORIZED.TXT") || die $?;
foreach (@uncatagorized) { print UNCATAGORIZED "$_\n"; }
close(UNCATAGORIZED);
