#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 1 );

######################################################################
# First ensure the modules to test will compile, are correct versions:

use Rosetta 0.43;
use Rosetta::L::en 0.16;
use Rosetta::Validator 0.43;
use Rosetta::Validator::L::en 0.10;

######################################################################
# Here are some utility methods:

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub error_to_string {
	my ($message) = @_;
	if( ref($message) and UNIVERSAL::isa( $message, 'Rosetta::Interface' ) ) {
		$message = $message->get_error_message();
	}
	if( ref($message) and UNIVERSAL::isa( $message, 'Locale::KeyedText::Message' ) ) {
		my $translator = Locale::KeyedText->new_translator( 
			['Rosetta::L::', 'SQL::Routine::L::'], ['en'] );
		my $user_text = $translator->translate_message( $message );
		unless( $user_text ) {
			return 'internal error: can\'t find user text for a message: '.
				$message->as_string().' '.$translator->as_string();
		}
		return $user_text;
	}
	return $message; # if this isn't the right kind of object
}

######################################################################
# Now perform the actual tests:

message( 'START TESTING Rosetta' );

######################################################################

eval {
	pass( "all modules compiled" );
};
$@ and fail( "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( 'DONE TESTING Rosetta' );

######################################################################

1;
