# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Rosetta-Schema-DataType.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..68\n"; }
END {print "not ok 1\n" unless $loaded;}
use Rosetta::Schema::DataType 0.021;
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

message( "START TESTING Rosetta::Schema::DataType" );

######################################################################
# testing new(), initialize(), clone(), and get_all_properties()

{
	message( "testing new(), initialize(), clone(), and get_all_properties()" );

	my ($did, $should);

	# make new with default values

	my $rsdt1 = Rosetta::Schema::DataType->new();  
	result( UNIVERSAL::isa( $rsdt1, "Rosetta::Schema::DataType" ), 
		"rsdt1 = new() ret rsdt obj" );

	$did = serialize( $rsdt1->get_all_properties() );
	$should = "{ 'base_type' => 'str', 'name' => 'No_Name_Data_Type', 'size' => '250', 'store_fixed' => '0', }, ";
	result( $did eq $should, "on init rsdt1->get_all_properties() returns '$did'" );

	# make new with provided values (in hash)

	my $rsdt2 = Rosetta::Schema::DataType->new( {
		'name' => 'product_code',
		'base_type' => 'str',
		'size' => 10,
		'store_fixed' => 1,
	} );  
	result( UNIVERSAL::isa( $rsdt2, "Rosetta::Schema::DataType" ), 
		"rsdt2 = new( { 'name' => 'product_code', 'base_type' => 'str', ".
		"'size' => 10, 'store_fixed' => 1, } ) ret rsdt obj" );

	$did = serialize( $rsdt2->get_all_properties() );
	$should = "{ 'base_type' => 'str', 'name' => 'product_code', 'size' => '10', 'store_fixed' => '1', }, ";
	result( $did eq $should, "on init rsdt2->get_all_properties() returns '$did'" );
	# now we test clone of default values

	my $rsdt3 = $rsdt1->clone();  
	result( UNIVERSAL::isa( $rsdt3, "Rosetta::Schema::DataType" ), 
		"rsdt3 = rsdt1->clone() ret rsdt obj" );

	$did = serialize( $rsdt3->get_all_properties() );
	$should = "{ 'base_type' => 'str', 'name' => 'No_Name_Data_Type', 'size' => '250', 'store_fixed' => '0', }, ";
	result( $did eq $should, "on init rsdt3->get_all_properties() returns '$did'" );
	# now we test clone of provided values (in hash)

	my $rsdt4 = $rsdt2->clone();  
	result( UNIVERSAL::isa( $rsdt4, "Rosetta::Schema::DataType" ), 
		"rsdt4 = rsdt2->clone() ret rsdt obj" );

	$did = serialize( $rsdt4->get_all_properties() );
	$should = "{ 'base_type' => 'str', 'name' => 'product_code', 'size' => '10', 'store_fixed' => '1', }, ";
	result( $did eq $should, "on init rsdt4->get_all_properties() returns '$did'" );

	# make new with provided values (in DataType object)

	my $rsdt5 = Rosetta::Schema::DataType->new( $rsdt4 );  
	result( UNIVERSAL::isa( $rsdt5, "Rosetta::Schema::DataType" ), 
		"rsdt5 = new( rsdt4 ) ret rsdt obj" );

	$did = serialize( $rsdt5->get_all_properties() );
	$should = "{ 'base_type' => 'str', 'name' => 'product_code', 'size' => '10', 'store_fixed' => '1', }, ";
	result( $did eq $should, "on init rsdt5->get_all_properties() returns '$did'" );

	# make new with provided values (a string)

	my $rsdt6 = Rosetta::Schema::DataType->new( 'boolean' );  
	result( UNIVERSAL::isa( $rsdt6, "Rosetta::Schema::DataType" ), 
		"rsdt6 = new( 'boolean' ) ret rsdt obj" );

	$did = serialize( $rsdt6->get_all_properties() );
	$should = "{ 'base_type' => 'boolean', 'name' => 'No_Name_Data_Type', 'size' => '0', 'store_fixed' => '0', }, ";
	result( $did eq $should, "on init rsdt6->get_all_properties() returns '$did'" );

	# make new with provided values (an array ref)

	my $rsdt7 = Rosetta::Schema::DataType->new( [1,2,3] );  
	result( UNIVERSAL::isa( $rsdt7, "Rosetta::Schema::DataType" ), 
		"rsdt7 = new( [1,2,3] ) ret rsdt obj" );

	$did = serialize( $rsdt7->get_all_properties() );
	$should = "{ 'base_type' => 'str', 'name' => 'No_Name_Data_Type', 'size' => '250', 'store_fixed' => '0', }, ";
	result( $did eq $should, "on init rsdt7->get_all_properties() returns '$did'" );
	# now we test clone of provided values (string) into other existing object

	my $rsdt8 = $rsdt6->clone( $rsdt7 );  # now 8 and 7 point to same obj, with prop of 6
	result( UNIVERSAL::isa( $rsdt8, "Rosetta::Schema::DataType" ), 
		"rsdt8 = rsdt6->clone( rsdt7 ) ret rsdt obj" );

	$did = serialize( $rsdt8->get_all_properties() );
	$should = "{ 'base_type' => 'boolean', 'name' => 'No_Name_Data_Type', 'size' => '0', 'store_fixed' => '0', }, ";
	result( $did eq $should, "on init rsdt8->get_all_properties() returns '$did'" );

	# now we test initialize with partially full input hash

	$rsdt2->initialize( { 'store_fixed' => 1, 'base_type' => 'datetime' } );
	result( 1, "rsdt2->initialize( { 'store_fixed' => 1, ".
		"'base_type' => 'datetime' } ) was called" );

	$did = serialize( $rsdt2->get_all_properties() );
	$should = "{ 'base_type' => 'datetime', 'name' => 'No_Name_Data_Type', 'size' => '0', 'store_fixed' => '1', }, ";
	result( $did eq $should, "on init rsdt2->get_all_properties() returns '$did'" );
}

######################################################################
# test the other methods

{
	my ($rsdt, $did, $should);
	# first initialize data we will be reading from
	$rsdt = Rosetta::Schema::DataType->new(); 

	message( "testing setter/getter methods on default object - get only" );

	# check the main setter/getter methods

	$did = $rsdt->name();
	$should = "No_Name_Data_Type";
	result( $did eq $should, "on init rsdt->name() returns '$did'" );

	$did = $rsdt->base_type();
	$should = "str";
	result( $did eq $should, "on init rsdt->base_type() returns '$did'" );

	$did = $rsdt->size();
	$should = "250";
	result( $did eq $should, "on init rsdt->size() returns '$did'" );

	$did = $rsdt->store_fixed();
	$should = "0";
	result( $did eq $should, "on init rsdt->store_fixed() returns '$did'" );

	message( "testing name() method on default object - set then get" );

	$did = $rsdt->name( '' );
	$should = "";
	result( $did eq $should, "name( '' ) returns '$did'" );

	$did = $rsdt->name( 0 );
	$should = "0";
	result( $did eq $should, "name( 0 ) returns '$did'" );

	$did = $rsdt->name( 'inventory_count' );
	$should = "inventory_count";
	result( $did eq $should, "name( 'inventory_count' ) returns '$did'" );

	$did = $rsdt->name( undef );
	$should = "inventory_count";
	result( $did eq $should, "name( undef ) returns '$did'" );

	message( "testing base_type() method on default object - set then get" );

	$did = $rsdt->store_fixed( 1 );
	$should = "1";
	result( $did eq $should, "store_fixed( 1 ) returns '$did'" );
	$did = $rsdt->base_type( 'boolean' );
	$should = "boolean";
	result( $did eq $should, "base_type( 'boolean' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "0";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );
	$did = $rsdt->store_fixed();
	$should = "0";
	result( $did eq $should, "following type set rsdt->store_fixed() returns '$did'" );

	$did = $rsdt->base_type( 'datetime' );
	$should = "datetime";
	result( $did eq $should, "base_type( 'datetime' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "0";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	$did = $rsdt->base_type( 'str' );
	$should = "str";
	result( $did eq $should, "base_type( 'str' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "250";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	$did = $rsdt->base_type( 'binary' );
	$should = "binary";
	result( $did eq $should, "base_type( 'binary' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "250";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	$did = $rsdt->base_type( 'float' );
	$should = "float";
	result( $did eq $should, "base_type( 'float' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "4";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	$did = $rsdt->base_type( 'int' );
	$should = "int";
	result( $did eq $should, "base_type( 'int' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "4";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	$did = $rsdt->base_type( undef );
	$should = "int";
	result( $did eq $should, "base_type( undef ) returns '$did'" );
	$did = $rsdt->size();
	$should = "4";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	$did = $rsdt->base_type( 'blorf' );
	$should = "int";
	result( $did eq $should, "base_type( 'blorf' ) returns '$did'" );
	$did = $rsdt->size();
	$should = "4";
	result( $did eq $should, "following type set rsdt->size() returns '$did'" );

	message( "testing size() method on default object - set then get" );

	$did = $rsdt->size( 8 );
	$should = "8";
	result( $did eq $should, "size( 8 ) returns '$did'" );

	$did = $rsdt->size( undef );
	$should = "8";
	result( $did eq $should, "size( undef ) returns '$did'" );

	$did = $rsdt->size( -5 );
	$should = "-5";
	result( $did eq $should, "size( -5 ) returns '$did'" );

	$did = $rsdt->size( 0 );
	$should = "0";
	result( $did eq $should, "size( 0 ) returns '$did'" );

	$did = $rsdt->size( 1.24 );
	$should = "1";
	result( $did eq $should, "size( 1.24 ) returns '$did'" );

	$did = $rsdt->size( ' 6 ' );
	$should = "6";
	result( $did eq $should, "size( ' 6 ' ) returns '$did'" );

	$did = $rsdt->size( 8 );
	$should = "8";
	result( $did eq $should, "size( 8 ) returns '$did'" );

	message( "testing store_fixed() method on default object - set then get" );

	$did = $rsdt->store_fixed( '' );
	$should = "0";
	result( $did eq $should, "name( '' ) returns '$did'" );

	$did = $rsdt->store_fixed( 'meow' );
	$should = "1";
	result( $did eq $should, "name( 'meow' ) returns '$did'" );

	$did = $rsdt->store_fixed( undef );
	$should = "1";
	result( $did eq $should, "name( undef ) returns '$did'" );

	$did = $rsdt->store_fixed( 3 );
	$should = "1";
	result( $did eq $should, "name( 3 ) returns '$did'" );

	$did = $rsdt->store_fixed( 1 );
	$should = "1";
	result( $did eq $should, "name( 1 ) returns '$did'" );

	$did = $rsdt->store_fixed( 0 );
	$should = "0";
	result( $did eq $should, "name( 0 ) returns '$did'" );

	message( "testing valid_types() as method on default object and as function" );

	$did = serialize( $rsdt->valid_types() );
	$should = "{ 'binary' => '250', 'boolean' => '0', 'datetime' => '0', 'float' => '4', 'int' => '4', 'str' => '250', }, ";
	result( $did eq $should, "\$rsdt->valid_types() returns '$did'" );

	$did = serialize( Rosetta::Schema::DataType->valid_types() );
	$should = "{ 'binary' => '250', 'boolean' => '0', 'datetime' => '0', 'float' => '4', 'int' => '4', 'str' => '250', }, ";
	result( $did eq $should, "Rosetta::Schema::DataType->valid_types() returns '$did'" );

	$did = serialize( $rsdt->valid_types( 'float' ) );
	$should = "'4', ";
	result( $did eq $should, "\$rsdt->valid_types( 'float' ) returns '$did'" );

	$did = serialize( Rosetta::Schema::DataType->valid_types( 'float' ) );
	$should = "'4', ";
	result( $did eq $should, "Rosetta::Schema::DataType->valid_types( 'float' ) returns '$did'" );

	$did = serialize( $rsdt->valid_types( 'datetime' ) );
	$should = "'0', ";
	result( $did eq $should, "\$rsdt->valid_types( 'datetime' ) returns '$did'" );

	$did = serialize( Rosetta::Schema::DataType->valid_types( 'datetime' ) );
	$should = "'0', ";
	result( $did eq $should, "Rosetta::Schema::DataType->valid_types( 'datetime' ) returns '$did'" );

	$did = serialize( $rsdt->valid_types( 'chirp' ) );
	$should = "undef, ";
	result( $did eq $should, "\$rsdt->valid_types( 'chirp' ) returns '$did'" );

	$did = serialize( Rosetta::Schema::DataType->valid_types( 'chirp' ) );
	$should = "undef, ";
	result( $did eq $should, "Rosetta::Schema::DataType->valid_types( 'chirp' ) returns '$did'" );

	$did = serialize( $rsdt->valid_types( '' ) );
	$should = "undef, ";
	result( $did eq $should, "\$rsdt->valid_types( '' ) returns '$did'" );

	$did = serialize( Rosetta::Schema::DataType->valid_types( '' ) );
	$should = "undef, ";
	result( $did eq $should, "Rosetta::Schema::DataType->valid_types( '' ) returns '$did'" );
}

######################################################################

message( "DONE TESTING Rosetta::Schema::DataType" );

######################################################################

1;
