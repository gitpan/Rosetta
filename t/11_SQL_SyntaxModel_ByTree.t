# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 11_SQL_SyntaxModel_ByTree.t'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use t_SQL_SyntaxModel_ByTree;
use SQL::SyntaxModel::ByTree 0.08;
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

######################################################################

message( "START TESTING SQL::SyntaxModel::ByTree" );

######################################################################

message( "First populate some objects ..." );

my $model = t_SQL_SyntaxModel_ByTree->create_and_populate_model( 'SQL::SyntaxModel::ByTree' );
result( ref($model) eq 'SQL::SyntaxModel::ByTree', "creation of all objects" );

message( "Now see if the output is correct ..." );

my $expected_output = t_SQL_SyntaxModel_ByTree->expected_model_xml_output();
my $actual_output = $model->get_all_properties_as_xml_str();
result( $actual_output eq $expected_output, "verify serialization of objects" );

message( "Other functional tests are not written yet; they will come later" );

######################################################################

message( "DONE TESTING SQL::SyntaxModel::ByTree" );

######################################################################

1;
