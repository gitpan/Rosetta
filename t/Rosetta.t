#!perl

use 5.008001; use utf8; use strict; use warnings;

BEGIN { $| = 1; print "1..1\n"; }

######################################################################
# First ensure the modules to test will compile, are correct versions:

use Rosetta '0.42';
use Rosetta::L::en '0.15';
use Rosetta::Validator '0.42';
use Rosetta::Validator::L::en '0.09';

######################################################################
# Here are some utility methods:

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

my $test_num = 0;

sub result {
	my ($worked, $detail) = @_;
	$test_num++;
	$verbose or 
		$detail = substr( $detail, 0, 50 ).
		(length( $detail ) > 47 ? "..." : "");
	print "@{[$worked ? '' : 'not ']}ok $test_num $detail\n";
}

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub error_to_string {
	my ($message) = @_;
	ref($message) or return $message; # if this isn't an object
	my $translator = Locale::KeyedText->new_translator( 
		['Rosetta::L::', 'SQL::Routine::L::'], ['en'] );
	my $user_text = $translator->translate_message( $message );
	unless( $user_text ) {
		return "internal error: can't find user text for a message: ".
			$message->as_string()." ".$translator->as_string();
	}
	return $user_text;
}

######################################################################
# Now perform the actual tests:

message( "START TESTING Rosetta" );

######################################################################

eval {
	result( 1, "all modules compiled" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING Rosetta" );

######################################################################

1;
