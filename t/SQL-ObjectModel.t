# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SQL-ObjectModel.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use SQL::ObjectModel 0.02;
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

message( "START TESTING SQL::ObjectModel" );

######################################################################

message( "First populate some objects ..." );

use SQL::ObjectModel;

my $object_model = SQL::ObjectModel->new(); # a root node

$object_model->add_child_nodes( [ map { { 'NODE_TYPE' => 'data_type', 'ATTRS' => $_ } } (
	{ 'name' => 'bin1k' , 'basic_type' => 'bin', 'size_in_bytes' =>  1_000, },
	{ 'name' => 'bin32k', 'basic_type' => 'bin', 'size_in_bytes' => 32_000, },
	{ 'name' => 'str4'  , 'basic_type' => 'str', 'size_in_chars' =>  4, 'store_fixed' => 1, 
		'str_encoding' => 'asc', 'str_trim_white' => 1, 'str_latin_case' => 'uc', 
		'str_pad_char' => ' ', 'str_trim_pad' => 1, },
	{ 'name' => 'str10' , 'basic_type' => 'str', 'size_in_chars' => 10, 'store_fixed' => 1, 
		'str_encoding' => 'asc', 'str_trim_white' => 1, 'str_latin_case' => 'pr', 
		'str_pad_char' => ' ', 'str_trim_pad' => 1, },
	{ 'name' => 'str30' , 'basic_type' => 'str', 'size_in_chars' =>    30, 
		'str_encoding' => 'asc', 'str_trim_white' => 1, },
	{ 'name' => 'str2k' , 'basic_type' => 'str', 'size_in_chars' => 2_000, 'str_encoding' => 'u16', },
	{ 'name' => 'byte' , 'basic_type' => 'num', 'size_in_bytes' => 1, 'num_precision' => 0, }, #  3 digits
	{ 'name' => 'short', 'basic_type' => 'num', 'size_in_bytes' => 2, 'num_precision' => 0, }, #  5 digits
	{ 'name' => 'int'  , 'basic_type' => 'num', 'size_in_bytes' => 4, 'num_precision' => 0, }, # 10 digits
	{ 'name' => 'long' , 'basic_type' => 'num', 'size_in_bytes' => 8, 'num_precision' => 0, }, # 19 digits
	{ 'name' => 'ubyte' , 'basic_type' => 'num', 'size_in_bytes' => 1, 
		'num_unsigned' => 1, 'num_precision' => 0, }, #  3 digits
	{ 'name' => 'ushort', 'basic_type' => 'num', 'size_in_bytes' => 2, 
		'num_unsigned' => 1, 'num_precision' => 0, }, #  5 digits
	{ 'name' => 'uint'  , 'basic_type' => 'num', 'size_in_bytes' => 4, 
		'num_unsigned' => 1, 'num_precision' => 0, }, # 10 digits
	{ 'name' => 'ulong' , 'basic_type' => 'num', 'size_in_bytes' => 8, 
		'num_unsigned' => 1, 'num_precision' => 0, }, # 19 digits
	{ 'name' => 'float' , 'basic_type' => 'num', 'size_in_bytes' => 4, },
	{ 'name' => 'double', 'basic_type' => 'num', 'size_in_bytes' => 8, },
	{ 'name' => 'dec10p2', 'basic_type' => 'num', 'size_in_digits' =>  10, 'num_precision' => 2, },
	{ 'name' => 'dec255' , 'basic_type' => 'num', 'size_in_digits' => 255, },
	{ 'name' => 'boolean', 'basic_type' => 'bool', },
	{ 'name' => 'datetime', 'basic_type' => 'datetime', 'datetime_calendar' => 'abs', },
	{ 'name' => 'dtchines', 'basic_type' => 'datetime', 'datetime_calendar' => 'chi', },
	{ 'name' => 'str1'  , 'basic_type' => 'str', 'size_in_chars' =>     1, },
	{ 'name' => 'str20' , 'basic_type' => 'str', 'size_in_chars' =>    20, },
	{ 'name' => 'str100', 'basic_type' => 'str', 'size_in_chars' =>   100, },
	{ 'name' => 'str250', 'basic_type' => 'str', 'size_in_chars' =>   250, },
	{ 'name' => 'entitynm', 'basic_type' => 'str', 'size_in_chars' =>  30, },
	{ 'name' => 'generic' , 'basic_type' => 'str', 'size_in_chars' => 250, },
) ] );

my $database = SQL::ObjectModel->new( { 'NODE_TYPE' => 'database', 'PARENT' => $object_model } );
my $namespace = SQL::ObjectModel->new( { 'NODE_TYPE' => 'namespace', 'PARENT' => $database } );

my $tbl_person = SQL::ObjectModel->new( { 'NODE_TYPE' => 'table', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'person', 'public_syn' => 'person', 
		'storage_file' => 'person', }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
		{
			'name' => 'person_id', 'data_type' => 'int', 'required_val' => 1,
			'default_val' => 1, 'auto_inc' => 1,
		},
		{ 'name' => 'alternate_id', 'data_type' => 'str20' , 'required_val' => 0, },
		{ 'name' => 'name'        , 'data_type' => 'str100', 'required_val' => 1, },
		{ 'name' => 'sex'         , 'data_type' => 'str1'  , 'required_val' => 0, },
		{ 'name' => 'father_id'   , 'data_type' => 'int'   , 'required_val' => 0, },
		{ 'name' => 'mother_id'   , 'data_type' => 'int'   , 'required_val' => 0, },
	) ),
	( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
			'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
		[ { 'name' => 'primary'        , 'ind_type' => 'unique', }, 'person_id'    ], 
		[ { 'name' => 'ak_alternate_id', 'ind_type' => 'unique', }, 'alternate_id' ], 
		[ { 'name' => 'fk_father', 'ind_type' => 'foreign', 'f_table' => 'person', }, 
			{ 'col' => 'father_id', 'f_col' => 'person_id' } ], 
		[ { 'name' => 'fk_mother', 'ind_type' => 'foreign', 'f_table' => 'person', }, 
			{ 'col' => 'mother_id', 'f_col' => 'person_id' } ], 
	) ),
] } );

my $vw_person = SQL::ObjectModel->new( { 'NODE_TYPE' => 'view', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'person', 'may_write' => 1, 'match_table' => 'person' }, } );

my $vw_person_with_parents = SQL::ObjectModel->new( { 'NODE_TYPE' => 'view', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'person_with_parents', 'may_write' => 0, }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
		{ 'name' => 'self_id'    , 'data_type' => 'int'   , },
		{ 'name' => 'self_name'  , 'data_type' => 'str100', },
		{ 'name' => 'father_id'  , 'data_type' => 'int'   , },
		{ 'name' => 'father_name', 'data_type' => 'str100', },
		{ 'name' => 'mother_id'  , 'data_type' => 'int'   , },
		{ 'name' => 'mother_name', 'data_type' => 'str100', },
	) ),
	{ 'NODE_TYPE' => 'view_rowset', 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => $_, 'match_table' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( person_id name ) ] 
		} } qw( self father mother ) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'self', 
				'rhs_src' => 'father', 'join_type' => 'left', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'lhs_src_col' => 'father_id', 
				'rhs_src_col' => 'person_id',  } },
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'self', 
				'rhs_src' => 'mother', 'join_type' => 'left', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'lhs_src_col' => 'mother_id', 
				'rhs_src_col' => 'person_id',  } },
		] },
		( map { { 'NODE_TYPE' => 'view_col_def', 'ATTRS' => $_ } } (
			{ 'name' => 'self_id'    , 'expr_type' => 'col', 'src' => 'self'  , 'src_col' => 'person_id', },
			{ 'name' => 'self_name'  , 'expr_type' => 'col', 'src' => 'self'  , 'src_col' => 'name'     , },
			{ 'name' => 'father_id'  , 'expr_type' => 'col', 'src' => 'father', 'src_col' => 'person_id', },
			{ 'name' => 'father_name', 'expr_type' => 'col', 'src' => 'father', 'src_col' => 'name'     , },
			{ 'name' => 'mother_id'  , 'expr_type' => 'col', 'src' => 'mother', 'src_col' => 'person_id', },
			{ 'name' => 'mother_name', 'expr_type' => 'col', 'src' => 'mother', 'src_col' => 'name'     , },
		) ),
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
				'expr_type' => 'sfunc', 'sfunc' => 'and', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'sfunc', 'sfunc' => 'like', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'col', 'src' => 'father', 'src_col' => 'name', }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'var', 'var_name' => 'srchw_fa', }, },
			] },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'sfunc', 'sfunc' => 'like', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'col', 'src' => 'mother', 'src_col' => 'name', }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'var', 'var_name' => 'srchw_mo', }, },
			] },
		] },
	] },
] } );

my $tbl_user_auth = SQL::ObjectModel->new( { 'NODE_TYPE' => 'table', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'user_auth', 'public_syn' => 'user_auth', 
		'storage_file' => 'user', }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
		{
			'name' => 'user_id', 'data_type' => 'int', 'required_val' => 1,
			'default_val' => 1, 'auto_inc' => 1,
		},
		{ 'name' => 'login_name'   , 'data_type' => 'str20'  , 'required_val' => 1, },
		{ 'name' => 'login_pass'   , 'data_type' => 'str20'  , 'required_val' => 1, },
		{ 'name' => 'private_name' , 'data_type' => 'str100' , 'required_val' => 1, },
		{ 'name' => 'private_email', 'data_type' => 'str100' , 'required_val' => 1, },
		{ 'name' => 'may_login'    , 'data_type' => 'boolean', 'required_val' => 1, },
		{ 
			'name' => 'max_sessions', 'data_type' => 'byte', 'required_val' => 1, 
			'default_val' => 3, 
		},
	) ),
	( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
			'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
		[ { 'name' => 'primary'         , 'ind_type' => 'unique', }, 'user_id'       ],
		[ { 'name' => 'ak_login_name'   , 'ind_type' => 'unique', }, 'login_name'    ],
		[ { 'name' => 'ak_private_email', 'ind_type' => 'unique', }, 'private_email' ],
	) ),
] } );

my $tbl_user_profile = SQL::ObjectModel->new( { 'NODE_TYPE' => 'table', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'user_profile', 'public_syn' => 'user_profile', 
		'storage_file' => 'user', }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
		{ 'name' => 'user_id'     , 'data_type' => 'int'   , 'required_val' => 1, },
		{ 'name' => 'public_name' , 'data_type' => 'str250', 'required_val' => 1, },
		{ 'name' => 'public_email', 'data_type' => 'str250', 'required_val' => 0, },
		{ 'name' => 'web_url'     , 'data_type' => 'str250', 'required_val' => 0, },
		{ 'name' => 'contact_net' , 'data_type' => 'str250', 'required_val' => 0, },
		{ 'name' => 'contact_phy' , 'data_type' => 'str250', 'required_val' => 0, },
		{ 'name' => 'bio'         , 'data_type' => 'str250', 'required_val' => 0, },
		{ 'name' => 'plan'        , 'data_type' => 'str250', 'required_val' => 0, },
		{ 'name' => 'comments'    , 'data_type' => 'str250', 'required_val' => 0, },
	) ),
	( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
			'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
		[ { 'name' => 'primary'       , 'ind_type' => 'unique', }, 'user_id'     ],
		[ { 'name' => 'ak_public_name', 'ind_type' => 'unique', }, 'public_name' ],
		[ { 'name' => 'fk_user', 'ind_type' => 'foreign', 'f_table' => 'user_auth', }, 
			{ 'col' => 'user_id', 'f_col' => 'user_id' } ], 
	) ),
] } );

my $vw_user = SQL::ObjectModel->new( { 'NODE_TYPE' => 'view', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'user', 'may_write' => 1, }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
		{ 'name' => 'user_id'      , 'data_type' => 'int'    , },
		{ 'name' => 'login_name'   , 'data_type' => 'str20'  , },
		{ 'name' => 'login_pass'   , 'data_type' => 'str20'  , },
		{ 'name' => 'private_name' , 'data_type' => 'str100' , },
		{ 'name' => 'private_email', 'data_type' => 'str100' , },
		{ 'name' => 'may_login'    , 'data_type' => 'boolean', },
		{ 'name' => 'max_sessions' , 'data_type' => 'byte'   , },
		{ 'name' => 'public_name'  , 'data_type' => 'str250' , },
		{ 'name' => 'public_email' , 'data_type' => 'str250' , },
		{ 'name' => 'web_url'      , 'data_type' => 'str250' , },
		{ 'name' => 'contact_net'  , 'data_type' => 'str250' , },
		{ 'name' => 'contact_phy'  , 'data_type' => 'str250' , },
		{ 'name' => 'bio'          , 'data_type' => 'str250' , },
		{ 'name' => 'plan'         , 'data_type' => 'str250' , },
		{ 'name' => 'comments'     , 'data_type' => 'str250' , },
	) ),
	{ 'NODE_TYPE' => 'view_rowset', 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_auth', 
				'match_table' => 'user_auth', }, 'CHILDREN' => [ 
			( map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw(
				user_id login_name login_pass private_name private_email may_login max_sessions
			) ),
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_profile', 
				'match_table' => 'user_profile', }, 'CHILDREN' => [ 
			( map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw(
				user_id public_name public_email web_url contact_net contact_phy bio plan comments
			) ),
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'user_auth', 
				'rhs_src' => 'user_profile', 'join_type' => 'left', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'lhs_src_col' => 'user_id', 
				'rhs_src_col' => 'user_id',  } },
		] },
		( map { { 'NODE_TYPE' => 'view_col_def', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'      , 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'user_id'      , },
			{ 'name' => 'login_name'   , 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'login_name'   , },
			{ 'name' => 'login_pass'   , 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'login_pass'   , },
			{ 'name' => 'private_name' , 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'private_name' , },
			{ 'name' => 'private_email', 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'private_email', },
			{ 'name' => 'may_login'    , 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'may_login'    , },
			{ 'name' => 'max_sessions' , 'expr_type' => 'col', 'src' => 'user_auth'   , 'src_col' => 'max_sessions' , },
			{ 'name' => 'public_name'  , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'public_name'  , },
			{ 'name' => 'public_email' , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'public_email' , },
			{ 'name' => 'web_url'      , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'web_url'      , },
			{ 'name' => 'contact_net'  , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'contact_net'  , },
			{ 'name' => 'contact_phy'  , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'contact_phy'  , },
			{ 'name' => 'bio'          , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'bio'          , },
			{ 'name' => 'plan'         , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'plan'         , },
			{ 'name' => 'comments'     , 'expr_type' => 'col', 'src' => 'user_profile', 'src_col' => 'comments'     , },
		) ),
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
				'expr_type' => 'sfunc', 'sfunc' => 'eq', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'col', 'src' => 'user_auth', 'src_col' => 'user_id', }, },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'var', 'var_name' => 'curr_uid', }, },
		] },
	] },
] } );

my $tbl_user_pref = SQL::ObjectModel->new( { 'NODE_TYPE' => 'table', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'user_pref', 'public_syn' => 'user_pref', 
		'storage_file' => 'user', }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
		{ 'name' => 'user_id'   , 'data_type' => 'int'     , 'required_val' => 1, },
		{ 'name' => 'pref_name' , 'data_type' => 'entitynm', 'required_val' => 1, },
		{ 'name' => 'pref_value', 'data_type' => 'generic' , 'required_val' => 0, },
	) ),
	( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
			map { { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_ } } @{$_->[1]}
			] } } (
		[ { 'name' => 'primary', 'ind_type' => 'unique', }, [ 'user_id', 'pref_name', ], ], 
		[ { 'name' => 'fk_user', 'ind_type' => 'foreign', 'f_table' => 'user_auth', }, 
			[ { 'col' => 'user_id', 'f_col' => 'user_id' }, ], ], 
	) ),
] } );

my $vw_user_theme = SQL::ObjectModel->new( { 'NODE_TYPE' => 'view', 'PARENT' => $namespace, 
		'ATTRS' => { 'name' => 'user_theme', 'may_write' => 0, }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
		{ 'name' => 'theme_name' , 'data_type' => 'generic', },
		{ 'name' => 'theme_count', 'data_type' => 'int'    , },
	) ),
	{ 'NODE_TYPE' => 'view_rowset', 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_pref', 'match_table' => 'user_pref', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( pref_name pref_value ) ] 
		},
		{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'name' => 'theme_name', 
			'expr_type' => 'col', 'src' => 'user_pref', 'src_col' => 'pref_value', }, },
		{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'name' => 'theme_count', 
				'expr_type' => 'sfunc', 'sfunc' => 'gcount', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 
				'expr_type' => 'col', 'src' => 'user_pref', 'src_col' => 'pref_value', }, },
		] },
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
				'expr_type' => 'sfunc', 'sfunc' => 'eq', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'col', 'src' => 'user_pref', 'src_col' => 'pref_name', }, },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'lit', 'lit_val' => 'theme', }, },
		] },
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'group', 
			'expr_type' => 'col', 'src' => 'user_pref', 'src_col' => 'pref_value', }, },
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'havin', 
				'expr_type' => 'sfunc', 'sfunc' => 'gt', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'sfunc', 'sfunc' => 'gcount', }, },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'lit', 'lit_val' => '1', }, },
		] },
	] },
] } );

result( 1, "creation of all objects" );

######################################################################

message( "Now see if the output is correct ..." );

my $expected_output = "{ 
'NODE_TYPE' => 'root', 
'ATTRS' => { }, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '1000', 
'basic_type' => 'bin', 
'name' => 'bin1k', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '32000', 
'basic_type' => 'bin', 
'name' => 'bin32k', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'store_fixed' => '1', 
'str_trim_pad' => '1', 
'str_latin_case' => 'uc', 
'size_in_chars' => '4', 
'basic_type' => 'str', 
'str_trim_white' => '1', 
'str_pad_char' => ' ', 
'str_encoding' => 'asc', 
'name' => 'str4', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'store_fixed' => '1', 
'str_trim_pad' => '1', 
'str_latin_case' => 'pr', 
'size_in_chars' => '10', 
'basic_type' => 'str', 
'str_trim_white' => '1', 
'str_pad_char' => ' ', 
'str_encoding' => 'asc', 
'name' => 'str10', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '30', 
'basic_type' => 'str', 
'str_trim_white' => '1', 
'str_encoding' => 'asc', 
'name' => 'str30', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '2000', 
'basic_type' => 'str', 
'str_encoding' => 'u16', 
'name' => 'str2k', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '1', 
'basic_type' => 'num', 
'num_precision' => '0', 
'name' => 'byte', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '2', 
'basic_type' => 'num', 
'num_precision' => '0', 
'name' => 'short', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '4', 
'basic_type' => 'num', 
'num_precision' => '0', 
'name' => 'int', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '8', 
'basic_type' => 'num', 
'num_precision' => '0', 
'name' => 'long', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '1', 
'basic_type' => 'num', 
'num_unsigned' => '1', 
'num_precision' => '0', 
'name' => 'ubyte', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '2', 
'basic_type' => 'num', 
'num_unsigned' => '1', 
'num_precision' => '0', 
'name' => 'ushort', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '4', 
'basic_type' => 'num', 
'num_unsigned' => '1', 
'num_precision' => '0', 
'name' => 'uint', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '8', 
'basic_type' => 'num', 
'num_unsigned' => '1', 
'num_precision' => '0', 
'name' => 'ulong', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '4', 
'basic_type' => 'num', 
'name' => 'float', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_bytes' => '8', 
'basic_type' => 'num', 
'name' => 'double', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'basic_type' => 'num', 
'size_in_digits' => '10', 
'num_precision' => '2', 
'name' => 'dec10p2', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'basic_type' => 'num', 
'size_in_digits' => '255', 
'name' => 'dec255', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'basic_type' => 'bool', 
'name' => 'boolean', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'basic_type' => 'datetime', 
'datetime_calendar' => 'abs', 
'name' => 'datetime', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'basic_type' => 'datetime', 
'datetime_calendar' => 'chi', 
'name' => 'dtchines', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '1', 
'basic_type' => 'str', 
'name' => 'str1', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '20', 
'basic_type' => 'str', 
'name' => 'str20', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '100', 
'basic_type' => 'str', 
'name' => 'str100', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '250', 
'basic_type' => 'str', 
'name' => 'str250', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '30', 
'basic_type' => 'str', 
'name' => 'entitynm', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'data_type', 
'ATTRS' => { 
'size_in_chars' => '250', 
'basic_type' => 'str', 
'name' => 'generic', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'database', 
'ATTRS' => { }, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'namespace', 
'ATTRS' => { }, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table', 
'ATTRS' => { 
'storage_file' => 'person', 
'id' => '1', 
'public_syn' => 'person', 
'name' => 'person', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'default_val' => '1', 
'auto_inc' => '1', 
'data_type' => 'int', 
'name' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str20', 
'name' => 'alternate_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'str100', 
'name' => 'name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str1', 
'name' => 'sex', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'int', 
'name' => 'father_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'int', 
'name' => 'mother_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'primary', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'ak_alternate_id', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'alternate_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'f_table' => 'person', 
'ind_type' => 'foreign', 
'name' => 'fk_father', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'father_id', 
'f_col' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'f_table' => 'person', 
'ind_type' => 'foreign', 
'name' => 'fk_mother', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'mother_id', 
'f_col' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table', 
'ATTRS' => { 
'storage_file' => 'user', 
'id' => '1', 
'public_syn' => 'user_auth', 
'name' => 'user_auth', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'default_val' => '1', 
'auto_inc' => '1', 
'data_type' => 'int', 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'str20', 
'name' => 'login_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'str20', 
'name' => 'login_pass', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'str100', 
'name' => 'private_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'str100', 
'name' => 'private_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'boolean', 
'name' => 'may_login', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'default_val' => '3', 
'data_type' => 'byte', 
'name' => 'max_sessions', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'primary', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'ak_login_name', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'login_name', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'ak_private_email', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'private_email', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table', 
'ATTRS' => { 
'storage_file' => 'user', 
'id' => '1', 
'public_syn' => 'user_profile', 
'name' => 'user_profile', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'int', 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'str250', 
'name' => 'public_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'public_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'web_url', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'contact_net', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'contact_phy', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'bio', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'plan', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'str250', 
'name' => 'comments', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'primary', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'ak_public_name', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'public_name', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'f_table' => 'user_auth', 
'ind_type' => 'foreign', 
'name' => 'fk_user', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'user_id', 
'f_col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table', 
'ATTRS' => { 
'storage_file' => 'user', 
'id' => '1', 
'public_syn' => 'user_pref', 
'name' => 'user_pref', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'int', 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '1', 
'data_type' => 'entitynm', 
'name' => 'pref_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_col', 
'ATTRS' => { 
'required_val' => '0', 
'data_type' => 'generic', 
'name' => 'pref_value', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'ind_type' => 'unique', 
'name' => 'primary', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'pref_name', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'table_ind', 
'ATTRS' => { 
'f_table' => 'user_auth', 
'ind_type' => 'foreign', 
'name' => 'fk_user', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'table_ind_col', 
'ATTRS' => { 
'col' => 'user_id', 
'f_col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view', 
'ATTRS' => { 
'id' => '1', 
'view_type' => 'caller', 
'match_table' => 'person', 
'may_write' => '1', 
'name' => 'person', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view', 
'ATTRS' => { 
'id' => '1', 
'view_type' => 'caller', 
'may_write' => '0', 
'name' => 'person_with_parents', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'int', 
'name' => 'self_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str100', 
'name' => 'self_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'int', 
'name' => 'father_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str100', 
'name' => 'father_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'int', 
'name' => 'mother_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str100', 
'name' => 'mother_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_rowset', 
'ATTRS' => { }, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'self', 
'expr_type' => 'col', 
'src_col' => 'person_id', 
'name' => 'self_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'self', 
'expr_type' => 'col', 
'src_col' => 'name', 
'name' => 'self_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'father', 
'expr_type' => 'col', 
'src_col' => 'person_id', 
'name' => 'father_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'father', 
'expr_type' => 'col', 
'src_col' => 'name', 
'name' => 'father_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'mother', 
'expr_type' => 'col', 
'src_col' => 'person_id', 
'name' => 'mother_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'mother', 
'expr_type' => 'col', 
'src_col' => 'name', 
'name' => 'mother_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_join', 
'ATTRS' => { 
'rhs_src' => 'father', 
'join_type' => 'left', 
'lhs_src' => 'self', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_join_col', 
'ATTRS' => { 
'lhs_src_col' => { 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'father_id', 
}, 
'CHILDREN' => [ ], 
}, 
'rhs_src_col' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_join', 
'ATTRS' => { 
'rhs_src' => 'mother', 
'join_type' => 'left', 
'lhs_src' => 'self', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_join_col', 
'ATTRS' => { 
'lhs_src_col' => { 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'mother_id', 
}, 
'CHILDREN' => [ ], 
}, 
'rhs_src_col' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'and', 
'view_part' => 'where', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'like', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'src' => 'father', 
'expr_type' => 'col', 
'src_col' => 'name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'var_name' => 'srchw_fa', 
'expr_type' => 'var', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'like', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'src' => 'mother', 
'expr_type' => 'col', 
'src_col' => 'name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'var_name' => 'srchw_mo', 
'expr_type' => 'var', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_src', 
'ATTRS' => { 
'match_table' => 'person', 
'name' => 'self', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'name', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_src', 
'ATTRS' => { 
'match_table' => 'person', 
'name' => 'father', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'name', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_src', 
'ATTRS' => { 
'match_table' => 'person', 
'name' => 'mother', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'person_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'name', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view', 
'ATTRS' => { 
'id' => '1', 
'view_type' => 'caller', 
'may_write' => '1', 
'name' => 'user', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'int', 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str20', 
'name' => 'login_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str20', 
'name' => 'login_pass', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str100', 
'name' => 'private_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str100', 
'name' => 'private_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'boolean', 
'name' => 'may_login', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'byte', 
'name' => 'max_sessions', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'public_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'public_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'web_url', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'contact_net', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'contact_phy', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'bio', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'plan', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'str250', 
'name' => 'comments', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_rowset', 
'ATTRS' => { }, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'user_id', 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'login_name', 
'name' => 'login_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'login_pass', 
'name' => 'login_pass', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'private_name', 
'name' => 'private_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'private_email', 
'name' => 'private_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'may_login', 
'name' => 'may_login', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'max_sessions', 
'name' => 'max_sessions', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'public_name', 
'name' => 'public_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'public_email', 
'name' => 'public_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'web_url', 
'name' => 'web_url', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'contact_net', 
'name' => 'contact_net', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'contact_phy', 
'name' => 'contact_phy', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'bio', 
'name' => 'bio', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'plan', 
'name' => 'plan', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_profile', 
'expr_type' => 'col', 
'src_col' => 'comments', 
'name' => 'comments', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_join', 
'ATTRS' => { 
'rhs_src' => 'user_profile', 
'join_type' => 'left', 
'lhs_src' => 'user_auth', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_join_col', 
'ATTRS' => { 
'lhs_src_col' => 'user_id', 
'rhs_src_col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'eq', 
'view_part' => 'where', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'src' => 'user_auth', 
'expr_type' => 'col', 
'src_col' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'var_name' => 'curr_uid', 
'expr_type' => 'var', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_src', 
'ATTRS' => { 
'match_table' => 'user_auth', 
'name' => 'user_auth', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'login_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'login_pass', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'private_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'private_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'may_login', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'max_sessions', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_src', 
'ATTRS' => { 
'match_table' => 'user_profile', 
'name' => 'user_profile', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'user_id', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'public_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'public_email', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'web_url', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'contact_net', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'contact_phy', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'bio', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'plan', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'comments', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view', 
'ATTRS' => { 
'id' => '1', 
'view_type' => 'caller', 
'may_write' => '0', 
'name' => 'user_theme', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'generic', 
'name' => 'theme_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col', 
'ATTRS' => { 
'data_type' => 'int', 
'name' => 'theme_count', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_rowset', 
'ATTRS' => { }, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_pref', 
'expr_type' => 'col', 
'src_col' => 'pref_value', 
'name' => 'theme_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'gcount', 
'name' => 'theme_count', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_col_def', 
'ATTRS' => { 
'src' => 'user_pref', 
'expr_type' => 'col', 
'src_col' => 'pref_value', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'eq', 
'view_part' => 'where', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'src' => 'user_pref', 
'expr_type' => 'col', 
'src_col' => 'pref_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'lit_val' => 'theme', 
'expr_type' => 'lit', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'src' => 'user_pref', 
'expr_type' => 'col', 
'src_col' => 'pref_value', 
'view_part' => 'group', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'gt', 
'view_part' => 'havin', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'expr_type' => 'sfunc', 
'sfunc' => 'gcount', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_part_def', 
'ATTRS' => { 
'lit_val' => '1', 
'expr_type' => 'lit', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
{ 
'NODE_TYPE' => 'view_src', 
'ATTRS' => { 
'match_table' => 'user_pref', 
'name' => 'user_pref', 
}, 
'CHILDREN' => [ 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'pref_name', 
}, 
'CHILDREN' => [ ], 
}, 
{ 
'NODE_TYPE' => 'view_src_col', 
'ATTRS' => { 
'name' => 'pref_value', 
}, 
'CHILDREN' => [ ], 
}, 
], 
}, 
], 
}, 
], 
}, 
], 
}, 
], 
}, 
], 
}";

my $actual_output = $object_model->get_all_properties_as_str( 1, 1 );

result( $actual_output eq $expected_output, "verify serialization of objects" );

######################################################################

message( "Other functional tests are not written yet; they will come later" );

######################################################################

message( "DONE TESTING SQL::ObjectModel" );

######################################################################

1;
