#!/usr/bin/env perl

use warnings;
use strict;

use Net::Twitter;
use Scalar::Util 'blessed';

my %config = do '/secret/twitter3.config';

my $consumer_key		= $config{consumer_key};
my $consumer_secret		= $config{consumer_secret};
my $token			= $config{token};
my $token_secret		= $config{token_secret};

my $nt = Net::Twitter->new(
	ssl									=> 1,
	traits							=> [qw/API::RESTv1_1/],
	consumer_key        => $consumer_key,
	consumer_secret     => $consumer_secret,
	access_token        => $token,
	access_token_secret => $token_secret,
);


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();


my $folder = sprintf("%d-%02d-%02d_%02d-%02d-%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);

my $result = $nt->direct_messages;
my $ts=gmtime();
print "$ts checking for commands\n";
foreach (@$result){
	if($_->{text} =~ /^[Bb]uild$/){
		print "$ts starting tip build $_->{id}\n";
		$nt->update("starting tip build $_->{id}");
		$nt->destroy_direct_message($_->{id});
		system("/usr/bin/java -jar /home/jctong/scripts/jenkins-cli.jar -s http://jenkinsci:8080/ build assimmon  -p VERSION=tip -p FOLDER=$folder");
		system("/usr/bin/java -jar /home/jctong/scripts/jenkins-cli.jar -s http://jenkinsci:8080/ build assimmon-centos  -p VERSION=tip -p FOLDER=$folder");
	
	}elsif($_->{text} =~ /\b[Bb]uild\b (\w+)/){
		print "$ts starting rev $1 build $_->{id}\n";
		$nt->update("starting rev $1 build $_->{id}");
		$nt->destroy_direct_message($_->{id});
		system("/usr/bin/java -jar /home/jctong/scripts/jenkins-cli.jar -s http://jenkinsci:8080/ build assimmon  -p VERSION=$1 -p FOLDER=$folder");
		system("/usr/bin/java -jar /home/jctong/scripts/jenkins-cli.jar -s http://jenkinsci:8080/ build assimmon-centos  -p VERSION=$1 -p FOLDER=$folder");
	}
}


if ( my $err = $@ ) {
	die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

	warn "HTTP Response Code: ", $err->code, "\n",
	"HTTP Message......: ", $err->message, "\n",
	"Twitter error.....: ", $err->error, "\n";
	$nt->update("http response code: $err->code");
	$nt->update("http mesg: $err->message");
	$nt->update("twitter error: $err->error");

}

