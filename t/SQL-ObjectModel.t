# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SQL-ObjectModel.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use SQL::ObjectModel 0.031;
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

my $expected_output = 
'{ \n\'NODE_TYPE\' => \'root\', \n\'ATTRS\' => { }, \n\'CHILDREN\' => [ '.
'\n{ \n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { '.
'\n\'size_in_bytes\' => \'1000\', \n\'basic_type\' => \'bin\', \n\'name\' '.
'=> \'bin1k\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' => \'32000\', '.
'\n\'basic_type\' => \'bin\', \n\'name\' => \'bin32k\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'store_fixed\' => \'1\', \n\'str_trim_pad\' => '.
'\'1\', \n\'str_latin_case\' => \'uc\', \n\'size_in_chars\' => \'4\', '.
'\n\'basic_type\' => \'str\', \n\'str_trim_white\' => \'1\', '.
'\n\'str_pad_char\' => \' \', \n\'str_encoding\' => \'asc\', \n\'name\' '.
'=> \'str4\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'data_type\', \n\'ATTRS\' => { \n\'store_fixed\' => \'1\', '.
'\n\'str_trim_pad\' => \'1\', \n\'str_latin_case\' => \'pr\', '.
'\n\'size_in_chars\' => \'10\', \n\'basic_type\' => \'str\', '.
'\n\'str_trim_white\' => \'1\', \n\'str_pad_char\' => \' \', '.
'\n\'str_encoding\' => \'asc\', \n\'name\' => \'str10\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_chars\' => \'30\', \n\'basic_type\' => '.
'\'str\', \n\'str_trim_white\' => \'1\', \n\'str_encoding\' => \'asc\', '.
'\n\'name\' => \'str30\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_chars\' '.
'=> \'2000\', \n\'basic_type\' => \'str\', \n\'str_encoding\' => \'u16\', '.
'\n\'name\' => \'str2k\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'1\', \n\'basic_type\' => \'num\', \n\'num_precision\' => \'0\', '.
'\n\'name\' => \'byte\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'2\', \n\'basic_type\' => \'num\', \n\'num_precision\' => \'0\', '.
'\n\'name\' => \'short\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'4\', \n\'basic_type\' => \'num\', \n\'num_precision\' => \'0\', '.
'\n\'name\' => \'int\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'8\', \n\'basic_type\' => \'num\', \n\'num_precision\' => \'0\', '.
'\n\'name\' => \'long\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'1\', \n\'basic_type\' => \'num\', \n\'num_unsigned\' => \'1\', '.
'\n\'num_precision\' => \'0\', \n\'name\' => \'ubyte\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_bytes\' => \'2\', \n\'basic_type\' => '.
'\'num\', \n\'num_unsigned\' => \'1\', \n\'num_precision\' => \'0\', '.
'\n\'name\' => \'ushort\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'4\', \n\'basic_type\' => \'num\', \n\'num_unsigned\' => \'1\', '.
'\n\'num_precision\' => \'0\', \n\'name\' => \'uint\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_bytes\' => \'8\', \n\'basic_type\' => '.
'\'num\', \n\'num_unsigned\' => \'1\', \n\'num_precision\' => \'0\', '.
'\n\'name\' => \'ulong\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_bytes\' '.
'=> \'4\', \n\'basic_type\' => \'num\', \n\'name\' => \'float\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_bytes\' => \'8\', \n\'basic_type\' => '.
'\'num\', \n\'name\' => \'double\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'basic_type\' => '.
'\'num\', \n\'size_in_digits\' => \'10\', \n\'num_precision\' => \'2\', '.
'\n\'name\' => \'dec10p2\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'basic_type\' => '.
'\'num\', \n\'size_in_digits\' => \'255\', \n\'name\' => \'dec255\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'basic_type\' => \'bool\', \n\'name\' => '.
'\'boolean\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'data_type\', \n\'ATTRS\' => { \n\'basic_type\' => \'datetime\', '.
'\n\'datetime_calendar\' => \'abs\', \n\'name\' => \'datetime\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'basic_type\' => \'datetime\', '.
'\n\'datetime_calendar\' => \'chi\', \n\'name\' => \'dtchines\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_chars\' => \'1\', \n\'basic_type\' => '.
'\'str\', \n\'name\' => \'str1\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_chars\' '.
'=> \'20\', \n\'basic_type\' => \'str\', \n\'name\' => \'str20\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_chars\' => \'100\', \n\'basic_type\' => '.
'\'str\', \n\'name\' => \'str100\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { \n\'size_in_chars\' '.
'=> \'250\', \n\'basic_type\' => \'str\', \n\'name\' => \'str250\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'data_type\', '.
'\n\'ATTRS\' => { \n\'size_in_chars\' => \'30\', \n\'basic_type\' => '.
'\'str\', \n\'name\' => \'entitynm\', \n}, \n\'CHILDREN\' => [ ], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'data_type\', \n\'ATTRS\' => { '.
'\n\'size_in_chars\' => \'250\', \n\'basic_type\' => \'str\', \n\'name\' '.
'=> \'generic\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'database\', \n\'ATTRS\' => { }, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'namespace\', \n\'ATTRS\' => { }, \n\'CHILDREN\' => '.
'[ \n{ \n\'NODE_TYPE\' => \'table\', \n\'ATTRS\' => { \n\'storage_file\' '.
'=> \'person\', \n\'id\' => \'1\', \n\'public_syn\' => \'person\', '.
'\n\'name\' => \'person\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' '.
'=> \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'1\', '.
'\n\'default_val\' => \'1\', \n\'auto_inc\' => \'1\', \n\'data_type\' => '.
'\'int\', \n\'name\' => \'person_id\', \n}, \n\'CHILDREN\' => [ ], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { '.
'\n\'required_val\' => \'0\', \n\'data_type\' => \'str20\', \n\'name\' => '.
'\'alternate_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'1\', '.
'\n\'data_type\' => \'str100\', \n\'name\' => \'name\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'0\', \n\'data_type\' => '.
'\'str1\', \n\'name\' => \'sex\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => '.
'\'0\', \n\'data_type\' => \'int\', \n\'name\' => \'father_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'0\', \n\'data_type\' => '.
'\'int\', \n\'name\' => \'mother_id\', \n}, \n\'CHILDREN\' => [ ], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => '.
'\'unique\', \n\'name\' => \'primary\', \n}, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => '.
'\'person_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => '.
'\'unique\', \n\'name\' => \'ak_alternate_id\', \n}, \n\'CHILDREN\' => [ '.
'\n{ \n\'NODE_TYPE\' => \'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => '.
'\'alternate_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table_ind\', \n\'ATTRS\' => { \n\'f_table\' => '.
'\'person\', \n\'ind_type\' => \'foreign\', \n\'name\' => \'fk_father\', '.
'\n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'table_ind_col\', '.
'\n\'ATTRS\' => { \n\'col\' => \'father_id\', \n\'f_col\' => '.
'\'person_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table_ind\', \n\'ATTRS\' => { \n\'f_table\' => '.
'\'person\', \n\'ind_type\' => \'foreign\', \n\'name\' => \'fk_mother\', '.
'\n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'table_ind_col\', '.
'\n\'ATTRS\' => { \n\'col\' => \'mother_id\', \n\'f_col\' => '.
'\'person_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table\', \n\'ATTRS\' => { \n\'storage_file\' => '.
'\'user\', \n\'id\' => \'1\', \n\'public_syn\' => \'user_auth\', '.
'\n\'name\' => \'user_auth\', \n}, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => '.
'\'1\', \n\'default_val\' => \'1\', \n\'auto_inc\' => \'1\', '.
'\n\'data_type\' => \'int\', \n\'name\' => \'user_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'1\', \n\'data_type\' => '.
'\'str20\', \n\'name\' => \'login_name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { '.
'\n\'required_val\' => \'1\', \n\'data_type\' => \'str20\', \n\'name\' => '.
'\'login_pass\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'1\', '.
'\n\'data_type\' => \'str100\', \n\'name\' => \'private_name\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'1\', \n\'data_type\' => '.
'\'str100\', \n\'name\' => \'private_email\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { '.
'\n\'required_val\' => \'1\', \n\'data_type\' => \'boolean\', \n\'name\' '.
'=> \'may_login\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'1\', '.
'\n\'default_val\' => \'3\', \n\'data_type\' => \'byte\', \n\'name\' => '.
'\'max_sessions\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => \'unique\', '.
'\n\'name\' => \'primary\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' '.
'=> \'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'user_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => \'unique\', \n\'name\' '.
'=> \'ak_login_name\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'login_name\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => \'unique\', \n\'name\' '.
'=> \'ak_private_email\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'private_email\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'table\', \n\'ATTRS\' => { \n\'storage_file\' => \'user\', \n\'id\' => '.
'\'1\', \n\'public_syn\' => \'user_profile\', \n\'name\' => '.
'\'user_profile\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'1\', '.
'\n\'data_type\' => \'int\', \n\'name\' => \'user_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'1\', \n\'data_type\' => '.
'\'str250\', \n\'name\' => \'public_name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { '.
'\n\'required_val\' => \'0\', \n\'data_type\' => \'str250\', \n\'name\' '.
'=> \'public_email\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => '.
'\'0\', \n\'data_type\' => \'str250\', \n\'name\' => \'web_url\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'0\', \n\'data_type\' => '.
'\'str250\', \n\'name\' => \'contact_net\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { '.
'\n\'required_val\' => \'0\', \n\'data_type\' => \'str250\', \n\'name\' '.
'=> \'contact_phy\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'0\', '.
'\n\'data_type\' => \'str250\', \n\'name\' => \'bio\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'0\', \n\'data_type\' => '.
'\'str250\', \n\'name\' => \'plan\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { \n\'required_val\' => '.
'\'0\', \n\'data_type\' => \'str250\', \n\'name\' => \'comments\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_ind\', '.
'\n\'ATTRS\' => { \n\'ind_type\' => \'unique\', \n\'name\' => '.
'\'primary\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'user_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => \'unique\', \n\'name\' '.
'=> \'ak_public_name\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'public_name\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'table_ind\', \n\'ATTRS\' => { \n\'f_table\' => \'user_auth\', '.
'\n\'ind_type\' => \'foreign\', \n\'name\' => \'fk_user\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'table_ind_col\', '.
'\n\'ATTRS\' => { \n\'col\' => \'user_id\', \n\'f_col\' => \'user_id\', '.
'\n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'table\', \n\'ATTRS\' => { \n\'storage_file\' => \'user\', \n\'id\' '.
'=> \'1\', \n\'public_syn\' => \'user_pref\', \n\'name\' => '.
'\'user_pref\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'table_col\', \n\'ATTRS\' => { \n\'required_val\' => \'1\', '.
'\n\'data_type\' => \'int\', \n\'name\' => \'user_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_col\', '.
'\n\'ATTRS\' => { \n\'required_val\' => \'1\', \n\'data_type\' => '.
'\'entitynm\', \n\'name\' => \'pref_name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'table_col\', \n\'ATTRS\' => { '.
'\n\'required_val\' => \'0\', \n\'data_type\' => \'generic\', \n\'name\' '.
'=> \'pref_value\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'table_ind\', \n\'ATTRS\' => { \n\'ind_type\' => \'unique\', '.
'\n\'name\' => \'primary\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' '.
'=> \'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'user_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'table_ind_col\', '.
'\n\'ATTRS\' => { \n\'col\' => \'pref_name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'table_ind\', \n\'ATTRS\' => { '.
'\n\'f_table\' => \'user_auth\', \n\'ind_type\' => \'foreign\', '.
'\n\'name\' => \'fk_user\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' '.
'=> \'table_ind_col\', \n\'ATTRS\' => { \n\'col\' => \'user_id\', '.
'\n\'f_col\' => \'user_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, '.
'\n], \n}, \n{ \n\'NODE_TYPE\' => \'view\', \n\'ATTRS\' => { \n\'id\' => '.
'\'1\', \n\'view_type\' => \'caller\', \n\'match_table\' => \'person\', '.
'\n\'may_write\' => \'1\', \n\'name\' => \'person\', \n}, \n\'CHILDREN\' '.
'=> [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view\', \n\'ATTRS\' => { \n\'id\' '.
'=> \'1\', \n\'view_type\' => \'caller\', \n\'may_write\' => \'0\', '.
'\n\'name\' => \'person_with_parents\', \n}, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => '.
'\'int\', \n\'name\' => \'self_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => '.
'\'str100\', \n\'name\' => \'self_name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { '.
'\n\'data_type\' => \'int\', \n\'name\' => \'father_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'str100\', \n\'name\' => '.
'\'father_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_col\', \n\'ATTRS\' => { \n\'data_type\' => \'int\', \n\'name\' => '.
'\'mother_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_col\', \n\'ATTRS\' => { \n\'data_type\' => \'str100\', \n\'name\' '.
'=> \'mother_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'view_rowset\', \n\'ATTRS\' => { }, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'self\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'person_id\', '.
'\n\'name\' => \'self_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'self\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'name\', '.
'\n\'name\' => \'self_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'father\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'person_id\', '.
'\n\'name\' => \'father_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'father\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'name\', '.
'\n\'name\' => \'father_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'mother\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'person_id\', '.
'\n\'name\' => \'mother_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'mother\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'name\', '.
'\n\'name\' => \'mother_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_join\', \n\'ATTRS\' => { \n\'rhs_src\' => '.
'\'father\', \n\'join_type\' => \'left\', \n\'lhs_src\' => \'self\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_join_col\', '.
'\n\'ATTRS\' => { \n\'lhs_src_col\' => { \n\'NODE_TYPE\' => '.
'\'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'father_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n\'rhs_src_col\' => \'person_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_join\', \n\'ATTRS\' => { \n\'rhs_src\' => \'mother\', '.
'\n\'join_type\' => \'left\', \n\'lhs_src\' => \'self\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_join_col\', '.
'\n\'ATTRS\' => { \n\'lhs_src_col\' => { \n\'NODE_TYPE\' => '.
'\'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'mother_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n\'rhs_src_col\' => \'person_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_part_def\', \n\'ATTRS\' => { \n\'expr_type\' => \'sfunc\', '.
'\n\'sfunc\' => \'and\', \n\'view_part\' => \'where\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_part_def\', '.
'\n\'ATTRS\' => { \n\'expr_type\' => \'sfunc\', \n\'sfunc\' => \'like\', '.
'\n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_part_def\', '.
'\n\'ATTRS\' => { \n\'src\' => \'father\', \n\'expr_type\' => \'col\', '.
'\n\'src_col\' => \'name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { \n\'var_name\' => '.
'\'srchw_fa\', \n\'expr_type\' => \'var\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => '.
'{ \n\'expr_type\' => \'sfunc\', \n\'sfunc\' => \'like\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_part_def\', '.
'\n\'ATTRS\' => { \n\'src\' => \'mother\', \n\'expr_type\' => \'col\', '.
'\n\'src_col\' => \'name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { \n\'var_name\' => '.
'\'srchw_mo\', \n\'expr_type\' => \'var\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view_src\', '.
'\n\'ATTRS\' => { \n\'match_table\' => \'person\', \n\'name\' => '.
'\'self\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'person_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view_src\', \n\'ATTRS\' => { '.
'\n\'match_table\' => \'person\', \n\'name\' => \'father\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' '.
'=> { \n\'name\' => \'person_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => '.
'\'name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'view_src\', \n\'ATTRS\' => { \n\'match_table\' => \'person\', '.
'\n\'name\' => \'mother\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' '.
'=> \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'person_id\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n], \n}, \n], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view\', '.
'\n\'ATTRS\' => { \n\'id\' => \'1\', \n\'view_type\' => \'caller\', '.
'\n\'may_write\' => \'1\', \n\'name\' => \'user\', \n}, \n\'CHILDREN\' => '.
'[ \n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' '.
'=> \'int\', \n\'name\' => \'user_id\', \n}, \n\'CHILDREN\' => [ ], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => '.
'\'str20\', \n\'name\' => \'login_name\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { '.
'\n\'data_type\' => \'str20\', \n\'name\' => \'login_pass\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'str100\', \n\'name\' => '.
'\'private_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => \'str100\', '.
'\n\'name\' => \'private_email\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => '.
'\'boolean\', \n\'name\' => \'may_login\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { '.
'\n\'data_type\' => \'byte\', \n\'name\' => \'max_sessions\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'str250\', \n\'name\' => '.
'\'public_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_col\', \n\'ATTRS\' => { \n\'data_type\' => \'str250\', \n\'name\' '.
'=> \'public_email\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => '.
'\'str250\', \n\'name\' => \'web_url\', \n}, \n\'CHILDREN\' => [ ], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { \n\'data_type\' => '.
'\'str250\', \n\'name\' => \'contact_net\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => { '.
'\n\'data_type\' => \'str250\', \n\'name\' => \'contact_phy\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'str250\', \n\'name\' => \'bio\', '.
'\n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'str250\', \n\'name\' => \'plan\', '.
'\n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'str250\', \n\'name\' => '.
'\'comments\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_rowset\', \n\'ATTRS\' => { }, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'user_id\', '.
'\n\'name\' => \'user_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'login_name\', \n\'name\' => \'login_name\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'login_pass\', \n\'name\' => \'login_pass\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'private_name\', \n\'name\' => \'private_name\', \n}, \n\'CHILDREN\' => '.
'[ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'private_email\', \n\'name\' => \'private_email\', \n}, \n\'CHILDREN\' '.
'=> [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'may_login\', \n\'name\' => \'may_login\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' '.
'=> \'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'max_sessions\', \n\'name\' => \'max_sessions\', \n}, \n\'CHILDREN\' => '.
'[ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' '.
'=> \'public_name\', \n\'name\' => \'public_name\', \n}, \n\'CHILDREN\' '.
'=> [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' '.
'=> \'public_email\', \n\'name\' => \'public_email\', \n}, \n\'CHILDREN\' '.
'=> [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' '.
'=> \'web_url\', \n\'name\' => \'web_url\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' '.
'=> \'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'contact_net\', \n\'name\' => \'contact_net\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' '.
'=> \'contact_phy\', \n\'name\' => \'contact_phy\', \n}, \n\'CHILDREN\' '.
'=> [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' '.
'=> \'bio\', \n\'name\' => \'bio\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'plan\', '.
'\n\'name\' => \'plan\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_profile\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'comments\', \n\'name\' => \'comments\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_join\', \n\'ATTRS\' => { '.
'\n\'rhs_src\' => \'user_profile\', \n\'join_type\' => \'left\', '.
'\n\'lhs_src\' => \'user_auth\', \n}, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'view_join_col\', \n\'ATTRS\' => { \n\'lhs_src_col\' '.
'=> \'user_id\', \n\'rhs_src_col\' => \'user_id\', \n}, \n\'CHILDREN\' => '.
'[ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view_part_def\', '.
'\n\'ATTRS\' => { \n\'expr_type\' => \'sfunc\', \n\'sfunc\' => \'eq\', '.
'\n\'view_part\' => \'where\', \n}, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_auth\', \n\'expr_type\' => \'col\', \n\'src_col\' => \'user_id\', '.
'\n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_part_def\', \n\'ATTRS\' => { \n\'var_name\' => \'curr_uid\', '.
'\n\'expr_type\' => \'var\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'view_src\', \n\'ATTRS\' => { \n\'match_table\' '.
'=> \'user_auth\', \n\'name\' => \'user_auth\', \n}, \n\'CHILDREN\' => [ '.
'\n{ \n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => '.
'\'user_id\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'login_name\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'login_pass\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { '.
'\n\'name\' => \'private_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => '.
'\'private_email\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'may_login\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'max_sessions\', \n}, \n\'CHILDREN\' => '.
'[ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view_src\', \n\'ATTRS\' => '.
'{ \n\'match_table\' => \'user_profile\', \n\'name\' => \'user_profile\', '.
'\n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'user_id\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { '.
'\n\'name\' => \'public_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => '.
'\'public_email\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' '.
'=> \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'web_url\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'contact_net\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { '.
'\n\'name\' => \'contact_phy\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => '.
'\'bio\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_src_col\', \n\'ATTRS\' => { \n\'name\' => \'plan\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_src_col\', '.
'\n\'ATTRS\' => { \n\'name\' => \'comments\', \n}, \n\'CHILDREN\' => [ ], '.
'\n}, \n], \n}, \n], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => \'view\', '.
'\n\'ATTRS\' => { \n\'id\' => \'1\', \n\'view_type\' => \'caller\', '.
'\n\'may_write\' => \'0\', \n\'name\' => \'user_theme\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_col\', \n\'ATTRS\' => '.
'{ \n\'data_type\' => \'generic\', \n\'name\' => \'theme_name\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => \'view_col\', '.
'\n\'ATTRS\' => { \n\'data_type\' => \'int\', \n\'name\' => '.
'\'theme_count\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_rowset\', \n\'ATTRS\' => { }, \n\'CHILDREN\' => [ \n{ '.
'\n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_pref\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'pref_value\', \n\'name\' => \'theme_name\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_col_def\', \n\'ATTRS\' => { '.
'\n\'expr_type\' => \'sfunc\', \n\'sfunc\' => \'gcount\', \n\'name\' => '.
'\'theme_count\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'view_col_def\', \n\'ATTRS\' => { \n\'src\' => \'user_pref\', '.
'\n\'expr_type\' => \'col\', \n\'src_col\' => \'pref_value\', \n}, '.
'\n\'CHILDREN\' => [ ], \n}, \n], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_part_def\', \n\'ATTRS\' => { \n\'expr_type\' => \'sfunc\', '.
'\n\'sfunc\' => \'eq\', \n\'view_part\' => \'where\', \n}, \n\'CHILDREN\' '.
'=> [ \n{ \n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { '.
'\n\'src\' => \'user_pref\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'pref_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ \n\'NODE_TYPE\' => '.
'\'view_part_def\', \n\'ATTRS\' => { \n\'lit_val\' => \'theme\', '.
'\n\'expr_type\' => \'lit\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, '.
'\n{ \n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { \n\'src\' => '.
'\'user_pref\', \n\'expr_type\' => \'col\', \n\'src_col\' => '.
'\'pref_value\', \n\'view_part\' => \'group\', \n}, \n\'CHILDREN\' => [ '.
'], \n}, \n{ \n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { '.
'\n\'expr_type\' => \'sfunc\', \n\'sfunc\' => \'gt\', \n\'view_part\' => '.
'\'havin\', \n}, \n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => '.
'\'view_part_def\', \n\'ATTRS\' => { \n\'expr_type\' => \'sfunc\', '.
'\n\'sfunc\' => \'gcount\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_part_def\', \n\'ATTRS\' => { \n\'lit_val\' => '.
'\'1\', \n\'expr_type\' => \'lit\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], '.
'\n}, \n{ \n\'NODE_TYPE\' => \'view_src\', \n\'ATTRS\' => { '.
'\n\'match_table\' => \'user_pref\', \n\'name\' => \'user_pref\', \n}, '.
'\n\'CHILDREN\' => [ \n{ \n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' '.
'=> { \n\'name\' => \'pref_name\', \n}, \n\'CHILDREN\' => [ ], \n}, \n{ '.
'\n\'NODE_TYPE\' => \'view_src_col\', \n\'ATTRS\' => { \n\'name\' => '.
'\'pref_value\', \n}, \n\'CHILDREN\' => [ ], \n}, \n], \n}, \n], \n}, '.
'\n], \n}, \n], \n}, \n], \n}, \n], \n}, \n';

my $actual_output = vis( $object_model->get_all_properties_as_str( 1, 1 ) );

result( $actual_output eq $expected_output, "verify serialization of objects" );

######################################################################

message( "Other functional tests are not written yet; they will come later" );

######################################################################

message( "DONE TESTING SQL::ObjectModel" );

######################################################################

1;
