# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 12_SQL_SyntaxModel_SkipID.t'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use t_SQL_SyntaxModel;
use t_SQL_SyntaxModel_ByTree;
use t_SQL_SyntaxModel_SkipID;
use SQL::SyntaxModel::SkipID 0.11;
use SQL::SyntaxModel::SkipID::L::en 0.02;
$loaded = 1;
print "ok 1\n";
use strict;
use warnings;

######################### End of black magic.

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

######################################################################
# Here are some utility methods:

my $test_num = 1;  # same as the first test, above

sub result {
	$test_num++;
	my ($worked, $detail) = @_;
	$verbose or 
		$detail = substr( $detail, 0, 50 ).
		(length( $detail ) > 47 ? "..." : "");	print "@{[$worked ? '' : 'not ']}ok $test_num $detail\n";
}

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub error_to_string {
	my ($message) = @_;
	ref($message) or return( $message ); # if this isn't an object
	my $translator = Locale::KeyedText->new_translator( ['SQL::SyntaxModel::SkipID::L::', 
		'SQL::SyntaxModel::ByTree::L::', 'SQL::SyntaxModel::L::'], ['en'] );
	my $user_text = $translator->translate_message( $message );
	unless( $user_text ) {
		return( "internal error: can't find user text for a message: ".
			$message->as_string()." ".$translator->as_string() );
	}
	return( $user_text );
}

######################################################################

message( "START TESTING SQL::SyntaxModel::SkipID Parent Compatibility (SSM)" );

######################################################################

eval {
	message( "First populate some objects ..." );

	my $model = t_SQL_SyntaxModel->create_and_populate_model( 'SQL::SyntaxModel::SkipID' );
	result( ref($model) eq 'SQL::SyntaxModel::SkipID', "creation of all objects" );

	message( "Now see if the output is correct ..." );

	my $expected_output = t_SQL_SyntaxModel->expected_model_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects" );

	message( "Other functional tests are not written yet; they will come later" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::SyntaxModel::SkipID Parent Compatibility (SSM)" );
message( "START TESTING SQL::SyntaxModel::SkipID Parent Compatibility (SSMBTR)" );

######################################################################

eval {
	message( "First populate some objects ..." );

	my $model = t_SQL_SyntaxModel_ByTree->create_and_populate_model( 'SQL::SyntaxModel::SkipID' );
	result( ref($model) eq 'SQL::SyntaxModel::SkipID', "creation of all objects" );

	message( "Now see if the output is correct ..." );

	my $expected_output = t_SQL_SyntaxModel_ByTree->expected_model_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects" );

	message( "Other functional tests are not written yet; they will come later" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::SyntaxModel::SkipID Parent Compatibility (SSMBTR)" );
message( "START TESTING SQL::SyntaxModel::SkipID Added Functionality" );

######################################################################

eval {
	message( "First populate some objects ..." );

	my $model2 = t_SQL_SyntaxModel_SkipID->create_and_populate_model( 'SQL::SyntaxModel::SkipID' );
	result( ref($model2) eq 'SQL::SyntaxModel::SkipID', "creation of all objects" );

	message( "Now see if the output is correct ..." );

	my $expected_output2 = t_SQL_SyntaxModel_SkipID->expected_model_xml_output();
	my $actual_output2 = $model2->get_all_properties_as_xml_str();
	result( $actual_output2 eq $expected_output2, "verify serialization of objects" );

	message( "Other functional tests are not written yet; they will come later" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::SyntaxModel::SkipID Added Functionality" );

######################################################################

1;
