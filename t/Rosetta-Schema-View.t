# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Rosetta-Schema-View.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Rosetta::Schema::View 0.012;
$loaded = 1;
print "ok 1\n";
use strict;
use warnings;

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

######################################################################
# Here are some utility methods:

my $test_num = 1;  # same as the firsv test, above

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

sub vis {
	my ($str) = @_;
	$str =~ s/\n/\\n/g;  # make newlines visible
	$str =~ s/\t/\\t/g;  # make tabs visible
	return( $str );
}

sub serialize {
	my ($input,$is_key) = @_;
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( '{ ', ( map { 
				( serialize( $_, 1 ), serialize( $input->{$_} ) ) 
			} sort keys %{$input} ), '}, ' ) 
		: ref($input) eq 'ARRAY' ? 
			( '[ ', ( map { 
				( serialize( $_ ) ) 
			} @{$input} ), '], ' ) 
		: defined($input) ?
			"'$input'".($is_key ? ' => ' : ', ')
		: "undef".($is_key ? ' => ' : ', ')
	) );
}

######################################################################

message( "START TESTING Rosetta::Schema::View" );

######################################################################
# testing new(), initialize(), clone(), and get_all_properties()

{
	message( "testing new(), initialize(), clone(), and get_all_properties()" );

	my ($did, $should);

	# make new with default values

	my $rsv1 = Rosetta::Schema::View->new();  
	result( UNIVERSAL::isa( $rsv1, "Rosetta::Schema::View" ), 
		"rsv1 = new() ret rsv obj" );

	message( "OTHER TESTS TO GO HERE" );
}

######################################################################
# test the other methods

{
	my ($rsv, $did, $should);
	# firsv initialize data we will be reading from
	$rsv = Rosetta::Schema::View->new(); 

	message( "OTHER TESTS TO GO HERE" );
}

######################################################################

message( "DONE TESTING Rosetta::Schema::View" );

######################################################################

1;
