#!/usr/bin/env perl

use warnings;
use strict;

use Net::Twitter;
use Scalar::Util 'blessed';
use Data::Dumper;

my %config = do '/secret/twitter3.config';

my $consumer_key		= $config{consumer_key};
my $consumer_secret		= $config{consumer_secret};
my $token			= $config{token};
my $token_secret		= $config{token_secret};

my $nt = Net::Twitter->new(
	traits							=> [qw/API::RESTv1_1/],
	consumer_key        => $consumer_key,
	consumer_secret     => $consumer_secret,
	access_token        => $token,
	access_token_secret => $token_secret,
);


my $result = $nt->direct_messages;
foreach (@$result){
	if($_->{text} eq 'build'){
		$nt->update("starting build $_->{id}");
		$nt->destroy_direct_message($_->{id});
		system("/usr/bin/java -jar /home/jctong/scripts/jenkins-cli.jar -s http://jenkinsci.ingres.prv:8080/ build assimmon");
	}
}


if ( my $err = $@ ) {
	die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

	warn "HTTP Response Code: ", $err->code, "\n",
	"HTTP Message......: ", $err->message, "\n",
	"Twitter error.....: ", $err->error, "\n";
}

