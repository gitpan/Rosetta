# This module contains test input and output data which is used only by 
# SQL-SyntaxModel-SkipID.t.

package # hide this class name from PAUSE indexer
t_SQL_SyntaxModel_SkipID;
use strict;
use warnings;

######################################################################

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new();

	$model->create_node_trees( [ map { { 'NODE_TYPE' => 'domain', 'ATTRS' => $_ } } (
		{ 'name' => 'bin1k' , 'base_type' => 'STR_BIT', 'max_octets' =>  1_000, },
		{ 'name' => 'bin32k', 'base_type' => 'STR_BIT', 'max_octets' => 32_000, },
		{ 'name' => 'str4'  , 'base_type' => 'STR_CHAR', 'max_chars' =>  4, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 'uc_latin' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'name' => 'str10' , 'base_type' => 'STR_CHAR', 'max_chars' => 10, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'name' => 'str30' , 'base_type' => 'STR_CHAR', 'max_chars' =>    30, 
			'char_enc' => 'ASCII', 'trim_white' => 1, },
		{ 'name' => 'str2k' , 'base_type' => 'STR_CHAR', 'max_chars' => 2_000, 'char_enc' => 'UTF8', },
		{ 'name' => 'byte' , 'base_type' => 'NUM_INT', 'num_scale' =>  3, },
		{ 'name' => 'short', 'base_type' => 'NUM_INT', 'num_scale' =>  5, },
		{ 'name' => 'int'  , 'base_type' => 'NUM_INT', 'num_scale' => 10, },
		{ 'name' => 'long' , 'base_type' => 'NUM_INT', 'num_scale' => 19, },
		{ 'name' => 'ubyte' , 'base_type' => 'NUM_INT', 'num_scale' =>  3, 'num_unsigned' => 1, },
		{ 'name' => 'ushort', 'base_type' => 'NUM_INT', 'num_scale' =>  5, 'num_unsigned' => 1, },
		{ 'name' => 'uint'  , 'base_type' => 'NUM_INT', 'num_scale' => 10, 'num_unsigned' => 1, },
		{ 'name' => 'ulong' , 'base_type' => 'NUM_INT', 'num_scale' => 19, 'num_unsigned' => 1, },
		{ 'name' => 'float' , 'base_type' => 'NUM_APR', 'num_octets' => 4, },
		{ 'name' => 'double', 'base_type' => 'NUM_APR', 'num_octets' => 8, },
		{ 'name' => 'dec10p2', 'base_type' => 'NUM_EXA', 'num_scale' =>  10, 'num_precision' => 2, },
		{ 'name' => 'dec255' , 'base_type' => 'NUM_EXA', 'num_scale' => 255, },
		{ 'name' => 'boolean', 'base_type' => 'BOOLEAN', },
		{ 'name' => 'datetime', 'base_type' => 'DATETIME', 'calendar' => 'ABS', },
		{ 'name' => 'dtchines', 'base_type' => 'DATETIME', 'calendar' => 'CHI', },
		{ 'name' => 'sex'   , 'base_type' => 'STR_CHAR', 'max_chars' =>     1, },
		{ 'name' => 'str20' , 'base_type' => 'STR_CHAR', 'max_chars' =>    20, },
		{ 'name' => 'str100', 'base_type' => 'STR_CHAR', 'max_chars' =>   100, },
		{ 'name' => 'str250', 'base_type' => 'STR_CHAR', 'max_chars' =>   250, },
		{ 'name' => 'entitynm', 'base_type' => 'STR_CHAR', 'max_chars' =>  30, },
		{ 'name' => 'generic' , 'base_type' => 'STR_CHAR', 'max_chars' => 250, },
	) ] );

	$model->create_node_trees( ['catalog', 'user', 'schema'] );

	$model->create_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{
				'name' => 'person_id', 'domain' => 'int', 'mandatory' => 1,
				'default_val' => 1, 'auto_inc' => 1,
			},
			{ 'name' => 'alternate_id', 'domain' => 'str20' , },
			{ 'name' => 'name'        , 'domain' => 'str100', 'mandatory' => 1, },
			{ 'name' => 'sex'         , 'domain' => 'sex'   , },
			{ 'name' => 'father_id'   , 'domain' => 'int'   , },
			{ 'name' => 'mother_id'   , 'domain' => 'int'   , },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'name' => 'primary'        , 'ind_type' => 'UNIQUE', }, 'person_id'    ], 
			[ { 'name' => 'ak_alternate_id', 'ind_type' => 'UNIQUE', }, 'alternate_id' ], 
			[ { 'name' => 'fk_father', 'ind_type' => 'FOREIGN', 'f_table' => 'person', }, 
				{ 'table_col' => 'father_id', 'f_table_col' => 'person_id' } ], 
			[ { 'name' => 'fk_mother', 'ind_type' => 'FOREIGN', 'f_table' => 'person', }, 
				{ 'table_col' => 'mother_id', 'f_table_col' => 'person_id' } ], 
		) ),
	] } );

	$model->create_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'person', 'view_type' => 'TABLE', 'may_write' => 1, 'match_table' => 'person' }, } );

	$model->create_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'person_with_parents', 'may_write' => 0, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'name' => 'self_id'    , 'domain' => 'int'   , },
			{ 'name' => 'self_name'  , 'domain' => 'str100', },
			{ 'name' => 'father_id'  , 'domain' => 'int'   , },
			{ 'name' => 'father_name', 'domain' => 'str100', },
			{ 'name' => 'mother_id'  , 'domain' => 'int'   , },
			{ 'name' => 'mother_name', 'domain' => 'str100', },
		) ),
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => $_, 'match_table' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( person_id name father_id mother_id ) ] 
		} } qw( self ) ),
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => $_, 'match_table' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( person_id name ) ] 
		} } qw( father mother ) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'self', 
				'rhs_src' => 'father', 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'lhs_src_col' => 'father_id', 
				'rhs_src_col' => 'person_id',  } },
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'self', 
				'rhs_src' => 'mother', 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'lhs_src_col' => 'mother_id', 
				'rhs_src_col' => 'person_id',  } },
		] },
		( map { { 'NODE_TYPE' => 'view_expr', 'ATTRS' => $_ } } (
			{ 'view_part' => 'RESULT', 'view_col' => 'self_id'    , 'expr_type' => 'COL', 'src_col' => ['person_id','self'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'self_name'  , 'expr_type' => 'COL', 'src_col' => ['name'     ,'self'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'father_id'  , 'expr_type' => 'COL', 'src_col' => ['person_id','father'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'father_name', 'expr_type' => 'COL', 'src_col' => ['name'     ,'father'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'mother_id'  , 'expr_type' => 'COL', 'src_col' => ['person_id','mother'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'mother_name', 'expr_type' => 'COL', 'src_col' => ['name'     ,'mother'], },
		) ),
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'expr_type' => 'SFUNC', 'sfunc' => 'AND', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'expr_type' => 'SFUNC', 'sfunc' => 'LIKE', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'expr_type' => 'COL', 'src_col' => ['name','father'], }, },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'expr_type' => 'VAR', }, }, #'routine_var' => 'srchw_fa',
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'expr_type' => 'SFUNC', 'sfunc' => 'LIKE', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'expr_type' => 'COL', 'src_col' => ['name','mother'], }, },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'expr_type' => 'VAR', }, }, #'routine_var' => 'srchw_mo',
			] },
		] },
	] } );

	$model->create_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{
				'name' => 'user_id', 'domain' => 'int', 'mandatory' => 1,
				'default_val' => 1, 'auto_inc' => 1,
			},
			{ 'name' => 'login_name'   , 'domain' => 'str20'  , 'mandatory' => 1, },
			{ 'name' => 'login_pass'   , 'domain' => 'str20'  , 'mandatory' => 1, },
			{ 'name' => 'private_name' , 'domain' => 'str100' , 'mandatory' => 1, },
			{ 'name' => 'private_email', 'domain' => 'str100' , 'mandatory' => 1, },
			{ 'name' => 'may_login'    , 'domain' => 'boolean', 'mandatory' => 1, },
			{ 
				'name' => 'max_sessions', 'domain' => 'byte', 'mandatory' => 1, 
				'default_val' => 3, 
			},
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'name' => 'primary'         , 'ind_type' => 'UNIQUE', }, 'user_id'       ],
			[ { 'name' => 'ak_login_name'   , 'ind_type' => 'UNIQUE', }, 'login_name'    ],
			[ { 'name' => 'ak_private_email', 'ind_type' => 'UNIQUE', }, 'private_email' ],
		) ),
	] } );

	$model->create_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'     , 'domain' => 'int'   , 'mandatory' => 1, },
			{ 'name' => 'public_name' , 'domain' => 'str250', 'mandatory' => 1, },
			{ 'name' => 'public_email', 'domain' => 'str250', 'mandatory' => 0, },
			{ 'name' => 'web_url'     , 'domain' => 'str250', 'mandatory' => 0, },
			{ 'name' => 'contact_net' , 'domain' => 'str250', 'mandatory' => 0, },
			{ 'name' => 'contact_phy' , 'domain' => 'str250', 'mandatory' => 0, },
			{ 'name' => 'bio'         , 'domain' => 'str250', 'mandatory' => 0, },
			{ 'name' => 'plan'        , 'domain' => 'str250', 'mandatory' => 0, },
			{ 'name' => 'comments'    , 'domain' => 'str250', 'mandatory' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'name' => 'primary'       , 'ind_type' => 'UNIQUE', }, 'user_id'     ],
			[ { 'name' => 'ak_public_name', 'ind_type' => 'UNIQUE', }, 'public_name' ],
			[ { 'name' => 'fk_user', 'ind_type' => 'FOREIGN', 'f_table' => 'user_auth', }, 
				{ 'table_col' => 'user_id', 'f_table_col' => 'user_id' } ], 
		) ),
	] } );

	$model->create_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'user', 'may_write' => 1, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'      , 'domain' => 'int'    , },
			{ 'name' => 'login_name'   , 'domain' => 'str20'  , },
			{ 'name' => 'login_pass'   , 'domain' => 'str20'  , },
			{ 'name' => 'private_name' , 'domain' => 'str100' , },
			{ 'name' => 'private_email', 'domain' => 'str100' , },
			{ 'name' => 'may_login'    , 'domain' => 'boolean', },
			{ 'name' => 'max_sessions' , 'domain' => 'byte'   , },
			{ 'name' => 'public_name'  , 'domain' => 'str250' , },
			{ 'name' => 'public_email' , 'domain' => 'str250' , },
			{ 'name' => 'web_url'      , 'domain' => 'str250' , },
			{ 'name' => 'contact_net'  , 'domain' => 'str250' , },
			{ 'name' => 'contact_phy'  , 'domain' => 'str250' , },
			{ 'name' => 'bio'          , 'domain' => 'str250' , },
			{ 'name' => 'plan'         , 'domain' => 'str250' , },
			{ 'name' => 'comments'     , 'domain' => 'str250' , },
		) ),
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
				'rhs_src' => 'user_profile', 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'lhs_src_col' => 'user_id', 
				'rhs_src_col' => 'user_id',  } },
		] },
		( map { { 'NODE_TYPE' => 'view_expr', 'ATTRS' => $_ } } (
			{ 'view_part' => 'RESULT', 'view_col' => 'user_id'      , 'expr_type' => 'COL', 'src_col' => ['user_id'      ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'login_name'   , 'expr_type' => 'COL', 'src_col' => ['login_name'   ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'login_pass'   , 'expr_type' => 'COL', 'src_col' => ['login_pass'   ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'private_name' , 'expr_type' => 'COL', 'src_col' => ['private_name' ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'private_email', 'expr_type' => 'COL', 'src_col' => ['private_email','user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'may_login'    , 'expr_type' => 'COL', 'src_col' => ['may_login'    ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'max_sessions' , 'expr_type' => 'COL', 'src_col' => ['max_sessions' ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'view_col' => 'public_name'  , 'expr_type' => 'COL', 'src_col' => ['public_name'  ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'public_email' , 'expr_type' => 'COL', 'src_col' => ['public_email' ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'web_url'      , 'expr_type' => 'COL', 'src_col' => ['web_url'      ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'contact_net'  , 'expr_type' => 'COL', 'src_col' => ['contact_net'  ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'contact_phy'  , 'expr_type' => 'COL', 'src_col' => ['contact_phy'  ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'bio'          , 'expr_type' => 'COL', 'src_col' => ['bio'          ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'plan'         , 'expr_type' => 'COL', 'src_col' => ['plan'         ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'view_col' => 'comments'     , 'expr_type' => 'COL', 'src_col' => ['comments'     ,'user_profile'], },
		) ),
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'expr_type' => 'SFUNC', 'sfunc' => 'EQ', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'COL', 'src_col' => ['user_id','user_auth'], }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'VAR', }, }, #'routine_var' => 'curr_uid',
		] },
	] } );

	$model->create_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'   , 'domain' => 'int'     , 'mandatory' => 1, },
			{ 'name' => 'pref_name' , 'domain' => 'entitynm', 'mandatory' => 1, },
			{ 'name' => 'pref_value', 'domain' => 'generic' , 'mandatory' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
				map { { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_ } } @{$_->[1]}
				] } } (
			[ { 'name' => 'primary', 'ind_type' => 'UNIQUE', }, [ 'user_id', 'pref_name', ], ], 
			[ { 'name' => 'fk_user', 'ind_type' => 'FOREIGN', 'f_table' => 'user_auth', }, 
				[ { 'table_col' => 'user_id', 'f_table_col' => 'user_id' }, ], ], 
		) ),
	] } );

	$model->create_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'user_theme', 'may_write' => 0, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'name' => 'theme_name' , 'domain' => 'generic', },
			{ 'name' => 'theme_count', 'domain' => 'int'    , },
		) ),
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_pref', 'match_table' => 'user_pref', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_col', 'ATTRS' => $_ } } qw( pref_name pref_value ) ] 
		},
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
			'view_col' => 'theme_name', 'expr_type' => 'COL', 'src_col' => ['pref_value','user_pref'], }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
				'view_col' => 'theme_count', 'expr_type' => 'SFUNC', 'sfunc' => 'GCOUNT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'COL', 'src_col' => ['pref_value','user_pref'], }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'expr_type' => 'SFUNC', 'sfunc' => 'EQ', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'COL', 'src_col' => ['pref_name','user_pref'], }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'LIT', 'lit_val' => 'theme', }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'GROUP', 
			'expr_type' => 'COL', 'src_col' => ['pref_value','user_pref'], }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'HAVING', 
				'expr_type' => 'SFUNC', 'sfunc' => 'GT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'SFUNC', 'sfunc' => 'GCOUNT', }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'expr_type' => 'LIT', 'lit_val' => '1', }, },
		] },
	] } );

	return( $model );
}

######################################################################

sub expected_model_xml_output {
	return(
'<root>
	<common_space>
		<domain id="1" name="bin1k" base_type="STR_BIT" max_octets="1000" />
		<domain id="2" name="bin32k" base_type="STR_BIT" max_octets="32000" />
		<domain id="3" name="str4" base_type="STR_CHAR" max_chars="4" store_fixed="1" char_enc="ASCII" trim_white="1" uc_latin="1" pad_char=" " trim_pad="1" />
		<domain id="4" name="str10" base_type="STR_CHAR" max_chars="10" store_fixed="1" char_enc="ASCII" trim_white="1" pad_char=" " trim_pad="1" />
		<domain id="5" name="str30" base_type="STR_CHAR" max_chars="30" char_enc="ASCII" trim_white="1" />
		<domain id="6" name="str2k" base_type="STR_CHAR" max_chars="2000" char_enc="UTF8" />
		<domain id="7" name="byte" base_type="NUM_INT" num_scale="3" />
		<domain id="8" name="short" base_type="NUM_INT" num_scale="5" />
		<domain id="9" name="int" base_type="NUM_INT" num_scale="10" />
		<domain id="10" name="long" base_type="NUM_INT" num_scale="19" />
		<domain id="11" name="ubyte" base_type="NUM_INT" num_scale="3" num_unsigned="1" />
		<domain id="12" name="ushort" base_type="NUM_INT" num_scale="5" num_unsigned="1" />
		<domain id="13" name="uint" base_type="NUM_INT" num_scale="10" num_unsigned="1" />
		<domain id="14" name="ulong" base_type="NUM_INT" num_scale="19" num_unsigned="1" />
		<domain id="15" name="float" base_type="NUM_APR" num_octets="4" />
		<domain id="16" name="double" base_type="NUM_APR" num_octets="8" />
		<domain id="17" name="dec10p2" base_type="NUM_EXA" num_scale="10" num_precision="2" />
		<domain id="18" name="dec255" base_type="NUM_EXA" num_scale="255" />
		<domain id="19" name="boolean" base_type="BOOLEAN" />
		<domain id="20" name="datetime" base_type="DATETIME" calendar="ABS" />
		<domain id="21" name="dtchines" base_type="DATETIME" calendar="CHI" />
		<domain id="22" name="sex" base_type="STR_CHAR" max_chars="1" />
		<domain id="23" name="str20" base_type="STR_CHAR" max_chars="20" />
		<domain id="24" name="str100" base_type="STR_CHAR" max_chars="100" />
		<domain id="25" name="str250" base_type="STR_CHAR" max_chars="250" />
		<domain id="26" name="entitynm" base_type="STR_CHAR" max_chars="30" />
		<domain id="27" name="generic" base_type="STR_CHAR" max_chars="250" />
	</common_space>
	<database_space>
		<catalog id="1">
			<user id="1" catalog="1" />
			<schema id="1" catalog="1" owner="1">
				<table id="1" schema="1" name="person">
					<table_col id="1" table="1" name="person_id" domain="9" mandatory="1" default_val="1" auto_inc="1" />
					<table_col id="2" table="1" name="alternate_id" domain="23" mandatory="0" />
					<table_col id="3" table="1" name="name" domain="24" mandatory="1" />
					<table_col id="4" table="1" name="sex" domain="22" mandatory="0" />
					<table_col id="5" table="1" name="father_id" domain="9" mandatory="0" />
					<table_col id="6" table="1" name="mother_id" domain="9" mandatory="0" />
					<table_ind id="1" table="1" name="primary" ind_type="UNIQUE">
						<table_ind_col id="1" table_ind="1" table_col="1" />
					</table_ind>
					<table_ind id="2" table="1" name="ak_alternate_id" ind_type="UNIQUE">
						<table_ind_col id="2" table_ind="2" table_col="2" />
					</table_ind>
					<table_ind id="3" table="1" name="fk_father" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="3" table_ind="3" table_col="5" f_table_col="1" />
					</table_ind>
					<table_ind id="4" table="1" name="fk_mother" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="4" table_ind="4" table_col="6" f_table_col="1" />
					</table_ind>
				</table>
				<view id="1" view_context="SCHEMA" view_type="TABLE" schema="1" name="person" match_table="1" may_write="1" />
				<view id="2" view_context="SCHEMA" view_type="SIMPLE" schema="1" name="person_with_parents" may_write="0">
					<view_col id="1" view="2" name="self_id" domain="9" />
					<view_col id="2" view="2" name="self_name" domain="24" />
					<view_col id="3" view="2" name="father_id" domain="9" />
					<view_col id="4" view="2" name="father_name" domain="24" />
					<view_col id="5" view="2" name="mother_id" domain="9" />
					<view_col id="6" view="2" name="mother_name" domain="24" />
					<view_src id="1" view="2" name="self" match_table="1">
						<view_src_col id="1" src="1" match_table_col="1" />
						<view_src_col id="2" src="1" match_table_col="3" />
						<view_src_col id="3" src="1" match_table_col="5" />
						<view_src_col id="4" src="1" match_table_col="6" />
					</view_src>
					<view_src id="2" view="2" name="father" match_table="1">
						<view_src_col id="5" src="2" match_table_col="1" />
						<view_src_col id="6" src="2" match_table_col="3" />
					</view_src>
					<view_src id="3" view="2" name="mother" match_table="1">
						<view_src_col id="7" src="3" match_table_col="1" />
						<view_src_col id="8" src="3" match_table_col="3" />
					</view_src>
					<view_join id="1" view="2" lhs_src="1" rhs_src="2" join_type="LEFT">
						<view_join_col id="1" join="1" lhs_src_col="3" rhs_src_col="5" />
					</view_join>
					<view_join id="2" view="2" lhs_src="1" rhs_src="3" join_type="LEFT">
						<view_join_col id="2" join="2" lhs_src_col="4" rhs_src_col="7" />
					</view_join>
					<view_expr id="1" expr_type="COL" view="2" view_part="RESULT" view_col="1" src_col="1" />
					<view_expr id="2" expr_type="COL" view="2" view_part="RESULT" view_col="2" src_col="2" />
					<view_expr id="3" expr_type="COL" view="2" view_part="RESULT" view_col="3" src_col="5" />
					<view_expr id="4" expr_type="COL" view="2" view_part="RESULT" view_col="4" src_col="6" />
					<view_expr id="5" expr_type="COL" view="2" view_part="RESULT" view_col="5" src_col="7" />
					<view_expr id="6" expr_type="COL" view="2" view_part="RESULT" view_col="6" src_col="8" />
					<view_expr id="7" expr_type="SFUNC" view="2" view_part="WHERE" sfunc="AND">
						<view_expr id="8" expr_type="SFUNC" p_expr="7" sfunc="LIKE">
							<view_expr id="9" expr_type="COL" p_expr="8" src_col="6" />
							<view_expr id="10" expr_type="VAR" p_expr="8" />
						</view_expr>
						<view_expr id="11" expr_type="SFUNC" p_expr="7" sfunc="LIKE">
							<view_expr id="12" expr_type="COL" p_expr="11" src_col="8" />
							<view_expr id="13" expr_type="VAR" p_expr="11" />
						</view_expr>
					</view_expr>
				</view>
				<table id="2" schema="1" name="user_auth">
					<table_col id="7" table="2" name="user_id" domain="9" mandatory="1" default_val="1" auto_inc="1" />
					<table_col id="8" table="2" name="login_name" domain="23" mandatory="1" />
					<table_col id="9" table="2" name="login_pass" domain="23" mandatory="1" />
					<table_col id="10" table="2" name="private_name" domain="24" mandatory="1" />
					<table_col id="11" table="2" name="private_email" domain="24" mandatory="1" />
					<table_col id="12" table="2" name="may_login" domain="19" mandatory="1" />
					<table_col id="13" table="2" name="max_sessions" domain="7" mandatory="1" default_val="3" />
					<table_ind id="5" table="2" name="primary" ind_type="UNIQUE">
						<table_ind_col id="5" table_ind="5" table_col="7" />
					</table_ind>
					<table_ind id="6" table="2" name="ak_login_name" ind_type="UNIQUE">
						<table_ind_col id="6" table_ind="6" table_col="8" />
					</table_ind>
					<table_ind id="7" table="2" name="ak_private_email" ind_type="UNIQUE">
						<table_ind_col id="7" table_ind="7" table_col="11" />
					</table_ind>
				</table>
				<table id="3" schema="1" name="user_profile">
					<table_col id="14" table="3" name="user_id" domain="9" mandatory="1" />
					<table_col id="15" table="3" name="public_name" domain="25" mandatory="1" />
					<table_col id="16" table="3" name="public_email" domain="25" mandatory="0" />
					<table_col id="17" table="3" name="web_url" domain="25" mandatory="0" />
					<table_col id="18" table="3" name="contact_net" domain="25" mandatory="0" />
					<table_col id="19" table="3" name="contact_phy" domain="25" mandatory="0" />
					<table_col id="20" table="3" name="bio" domain="25" mandatory="0" />
					<table_col id="21" table="3" name="plan" domain="25" mandatory="0" />
					<table_col id="22" table="3" name="comments" domain="25" mandatory="0" />
					<table_ind id="8" table="3" name="primary" ind_type="UNIQUE">
						<table_ind_col id="8" table_ind="8" table_col="14" />
					</table_ind>
					<table_ind id="9" table="3" name="ak_public_name" ind_type="UNIQUE">
						<table_ind_col id="9" table_ind="9" table_col="15" />
					</table_ind>
					<table_ind id="10" table="3" name="fk_user" ind_type="FOREIGN" f_table="2">
						<table_ind_col id="10" table_ind="10" table_col="14" f_table_col="7" />
					</table_ind>
				</table>
				<view id="3" view_context="SCHEMA" view_type="SIMPLE" schema="1" name="user" may_write="1">
					<view_col id="7" view="3" name="user_id" domain="9" />
					<view_col id="8" view="3" name="login_name" domain="23" />
					<view_col id="9" view="3" name="login_pass" domain="23" />
					<view_col id="10" view="3" name="private_name" domain="24" />
					<view_col id="11" view="3" name="private_email" domain="24" />
					<view_col id="12" view="3" name="may_login" domain="19" />
					<view_col id="13" view="3" name="max_sessions" domain="7" />
					<view_col id="14" view="3" name="public_name" domain="25" />
					<view_col id="15" view="3" name="public_email" domain="25" />
					<view_col id="16" view="3" name="web_url" domain="25" />
					<view_col id="17" view="3" name="contact_net" domain="25" />
					<view_col id="18" view="3" name="contact_phy" domain="25" />
					<view_col id="19" view="3" name="bio" domain="25" />
					<view_col id="20" view="3" name="plan" domain="25" />
					<view_col id="21" view="3" name="comments" domain="25" />
					<view_src id="4" view="3" name="user_auth" match_table="2">
						<view_src_col id="9" src="4" match_table_col="7" />
						<view_src_col id="10" src="4" match_table_col="8" />
						<view_src_col id="11" src="4" match_table_col="9" />
						<view_src_col id="12" src="4" match_table_col="10" />
						<view_src_col id="13" src="4" match_table_col="11" />
						<view_src_col id="14" src="4" match_table_col="12" />
						<view_src_col id="15" src="4" match_table_col="13" />
					</view_src>
					<view_src id="5" view="3" name="user_profile" match_table="3">
						<view_src_col id="16" src="5" match_table_col="14" />
						<view_src_col id="17" src="5" match_table_col="15" />
						<view_src_col id="18" src="5" match_table_col="16" />
						<view_src_col id="19" src="5" match_table_col="17" />
						<view_src_col id="20" src="5" match_table_col="18" />
						<view_src_col id="21" src="5" match_table_col="19" />
						<view_src_col id="22" src="5" match_table_col="20" />
						<view_src_col id="23" src="5" match_table_col="21" />
						<view_src_col id="24" src="5" match_table_col="22" />
					</view_src>
					<view_join id="3" view="3" lhs_src="4" rhs_src="5" join_type="LEFT">
						<view_join_col id="3" join="3" lhs_src_col="9" rhs_src_col="16" />
					</view_join>
					<view_expr id="14" expr_type="COL" view="3" view_part="RESULT" view_col="7" src_col="9" />
					<view_expr id="15" expr_type="COL" view="3" view_part="RESULT" view_col="8" src_col="10" />
					<view_expr id="16" expr_type="COL" view="3" view_part="RESULT" view_col="9" src_col="11" />
					<view_expr id="17" expr_type="COL" view="3" view_part="RESULT" view_col="10" src_col="12" />
					<view_expr id="18" expr_type="COL" view="3" view_part="RESULT" view_col="11" src_col="13" />
					<view_expr id="19" expr_type="COL" view="3" view_part="RESULT" view_col="12" src_col="14" />
					<view_expr id="20" expr_type="COL" view="3" view_part="RESULT" view_col="13" src_col="15" />
					<view_expr id="21" expr_type="COL" view="3" view_part="RESULT" view_col="14" src_col="17" />
					<view_expr id="22" expr_type="COL" view="3" view_part="RESULT" view_col="15" src_col="18" />
					<view_expr id="23" expr_type="COL" view="3" view_part="RESULT" view_col="16" src_col="19" />
					<view_expr id="24" expr_type="COL" view="3" view_part="RESULT" view_col="17" src_col="20" />
					<view_expr id="25" expr_type="COL" view="3" view_part="RESULT" view_col="18" src_col="21" />
					<view_expr id="26" expr_type="COL" view="3" view_part="RESULT" view_col="19" src_col="22" />
					<view_expr id="27" expr_type="COL" view="3" view_part="RESULT" view_col="20" src_col="23" />
					<view_expr id="28" expr_type="COL" view="3" view_part="RESULT" view_col="21" src_col="24" />
					<view_expr id="29" expr_type="SFUNC" view="3" view_part="WHERE" sfunc="EQ">
						<view_expr id="30" expr_type="COL" p_expr="29" src_col="9" />
						<view_expr id="31" expr_type="VAR" p_expr="29" />
					</view_expr>
				</view>
				<table id="4" schema="1" name="user_pref">
					<table_col id="23" table="4" name="user_id" domain="9" mandatory="1" />
					<table_col id="24" table="4" name="pref_name" domain="26" mandatory="1" />
					<table_col id="25" table="4" name="pref_value" domain="27" mandatory="0" />
					<table_ind id="11" table="4" name="primary" ind_type="UNIQUE">
						<table_ind_col id="11" table_ind="11" table_col="23" />
						<table_ind_col id="12" table_ind="11" table_col="24" />
					</table_ind>
					<table_ind id="12" table="4" name="fk_user" ind_type="FOREIGN" f_table="2">
						<table_ind_col id="13" table_ind="12" table_col="23" f_table_col="7" />
					</table_ind>
				</table>
				<view id="4" view_context="SCHEMA" view_type="SIMPLE" schema="1" name="user_theme" may_write="0">
					<view_col id="22" view="4" name="theme_name" domain="27" />
					<view_col id="23" view="4" name="theme_count" domain="9" />
					<view_src id="6" view="4" name="user_pref" match_table="4">
						<view_src_col id="25" src="6" match_table_col="24" />
						<view_src_col id="26" src="6" match_table_col="25" />
					</view_src>
					<view_expr id="32" expr_type="COL" view="4" view_part="RESULT" view_col="22" src_col="26" />
					<view_expr id="33" expr_type="SFUNC" view="4" view_part="RESULT" view_col="23" sfunc="GCOUNT">
						<view_expr id="34" expr_type="COL" p_expr="33" src_col="26" />
					</view_expr>
					<view_expr id="35" expr_type="SFUNC" view="4" view_part="WHERE" sfunc="EQ">
						<view_expr id="36" expr_type="COL" p_expr="35" src_col="25" />
						<view_expr id="37" expr_type="LIT" p_expr="35" lit_val="theme" />
					</view_expr>
					<view_expr id="38" expr_type="COL" view="4" view_part="GROUP" src_col="26" />
					<view_expr id="39" expr_type="SFUNC" view="4" view_part="HAVING" sfunc="GT">
						<view_expr id="40" expr_type="SFUNC" p_expr="39" sfunc="GCOUNT" />
						<view_expr id="41" expr_type="LIT" p_expr="39" lit_val="1" />
					</view_expr>
				</view>
			</schema>
		</catalog>
	</database_space>
	<application_space />
	<circumvention_space />
</root>
'
	);
}

######################################################################

1;
