# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SQL-ObjectModel.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use SQL::ObjectModel 0.04;
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

my $model = SQL::ObjectModel->new();

$model->create_nodes( [ map { { 'NODE_TYPE' => 'data_type', 'ATTRS' => $_ } } (
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

$model->create_nodes( ['database', 'namespace'] );

my $tbl_person = $model->create_node( { 'NODE_TYPE' => 'table', 
		'ATTRS' => { 'name' => 'person', 'public_syn' => 'person', 
		'storage_file' => 'person', }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
		{
			'name' => 'person_id', 'data_type' => 'int', 'required_val' => 1,
			'default_val' => 1, 'auto_inc' => 1,
		},
		{ 'name' => 'alternate_id', 'data_type' => 'str20' , },
		{ 'name' => 'name'        , 'data_type' => 'str100', 'required_val' => 1, },
		{ 'name' => 'sex'         , 'data_type' => 'str1'  , },
		{ 'name' => 'father_id'   , 'data_type' => 'int'   , },
		{ 'name' => 'mother_id'   , 'data_type' => 'int'   , },
	) ),
	( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
			'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
		[ { 'name' => 'primary'        , 'ind_type' => 'unique', }, 'person_id'    ], 
		[ { 'name' => 'ak_alternate_id', 'ind_type' => 'unique', }, 'alternate_id' ], 
		[ { 'name' => 'fk_father', 'ind_type' => 'foreign', 'f_table' => 'person', }, 
			{ 'table_col' => 'father_id', 'f_table_col' => 'person_id' } ], 
		[ { 'name' => 'fk_mother', 'ind_type' => 'foreign', 'f_table' => 'person', }, 
			{ 'table_col' => 'mother_id', 'f_table_col' => 'person_id' } ], 
	) ),
] } );

my $vw_person = $model->create_node( { 'NODE_TYPE' => 'view', 
		'ATTRS' => { 'name' => 'person', 'may_write' => 1, 'match_table' => 'person' }, } );

my $vw_person_with_parents = $model->create_node( { 'NODE_TYPE' => 'view', 
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
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( person_id name father_id mother_id ) ] 
		} } qw( self ) ),
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => $_, 'match_table' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( person_id name ) ] 
		} } qw( father mother ) ),
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
			{ 'view_col' => 'self_id'    , 'expr_type' => 'col', 'src_col' => ['person_id','self'], },
			{ 'view_col' => 'self_name'  , 'expr_type' => 'col', 'src_col' => ['name'     ,'self'], },
			{ 'view_col' => 'father_id'  , 'expr_type' => 'col', 'src_col' => ['person_id','father'], },
			{ 'view_col' => 'father_name', 'expr_type' => 'col', 'src_col' => ['name'     ,'father'], },
			{ 'view_col' => 'mother_id'  , 'expr_type' => 'col', 'src_col' => ['person_id','mother'], },
			{ 'view_col' => 'mother_name', 'expr_type' => 'col', 'src_col' => ['name'     ,'mother'], },
		) ),
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
				'expr_type' => 'sfunc', 'sfunc' => 'and', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'sfunc', 'sfunc' => 'like', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'col', 'src_col' => ['name','father'], }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'var', 'command_var' => 'srchw_fa', }, },
			] },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'sfunc', 'sfunc' => 'like', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'col', 'src_col' => ['name','mother'], }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'expr_type' => 'var', 'command_var' => 'srchw_mo', }, },
			] },
		] },
	] },
] } );

my $tbl_user_auth = $model->create_node( { 'NODE_TYPE' => 'table', 
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

my $tbl_user_profile = $model->create_node( { 'NODE_TYPE' => 'table', 
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
			{ 'table_col' => 'user_id', 'f_table_col' => 'user_id' } ], 
	) ),
] } );

my $vw_user = $model->create_node( { 'NODE_TYPE' => 'view', 
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
			{ 'view_col' => 'user_id'      , 'expr_type' => 'col', 'src_col' => ['user_id'      ,'user_auth'   ], },
			{ 'view_col' => 'login_name'   , 'expr_type' => 'col', 'src_col' => ['login_name'   ,'user_auth'   ], },
			{ 'view_col' => 'login_pass'   , 'expr_type' => 'col', 'src_col' => ['login_pass'   ,'user_auth'   ], },
			{ 'view_col' => 'private_name' , 'expr_type' => 'col', 'src_col' => ['private_name' ,'user_auth'   ], },
			{ 'view_col' => 'private_email', 'expr_type' => 'col', 'src_col' => ['private_email','user_auth'   ], },
			{ 'view_col' => 'may_login'    , 'expr_type' => 'col', 'src_col' => ['may_login'    ,'user_auth'   ], },
			{ 'view_col' => 'max_sessions' , 'expr_type' => 'col', 'src_col' => ['max_sessions' ,'user_auth'   ], },
			{ 'view_col' => 'public_name'  , 'expr_type' => 'col', 'src_col' => ['public_name'  ,'user_profile'], },
			{ 'view_col' => 'public_email' , 'expr_type' => 'col', 'src_col' => ['public_email' ,'user_profile'], },
			{ 'view_col' => 'web_url'      , 'expr_type' => 'col', 'src_col' => ['web_url'      ,'user_profile'], },
			{ 'view_col' => 'contact_net'  , 'expr_type' => 'col', 'src_col' => ['contact_net'  ,'user_profile'], },
			{ 'view_col' => 'contact_phy'  , 'expr_type' => 'col', 'src_col' => ['contact_phy'  ,'user_profile'], },
			{ 'view_col' => 'bio'          , 'expr_type' => 'col', 'src_col' => ['bio'          ,'user_profile'], },
			{ 'view_col' => 'plan'         , 'expr_type' => 'col', 'src_col' => ['plan'         ,'user_profile'], },
			{ 'view_col' => 'comments'     , 'expr_type' => 'col', 'src_col' => ['comments'     ,'user_profile'], },
		) ),
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
				'expr_type' => 'sfunc', 'sfunc' => 'eq', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'col', 'src_col' => ['user_id','user_auth'], }, },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'var', 'command_var' => 'curr_uid', }, },
		] },
	] },
] } );

my $tbl_user_pref = $model->create_node( { 'NODE_TYPE' => 'table', 
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
			[ { 'table_col' => 'user_id', 'f_table_col' => 'user_id' }, ], ], 
	) ),
] } );

my $vw_user_theme = $model->create_node( { 'NODE_TYPE' => 'view', 
		'ATTRS' => { 'name' => 'user_theme', 'may_write' => 0, }, 'CHILDREN' => [ 
	( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
		{ 'name' => 'theme_name' , 'data_type' => 'generic', },
		{ 'name' => 'theme_count', 'data_type' => 'int'    , },
	) ),
	{ 'NODE_TYPE' => 'view_rowset', 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_pref', 'match_table' => 'user_pref', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( pref_name pref_value ) ] 
		},
		{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'view_col' => 'theme_name', 
			'expr_type' => 'col', 'src_col' => ['pref_value','user_pref'], }, },
		{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'view_col' => 'theme_count', 
				'expr_type' => 'sfunc', 'sfunc' => 'gcount', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 
				'expr_type' => 'col', 'src_col' => ['pref_value','user_pref'], }, },
		] },
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
				'expr_type' => 'sfunc', 'sfunc' => 'eq', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'col', 'src_col' => ['pref_name','user_pref'], }, },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
				'expr_type' => 'lit', 'lit_val' => 'theme', }, },
		] },
		{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'group', 
			'expr_type' => 'col', 'src_col' => ['pref_value','user_pref'], }, },
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
'<root id="1">
	<type_list id="1">
		<data_type id="1" basic_type="bin" name="bin1k" size_in_bytes="1000" />
		<data_type id="2" basic_type="bin" name="bin32k" size_in_bytes="32000" />
		<data_type id="3" basic_type="str" name="str4" size_in_chars="4" store_fixed="1" str_encoding="asc" str_latin_case="uc" str_pad_char=" " str_trim_pad="1" str_trim_white="1" />
		<data_type id="4" basic_type="str" name="str10" size_in_chars="10" store_fixed="1" str_encoding="asc" str_latin_case="pr" str_pad_char=" " str_trim_pad="1" str_trim_white="1" />
		<data_type id="5" basic_type="str" name="str30" size_in_chars="30" str_encoding="asc" str_trim_white="1" />
		<data_type id="6" basic_type="str" name="str2k" size_in_chars="2000" str_encoding="u16" />
		<data_type id="7" basic_type="num" name="byte" num_precision="0" size_in_bytes="1" />
		<data_type id="8" basic_type="num" name="short" num_precision="0" size_in_bytes="2" />
		<data_type id="9" basic_type="num" name="int" num_precision="0" size_in_bytes="4" />
		<data_type id="10" basic_type="num" name="long" num_precision="0" size_in_bytes="8" />
		<data_type id="11" basic_type="num" name="ubyte" num_precision="0" num_unsigned="1" size_in_bytes="1" />
		<data_type id="12" basic_type="num" name="ushort" num_precision="0" num_unsigned="1" size_in_bytes="2" />
		<data_type id="13" basic_type="num" name="uint" num_precision="0" num_unsigned="1" size_in_bytes="4" />
		<data_type id="14" basic_type="num" name="ulong" num_precision="0" num_unsigned="1" size_in_bytes="8" />
		<data_type id="15" basic_type="num" name="float" size_in_bytes="4" />
		<data_type id="16" basic_type="num" name="double" size_in_bytes="8" />
		<data_type id="17" basic_type="num" name="dec10p2" num_precision="2" size_in_digits="10" />
		<data_type id="18" basic_type="num" name="dec255" size_in_digits="255" />
		<data_type id="19" basic_type="bool" name="boolean" />
		<data_type id="20" basic_type="datetime" datetime_calendar="abs" name="datetime" />
		<data_type id="21" basic_type="datetime" datetime_calendar="chi" name="dtchines" />
		<data_type id="22" basic_type="str" name="str1" size_in_chars="1" />
		<data_type id="23" basic_type="str" name="str20" size_in_chars="20" />
		<data_type id="24" basic_type="str" name="str100" size_in_chars="100" />
		<data_type id="25" basic_type="str" name="str250" size_in_chars="250" />
		<data_type id="26" basic_type="str" name="entitynm" size_in_chars="30" />
		<data_type id="27" basic_type="str" name="generic" size_in_chars="250" />
	</type_list>
	<database_list id="1">
		<database id="1">
			<namespace id="1" database="1">
				<table id="1" name="person" namespace="1" order="1" public_syn="person" storage_file="person">
					<table_col id="1" auto_inc="1" data_type="9" default_val="1" name="person_id" order="1" required_val="1" table="1" />
					<table_col id="2" data_type="23" name="alternate_id" order="2" required_val="0" table="1" />
					<table_col id="3" data_type="24" name="name" order="3" required_val="1" table="1" />
					<table_col id="4" data_type="22" name="sex" order="4" required_val="0" table="1" />
					<table_col id="5" data_type="9" name="father_id" order="5" required_val="0" table="1" />
					<table_col id="6" data_type="9" name="mother_id" order="6" required_val="0" table="1" />
					<table_ind id="1" ind_type="unique" name="primary" order="1" table="1">
						<table_ind_col id="1" order="1" table_col="1" table_ind="1" />
					</table_ind>
					<table_ind id="2" ind_type="unique" name="ak_alternate_id" order="2" table="1">
						<table_ind_col id="2" order="2" table_col="2" table_ind="2" />
					</table_ind>
					<table_ind id="3" f_table="1" ind_type="foreign" name="fk_father" order="3" table="1">
						<table_ind_col id="3" f_table_col="1" order="3" table_col="5" table_ind="3" />
					</table_ind>
					<table_ind id="4" f_table="1" ind_type="foreign" name="fk_mother" order="4" table="1">
						<table_ind_col id="4" f_table_col="1" order="4" table_col="6" table_ind="4" />
					</table_ind>
				</table>
				<view id="1" match_table="1" may_write="1" name="person" namespace="1" view_type="caller" />
				<view id="2" may_write="0" name="person_with_parents" namespace="1" view_type="caller">
					<view_col id="1" data_type="9" name="self_id" order="1" view="2" />
					<view_col id="2" data_type="24" name="self_name" order="2" view="2" />
					<view_col id="3" data_type="9" name="father_id" order="3" view="2" />
					<view_col id="4" data_type="24" name="father_name" order="4" view="2" />
					<view_col id="5" data_type="9" name="mother_id" order="5" view="2" />
					<view_col id="6" data_type="24" name="mother_name" order="6" view="2" />
					<view_rowset id="1" p_rowset_order="1" view="2">
						<view_src id="1" match_table="1" name="self" order="1" rowset="1">
							<view_src_col id="1" match_table_col="1" src="1" />
							<view_src_col id="2" match_table_col="3" src="1" />
							<view_src_col id="3" match_table_col="5" src="1" />
							<view_src_col id="4" match_table_col="6" src="1" />
						</view_src>
						<view_src id="2" match_table="1" name="father" order="2" rowset="1">
							<view_src_col id="5" match_table_col="1" src="2" />
							<view_src_col id="6" match_table_col="3" src="2" />
						</view_src>
						<view_src id="3" match_table="1" name="mother" order="3" rowset="1">
							<view_src_col id="7" match_table_col="1" src="3" />
							<view_src_col id="8" match_table_col="3" src="3" />
						</view_src>
						<view_join id="1" join_type="left" lhs_src="1" rhs_src="2" rowset="1">
							<view_join_col id="1" join="1" lhs_src_col="3" rhs_src_col="5" />
						</view_join>
						<view_join id="2" join_type="left" lhs_src="1" rhs_src="3" rowset="1">
							<view_join_col id="2" join="2" lhs_src_col="4" rhs_src_col="7" />
						</view_join>
						<view_col_def id="1" expr_type="col" p_expr_order="1" rowset="1" src_col="1" view="2" view_col="1" />
						<view_col_def id="2" expr_type="col" p_expr_order="2" rowset="1" src_col="2" view="2" view_col="2" />
						<view_col_def id="3" expr_type="col" p_expr_order="3" rowset="1" src_col="5" view="2" view_col="3" />
						<view_col_def id="4" expr_type="col" p_expr_order="4" rowset="1" src_col="6" view="2" view_col="4" />
						<view_col_def id="5" expr_type="col" p_expr_order="5" rowset="1" src_col="7" view="2" view_col="5" />
						<view_col_def id="6" expr_type="col" p_expr_order="6" rowset="1" src_col="8" view="2" view_col="6" />
						<view_part_def id="1" expr_type="sfunc" p_expr_order="1" rowset="1" sfunc="and" view_part="where">
							<view_part_def id="2" expr_type="sfunc" p_expr="1" p_expr_order="2" rowset="1" sfunc="like" view_part="where">
								<view_part_def id="3" expr_type="col" p_expr="2" p_expr_order="3" rowset="1" src_col="6" view_part="where" />
								<view_part_def id="4" command_var="" expr_type="var" p_expr="2" p_expr_order="4" rowset="1" view_part="where" />
							</view_part_def>
							<view_part_def id="5" expr_type="sfunc" p_expr="1" p_expr_order="5" rowset="1" sfunc="like" view_part="where">
								<view_part_def id="6" expr_type="col" p_expr="5" p_expr_order="6" rowset="1" src_col="8" view_part="where" />
								<view_part_def id="7" command_var="" expr_type="var" p_expr="5" p_expr_order="7" rowset="1" view_part="where" />
							</view_part_def>
						</view_part_def>
					</view_rowset>
				</view>
				<table id="2" name="user_auth" namespace="1" order="2" public_syn="user_auth" storage_file="user">
					<table_col id="7" auto_inc="1" data_type="9" default_val="1" name="user_id" order="7" required_val="1" table="2" />
					<table_col id="8" data_type="23" name="login_name" order="8" required_val="1" table="2" />
					<table_col id="9" data_type="23" name="login_pass" order="9" required_val="1" table="2" />
					<table_col id="10" data_type="24" name="private_name" order="10" required_val="1" table="2" />
					<table_col id="11" data_type="24" name="private_email" order="11" required_val="1" table="2" />
					<table_col id="12" data_type="19" name="may_login" order="12" required_val="1" table="2" />
					<table_col id="13" data_type="7" default_val="3" name="max_sessions" order="13" required_val="1" table="2" />
					<table_ind id="5" ind_type="unique" name="primary" order="5" table="2">
						<table_ind_col id="5" order="5" table_col="7" table_ind="5" />
					</table_ind>
					<table_ind id="6" ind_type="unique" name="ak_login_name" order="6" table="2">
						<table_ind_col id="6" order="6" table_col="8" table_ind="6" />
					</table_ind>
					<table_ind id="7" ind_type="unique" name="ak_private_email" order="7" table="2">
						<table_ind_col id="7" order="7" table_col="11" table_ind="7" />
					</table_ind>
				</table>
				<table id="3" name="user_profile" namespace="1" order="3" public_syn="user_profile" storage_file="user">
					<table_col id="14" data_type="9" name="user_id" order="14" required_val="1" table="3" />
					<table_col id="15" data_type="25" name="public_name" order="15" required_val="1" table="3" />
					<table_col id="16" data_type="25" name="public_email" order="16" required_val="0" table="3" />
					<table_col id="17" data_type="25" name="web_url" order="17" required_val="0" table="3" />
					<table_col id="18" data_type="25" name="contact_net" order="18" required_val="0" table="3" />
					<table_col id="19" data_type="25" name="contact_phy" order="19" required_val="0" table="3" />
					<table_col id="20" data_type="25" name="bio" order="20" required_val="0" table="3" />
					<table_col id="21" data_type="25" name="plan" order="21" required_val="0" table="3" />
					<table_col id="22" data_type="25" name="comments" order="22" required_val="0" table="3" />
					<table_ind id="8" ind_type="unique" name="primary" order="8" table="3">
						<table_ind_col id="8" order="8" table_col="14" table_ind="8" />
					</table_ind>
					<table_ind id="9" ind_type="unique" name="ak_public_name" order="9" table="3">
						<table_ind_col id="9" order="9" table_col="15" table_ind="9" />
					</table_ind>
					<table_ind id="10" f_table="2" ind_type="foreign" name="fk_user" order="10" table="3">
						<table_ind_col id="10" f_table_col="7" order="10" table_col="14" table_ind="10" />
					</table_ind>
				</table>
				<view id="3" may_write="1" name="user" namespace="1" view_type="caller">
					<view_col id="7" data_type="9" name="user_id" order="7" view="3" />
					<view_col id="8" data_type="23" name="login_name" order="8" view="3" />
					<view_col id="9" data_type="23" name="login_pass" order="9" view="3" />
					<view_col id="10" data_type="24" name="private_name" order="10" view="3" />
					<view_col id="11" data_type="24" name="private_email" order="11" view="3" />
					<view_col id="12" data_type="19" name="may_login" order="12" view="3" />
					<view_col id="13" data_type="7" name="max_sessions" order="13" view="3" />
					<view_col id="14" data_type="25" name="public_name" order="14" view="3" />
					<view_col id="15" data_type="25" name="public_email" order="15" view="3" />
					<view_col id="16" data_type="25" name="web_url" order="16" view="3" />
					<view_col id="17" data_type="25" name="contact_net" order="17" view="3" />
					<view_col id="18" data_type="25" name="contact_phy" order="18" view="3" />
					<view_col id="19" data_type="25" name="bio" order="19" view="3" />
					<view_col id="20" data_type="25" name="plan" order="20" view="3" />
					<view_col id="21" data_type="25" name="comments" order="21" view="3" />
					<view_rowset id="2" p_rowset_order="2" view="3">
						<view_src id="4" match_table="2" name="user_auth" order="4" rowset="2">
							<view_src_col id="9" match_table_col="7" src="4" />
							<view_src_col id="10" match_table_col="8" src="4" />
							<view_src_col id="11" match_table_col="9" src="4" />
							<view_src_col id="12" match_table_col="10" src="4" />
							<view_src_col id="13" match_table_col="11" src="4" />
							<view_src_col id="14" match_table_col="12" src="4" />
							<view_src_col id="15" match_table_col="13" src="4" />
						</view_src>
						<view_src id="5" match_table="3" name="user_profile" order="5" rowset="2">
							<view_src_col id="16" match_table_col="14" src="5" />
							<view_src_col id="17" match_table_col="15" src="5" />
							<view_src_col id="18" match_table_col="16" src="5" />
							<view_src_col id="19" match_table_col="17" src="5" />
							<view_src_col id="20" match_table_col="18" src="5" />
							<view_src_col id="21" match_table_col="19" src="5" />
							<view_src_col id="22" match_table_col="20" src="5" />
							<view_src_col id="23" match_table_col="21" src="5" />
							<view_src_col id="24" match_table_col="22" src="5" />
						</view_src>
						<view_join id="3" join_type="left" lhs_src="4" rhs_src="5" rowset="2">
							<view_join_col id="3" join="3" lhs_src_col="9" rhs_src_col="16" />
						</view_join>
						<view_col_def id="7" expr_type="col" p_expr_order="7" rowset="2" src_col="9" view="3" view_col="7" />
						<view_col_def id="8" expr_type="col" p_expr_order="8" rowset="2" src_col="10" view="3" view_col="8" />
						<view_col_def id="9" expr_type="col" p_expr_order="9" rowset="2" src_col="11" view="3" view_col="9" />
						<view_col_def id="10" expr_type="col" p_expr_order="10" rowset="2" src_col="12" view="3" view_col="10" />
						<view_col_def id="11" expr_type="col" p_expr_order="11" rowset="2" src_col="13" view="3" view_col="11" />
						<view_col_def id="12" expr_type="col" p_expr_order="12" rowset="2" src_col="14" view="3" view_col="12" />
						<view_col_def id="13" expr_type="col" p_expr_order="13" rowset="2" src_col="15" view="3" view_col="13" />
						<view_col_def id="14" expr_type="col" p_expr_order="14" rowset="2" src_col="17" view="3" view_col="14" />
						<view_col_def id="15" expr_type="col" p_expr_order="15" rowset="2" src_col="18" view="3" view_col="15" />
						<view_col_def id="16" expr_type="col" p_expr_order="16" rowset="2" src_col="19" view="3" view_col="16" />
						<view_col_def id="17" expr_type="col" p_expr_order="17" rowset="2" src_col="20" view="3" view_col="17" />
						<view_col_def id="18" expr_type="col" p_expr_order="18" rowset="2" src_col="21" view="3" view_col="18" />
						<view_col_def id="19" expr_type="col" p_expr_order="19" rowset="2" src_col="22" view="3" view_col="19" />
						<view_col_def id="20" expr_type="col" p_expr_order="20" rowset="2" src_col="23" view="3" view_col="20" />
						<view_col_def id="21" expr_type="col" p_expr_order="21" rowset="2" src_col="24" view="3" view_col="21" />
						<view_part_def id="8" expr_type="sfunc" p_expr_order="8" rowset="2" sfunc="eq" view_part="where">
							<view_part_def id="9" expr_type="col" p_expr="8" p_expr_order="9" rowset="2" src_col="9" view_part="where" />
							<view_part_def id="10" command_var="" expr_type="var" p_expr="8" p_expr_order="10" rowset="2" view_part="where" />
						</view_part_def>
					</view_rowset>
				</view>
				<table id="4" name="user_pref" namespace="1" order="4" public_syn="user_pref" storage_file="user">
					<table_col id="23" data_type="9" name="user_id" order="23" required_val="1" table="4" />
					<table_col id="24" data_type="26" name="pref_name" order="24" required_val="1" table="4" />
					<table_col id="25" data_type="27" name="pref_value" order="25" required_val="0" table="4" />
					<table_ind id="11" ind_type="unique" name="primary" order="11" table="4">
						<table_ind_col id="11" order="11" table_col="23" table_ind="11" />
						<table_ind_col id="12" order="12" table_col="24" table_ind="11" />
					</table_ind>
					<table_ind id="12" f_table="2" ind_type="foreign" name="fk_user" order="12" table="4">
						<table_ind_col id="13" f_table_col="7" order="13" table_col="23" table_ind="12" />
					</table_ind>
				</table>
				<view id="4" may_write="0" name="user_theme" namespace="1" view_type="caller">
					<view_col id="22" data_type="27" name="theme_name" order="22" view="4" />
					<view_col id="23" data_type="9" name="theme_count" order="23" view="4" />
					<view_rowset id="3" p_rowset_order="3" view="4">
						<view_src id="6" match_table="4" name="user_pref" order="6" rowset="3">
							<view_src_col id="25" match_table_col="24" src="6" />
							<view_src_col id="26" match_table_col="25" src="6" />
						</view_src>
						<view_col_def id="22" expr_type="col" p_expr_order="22" rowset="3" src_col="26" view="4" view_col="22" />
						<view_col_def id="23" expr_type="sfunc" p_expr_order="23" rowset="3" sfunc="gcount" view="4" view_col="23">
							<view_col_def id="24" expr_type="col" p_expr="23" p_expr_order="24" rowset="3" src_col="26" view="4" view_col="23" />
						</view_col_def>
						<view_part_def id="11" expr_type="sfunc" p_expr_order="11" rowset="3" sfunc="eq" view_part="where">
							<view_part_def id="12" expr_type="col" p_expr="11" p_expr_order="12" rowset="3" src_col="25" view_part="where" />
							<view_part_def id="13" expr_type="lit" lit_val="theme" p_expr="11" p_expr_order="13" rowset="3" view_part="where" />
						</view_part_def>
						<view_part_def id="14" expr_type="col" p_expr_order="14" rowset="3" src_col="26" view_part="group" />
						<view_part_def id="15" expr_type="sfunc" p_expr_order="15" rowset="3" sfunc="gt" view_part="havin">
							<view_part_def id="16" expr_type="sfunc" p_expr="15" p_expr_order="16" rowset="3" sfunc="gcount" view_part="havin" />
							<view_part_def id="17" expr_type="lit" lit_val="1" p_expr="15" p_expr_order="17" rowset="3" view_part="havin" />
						</view_part_def>
					</view_rowset>
				</view>
			</namespace>
		</database>
	</database_list>
	<application_list id="1" />
</root>
';

my $actual_output = $model->get_root_node()->get_all_properties_as_xml_str();

result( $actual_output eq $expected_output, "verify serialization of objects" );

######################################################################

message( "Other functional tests are not written yet; they will come later" );

######################################################################

message( "DONE TESTING SQL::ObjectModel" );

######################################################################

1;
