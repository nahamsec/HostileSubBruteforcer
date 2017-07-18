#!/usr/bin/perl

=head1 NAME
HostileSubDomainBruteForcer
=head1 SYNOPSIS
###############################################
Pure subdomain bruteforcer:
Will check and see if host is pointing to AWS
Alerts if a subdomain returns 404 so you can
manually check and see if it's hosted on a
3rd party website and if they are registered
properly or not.
Based on the work done by:
Author : Behrouz Sadeghipour
Email  : bensadeghi@gmail.chom
Twitter: @NahamSec
http:://github.com/nahamsec
Ported to Perl
Author : geekspeed
Email  : geekspeed@gmail.com
Twitter: @g33kspeed
###############################################
=cut
use Getopt::Long;
use Term::ANSIColor;
use Net::DNS;
use LWP::UserAgent;
use LWP::Simple;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Term::ProgressBar;
# Defines
my $VER = "0.001a";
my $ticker = 1;
my $names = "names.txt";
my @SECONDSTAGEA;
my @SECONDSTAGEC;
my $verbose = 0;
my $quiet = 0;
my $pretty = 0;
my $output = undef;
my $userAgent = "useragents.txt";
my $nameserver = "ns.txt";
my $help = 0;
my $resolver = Net::DNS::Resolver->new();
### Hashtable of interesting responses ###
my %RESPONSE;
$RESPONSE{'heroku'} = "there is no app configured at that hostname";
$RESPONSE{'aws'} = "NoSuchBucket";
$RESPONSE{'squarespace'} = "No Such Account";
$RESPONSE{'GitHub'} = "here isn't a GitHub Pages site here";
$RESPONSE{'Shopify'} = "Sorry, this shop is currently unavailable";
$RESPONSE{'Tumblr'} = "There's nothing here.";
$RESPONSE{'WpEngine'} = "The site you were looking for couldn't be found";
###


# Get options
GetOptions( 'verbose' => \$verbose, 'quiet' => sub { $verbose = 0; $quiet=1; }, "pretty" => \$pretty, "output=s" => \$output, "ns" => \$nameserver, "names=s" => \$names, "useragent=s" => \$userAgent, 'help' => sub { usage(); });
my $domain = shift;
my $mech = new WWW::Mechanize;
if($output) {
	open (FH,">$output") or die "Cannot open: $!\n";
	print FH "Scan: $domain ";
	print FH localtime;
	print FH "\n";
}
if($pretty){
	if(!$output){
		die "--pretty requires output file";
	}
	$pretty = 1;
	$quiet = 1;
}
# Prep name servers #
open (NS, $nameserver) or die "Cannot open $nameserver: $!\n";
my @NS = <NS>;
close(NS);

# Prep names #
open (NAMES, $names) or die "Cannot open $names: $!\n";
my @NAMES = <NAMES>;
my $MX = undef;
my $MAX = @NAMES;
if($MAX > 1000){
	$MX = $MAX/1000;
}elsif($MAX < 1000 && $MAX > 100){
	$MX = $MAX/100;
}else{
	$MX = $MAX;
}
$MAX=$MX;
close(NAMES);

#Prep User Agents #
open (UA, $userAgent) or die "Cannot open $userAgent: $!\n";
my @UA = <UA>;
close (UA);

#progress
my $progress = Term::ProgressBar->new($MAX) if $pretty;

brute($domain);
secondstage();

sub brute {
	my $domain = shift;
	$ns = give_me_a_nameserver();
	$resolver->nameservers($ns);
	foreach $n (@NAMES){
		chomp($n);
		my $host = "$n.$domain";
		my $reply = $resolver->query($host);
		if(1000 % $ticker == 0){
			$progress->update($_) if $pretty;
		}
		$ticker++;
		if($reply){
			my $rr = ($reply->answer)[0];
			if($rr->type eq "A"){
				my $msg = "$host\t\t\t".$rr->address;
				spit(0,$msg,1);
			}elsif($rr->type eq "CNAME"){
				my $msg = "$host\t\t".$rr->name." => ".$rr->cname;
				spit(0,$msg,1);
				push(@SECONDSTAGEC,$rr->name);
			}

		}else{
			if($resolver->errorstring =~ 'NOERROR'){
				my $msg = "[$domain] Resolver found possible sub: $host";
				spit(1,$msg,0);
			}else{
				my $msg = "$host\t\t\t Query Failed: ".$resolver->errorstring;
				spit(1,$msg,0);
			}
		}
	}
}
sub secondstage {
	# Working off of the CNAMEs lets see what we can find....
	#
	my $SSL = 0;
	my $HTTP200OK = 0;
	my $HTTPS200OK = 0;
	my $FOUND = 0;
	foreach $site (@SECONDSTAGEC){
		my $agent = give_me_an_agent();
		my $msg = "Connecting to $site using $agent";
		spit(1,$msg,0);
		my $uri = "http://".$site;
		my $mechs = WWW::Mechanize->new(quiet => 1, agent => $agent, cookie_jar => undef);
		my $mech = WWW::Mechanize->new(quiet => 1, agent => $agent, cookie_jar => undef);
		$mech->get($uri);
		$msg = "Connected: ".$mech->status();
		spit(1,$msg,0);
		if(!$mech->success()){
			$msg = "HTTP not available. Retry with TLS";
			spit(1,$msg,0);
			$agent = give_me_an_agent();
			$uris = "https://".$site;
			$mechs->get($uris);
			if(!$mechs->success()){
				$msg = "$uri and $uris seem to be down.";
				spit(1,$msg,0);
				return;
			}
			return;
		}
		if($mechs->status()){
			$SSL = 1;
		}
		if($SSL){
			if($mechs->status() =~ /30/){ 
				$msg = "Got a redirect: ";
				my $re = $mechs->res;
				my $loc = $re->header('Location');
				$msg .= "[TLS] $loc";
				spit(1,$msg,0);
				return;
			}elsif($mechs->status() == 200){
				$HTTPS200OK = 1;
			}
		}else{
			if($mech->status() =~ /30/){
				my $re = $mech->res;
				my $loc = $re-header('Location');
				$msg .= "[HTTP] $loc";
				spit(1,$msg,0);
				return;
			}elsif($mech->status() == 200){
				$HTTP200OK=1;
			}
		}
		if($HTTP200OK || $HTTPS200OK){
			my $c = undef;
			if($HTTP200OK){
				$c = $mech->content( format =>'text' );
			}elsif($HTTPS200OK){
				$c = $mechs->content( format => 'text' );
			}
			foreach $l (keys %RESPONSE){
				if($RESPONSE{$l} =~ /$c/){
					$msg = "$l detected.";
					spit(0,$msg,1);
					$FOUND=1;
				}
			}
			if(!$FOUND){
				$msg = "Unknown App Server detected.\n";
				spit(1,$msg,0);
			
			}
		}	
			
	}
		
}	
sub usage {
	
	print color('bold blue');
	print "$0: a subdomain brute force scanner originally inspired by work done by nahamsec\n";
	print color('reset');
	print "--verbose => turn on verbose logging\n";
	print "--quiet => supress all output\n";
	print "--useragent => File for random user agents\n";
	print "--ns => File for nameservers\n";
	print "--output => file for storing results\n";
	print "--help => this message\n";
	print "$0 [options] domain.tld\n";
	exit();
}

sub spit {
	my $err = shift;
	my $msg = shift;
	my $type = shift;
	chomp($msg); #just incase we add a newline
	$msg .="\n";
	print FH $msg if $output;
	print color("red") if $err;
	print color("green") if $type == 1;
	if($err){
		print $msg if $verbose;
	}else{
		print $msg;
	}
	print color("reset");
}

sub give_me_an_agent {
	my $agent = $UA[rand @UA];
	chomp($agent);
	return $agent;
}
sub give_me_a_nameserver {
	my $ns = $NS[rand @NS];
	chomp($ns);
	return $ns;
}
