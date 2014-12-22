#!C:\Perl\bin\perl.exe
use v5.14;
use warnings;
use strict;
use Data::Dumper;

my %clients;

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
					say("No OS: " . $userAgent);
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
					say("No Browser: " . $userAgent);
				}
			}
		}
		close(FH);
	}
}

open(DEBUGFILE, ">", "DEBUG.TXT") || die $?;
print DEBUGFILE Data::Dumper->Dump([\%clients]);
close(DEBUGFILE);
