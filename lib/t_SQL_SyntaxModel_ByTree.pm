# This module contains sample input and output data which is used to test 
# SQL::SyntaxModel::ByTree, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SQL_SyntaxModel_ByTree;
use strict;
use warnings;

######################################################################

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new_container();

	$model->create_node_trees( [ map { { 'NODE_TYPE' => 'domain', 'ATTRS' => $_ } } (
		{ 'id' =>  1, 'name' => 'bin1k' , 'base_type' => 'STR_BIT', 'max_octets' =>  1_000, },
		{ 'id' =>  2, 'name' => 'bin32k', 'base_type' => 'STR_BIT', 'max_octets' => 32_000, },
		{ 'id' =>  3, 'name' => 'str4'  , 'base_type' => 'STR_CHAR', 'max_chars' =>     4, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 'uc_latin' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'id' =>  4, 'name' => 'str10' , 'base_type' => 'STR_CHAR', 'max_chars' =>    10, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'id' =>  5, 'name' => 'str30' , 'base_type' => 'STR_CHAR', 'max_chars' =>    30, 
			'char_enc' => 'ASCII', 'trim_white' => 1, },
		{ 'id' =>  6, 'name' => 'str2k' , 'base_type' => 'STR_CHAR', 'max_chars' => 2_000, 'char_enc' => 'UTF8', },
		{ 'id' =>  7, 'name' => 'byte' , 'base_type' => 'NUM_INT', 'num_scale' =>  3, },
		{ 'id' =>  8, 'name' => 'short', 'base_type' => 'NUM_INT', 'num_scale' =>  5, },
		{ 'id' =>  9, 'name' => 'int'  , 'base_type' => 'NUM_INT', 'num_scale' => 10, },
		{ 'id' => 10, 'name' => 'long' , 'base_type' => 'NUM_INT', 'num_scale' => 19, },
		{ 'id' => 11, 'name' => 'ubyte' , 'base_type' => 'NUM_INT', 'num_scale' =>  3, 'num_unsigned' => 1, },
		{ 'id' => 12, 'name' => 'ushort', 'base_type' => 'NUM_INT', 'num_scale' =>  5, 'num_unsigned' => 1, },
		{ 'id' => 13, 'name' => 'uint'  , 'base_type' => 'NUM_INT', 'num_scale' => 10, 'num_unsigned' => 1, },
		{ 'id' => 14, 'name' => 'ulong' , 'base_type' => 'NUM_INT', 'num_scale' => 19, 'num_unsigned' => 1, },
		{ 'id' => 15, 'name' => 'float' , 'base_type' => 'NUM_APR', 'num_octets' => 4, },
		{ 'id' => 16, 'name' => 'double', 'base_type' => 'NUM_APR', 'num_octets' => 8, },
		{ 'id' => 17, 'name' => 'dec10p2', 'base_type' => 'NUM_EXA', 'num_scale' =>  10, 'num_precision' => 2, },
		{ 'id' => 18, 'name' => 'dec255' , 'base_type' => 'NUM_EXA', 'num_scale' => 255, },
		{ 'id' => 19, 'name' => 'boolean', 'base_type' => 'BOOLEAN', },
		{ 'id' => 20, 'name' => 'datetime', 'base_type' => 'DATETIME', 'calendar' => 'ABS', },
		{ 'id' => 21, 'name' => 'dtchines', 'base_type' => 'DATETIME', 'calendar' => 'CHI', },
		{ 'id' => 22, 'name' => 'sex'   , 'base_type' => 'STR_CHAR', 'max_chars' =>     1, },
		{ 'id' => 23, 'name' => 'str20' , 'base_type' => 'STR_CHAR', 'max_chars' =>    20, },
		{ 'id' => 24, 'name' => 'str100', 'base_type' => 'STR_CHAR', 'max_chars' =>   100, },
		{ 'id' => 25, 'name' => 'str250', 'base_type' => 'STR_CHAR', 'max_chars' =>   250, },
		{ 'id' => 26, 'name' => 'entitynm', 'base_type' => 'STR_CHAR', 'max_chars' =>  30, },
		{ 'id' => 27, 'name' => 'generic' , 'base_type' => 'STR_CHAR', 'max_chars' => 250, },
	) ] );

	my $sex = $model->get_node( 'domain', '22' );
	$sex->create_child_node_trees( [ map { { 'NODE_TYPE' => 'domain_opt', 'ATTRS' => $_ } } (
		{ 'id' =>  1, 'value' => 'M', },
		{ 'id' =>  2, 'value' => 'F', },
	) ] );

	my $catalog = $model->create_node_tree( { 'NODE_TYPE' => 'catalog', 'ATTRS' => { 'id' => 1, }, 
		'CHILDREN' => [ { 'NODE_TYPE' => 'owner', 'ATTRS' => { 'id' =>  1, } } ] } ); 

	my $schema = $catalog->create_child_node_tree( { 'NODE_TYPE' => 'schema', 'ATTRS' => { 'id' => 1, 'owner' => 1, } } ); 

	$schema->create_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 4, 'name' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{
				'id' => 20, 'name' => 'person_id', 'domain' => 9, 'mandatory' => 1,
				'default_val' => 1, 'auto_inc' => 1,
			},
			{ 'id' => 21, 'name' => 'alternate_id', 'domain' => 23, 'mandatory' => 0, },
			{ 'id' => 22, 'name' => 'name'        , 'domain' => 24, 'mandatory' => 1, },
			{ 'id' => 23, 'name' => 'sex'         , 'domain' => 22, 'mandatory' => 0, },
			{ 'id' => 24, 'name' => 'father_id'   , 'domain' =>  9, 'mandatory' => 0, },
			{ 'id' => 25, 'name' => 'mother_id'   , 'domain' =>  9, 'mandatory' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'id' =>  9, 'name' => 'primary'        , 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 10, 'table_col' => 20, }, ], 
			[ { 'id' => 10, 'name' => 'ak_alternate_id', 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 11, 'table_col' => 21, }, ], 
			[ { 'id' => 11, 'name' => 'fk_father', 'ind_type' => 'FOREIGN', 'f_table' => 4, }, 
				{ 'id' => 12, 'table_col' => 24, 'f_table_col' => 20 }, ], 
			[ { 'id' => 12, 'name' => 'fk_mother', 'ind_type' => 'FOREIGN', 'f_table' => 4, }, 
				{ 'id' => 13, 'table_col' => 25, 'f_table_col' => 20 }, ], 
		) ),
	] } );

	$schema->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 2, 
			'view_context' => 'SCHEMA', 'view_type' => 'MULTIPLE', 
			'name' => 'person_with_parents', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 3, 'name' => 'self'  , 
				'match_table' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 17, 'match_table_col' => 20, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 18, 'match_table_col' => 22, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 25, 'match_table_col' => 24, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 26, 'match_table_col' => 25, }, },
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 4, 'name' => 'father', 
				'match_table' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 19, 'match_table_col' => 20, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 20, 'match_table_col' => 22, }, },
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 5, 'name' => 'mother', 
				'match_table' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 21, 'match_table_col' => 20, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 22, 'match_table_col' => 22, }, },
		] },
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'id' => 16, 'name' => 'self_id'    , 'domain' =>  9, 'src_col' => 17, },
			{ 'id' => 17, 'name' => 'self_name'  , 'domain' => 24, 'src_col' => 18, },
			{ 'id' => 18, 'name' => 'father_id'  , 'domain' =>  9, 'src_col' => 19, },
			{ 'id' => 19, 'name' => 'father_name', 'domain' => 24, 'src_col' => 20, },
			{ 'id' => 20, 'name' => 'mother_id'  , 'domain' =>  9, 'src_col' => 21, },
			{ 'id' => 21, 'name' => 'mother_name', 'domain' => 24, 'src_col' => 22, },
		) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 2, 'lhs_src' => 3, 
				'rhs_src' => 4, 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 2, 'lhs_src_col' => 25, 'rhs_src_col' => 19, } },
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 3, 'lhs_src' => 3, 
				'rhs_src' => 5, 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 3, 'lhs_src_col' => 26, 'rhs_src_col' => 21, } },
		] },
	] } );

	$schema->create_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 1, 'name' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{
				'id' => 1, 'name' => 'user_id', 'domain' => 9, 'mandatory' => 1,
				'default_val' => 1, 'auto_inc' => 1,
			},
			{ 'id' => 2, 'name' => 'login_name'   , 'domain' => 23, 'mandatory' => 1, },
			{ 'id' => 3, 'name' => 'login_pass'   , 'domain' => 23, 'mandatory' => 1, },
			{ 'id' => 4, 'name' => 'private_name' , 'domain' => 24, 'mandatory' => 1, },
			{ 'id' => 5, 'name' => 'private_email', 'domain' => 24, 'mandatory' => 1, },
			{ 'id' => 6, 'name' => 'may_login'    , 'domain' => 19, 'mandatory' => 1, },
			{ 
				'id' => 7, 'name' => 'max_sessions', 'domain' => 7, 'mandatory' => 1, 
				'default_val' => 3, 
			},
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'id' => 1, 'name' => 'primary'         , 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 1, 'table_col' => 1, }, ], 
			[ { 'id' => 2, 'name' => 'ak_login_name'   , 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 2, 'table_col' => 2, }, ], 
			[ { 'id' => 3, 'name' => 'ak_private_email', 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 3, 'table_col' => 5, }, ], 
		) ),
	] } );

	$schema->create_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 2, 'name' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{ 'id' =>  8, 'name' => 'user_id'     , 'domain' =>  9, 'mandatory' => 1, },
			{ 'id' =>  9, 'name' => 'public_name' , 'domain' => 25, 'mandatory' => 1, },
			{ 'id' => 10, 'name' => 'public_email', 'domain' => 25, 'mandatory' => 0, },
			{ 'id' => 11, 'name' => 'web_url'     , 'domain' => 25, 'mandatory' => 0, },
			{ 'id' => 12, 'name' => 'contact_net' , 'domain' => 25, 'mandatory' => 0, },
			{ 'id' => 13, 'name' => 'contact_phy' , 'domain' => 25, 'mandatory' => 0, },
			{ 'id' => 14, 'name' => 'bio'         , 'domain' => 25, 'mandatory' => 0, },
			{ 'id' => 15, 'name' => 'plan'        , 'domain' => 25, 'mandatory' => 0, },
			{ 'id' => 16, 'name' => 'comments'    , 'domain' => 25, 'mandatory' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'id' => 4, 'name' => 'primary'       , 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 4, 'table_col' => 8, }, ], 
			[ { 'id' => 5, 'name' => 'ak_public_name', 'ind_type' => 'UNIQUE', }, 
				{ 'id' => 5, 'table_col' => 9, }, ], 
			[ { 'id' => 6, 'name' => 'fk_user'       , 'ind_type' => 'FOREIGN', 'f_table' => 1, }, 
				{ 'id' => 6, 'table_col' => 8, 'f_table_col' => 1 }, ], 
		) ),
	] } );

	$schema->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 1, 
			'view_context' => 'SCHEMA', 'view_type' => 'MULTIPLE', 
			'name' => 'user', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 1, 'name' => 'user_auth', 
				'match_table' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  1, 'match_table_col' =>  1, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  2, 'match_table_col' =>  2, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  3, 'match_table_col' =>  3, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  4, 'match_table_col' =>  4, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  5, 'match_table_col' =>  5, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  6, 'match_table_col' =>  6, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  7, 'match_table_col' =>  7, }, },
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 2, 'name' => 'user_profile', 
				'match_table' => 2, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  8, 'match_table_col' =>  8, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  9, 'match_table_col' =>  9, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 10, 'match_table_col' => 10, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 11, 'match_table_col' => 11, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 12, 'match_table_col' => 12, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 13, 'match_table_col' => 13, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 14, 'match_table_col' => 14, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 15, 'match_table_col' => 15, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 16, 'match_table_col' => 16, }, },
		] },
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'id' =>  1, 'name' => 'user_id'      , 'domain' =>  9, 'src_col' =>  1, },
			{ 'id' =>  2, 'name' => 'login_name'   , 'domain' => 23, 'src_col' =>  2, },
			{ 'id' =>  3, 'name' => 'login_pass'   , 'domain' => 23, 'src_col' =>  3, },
			{ 'id' =>  4, 'name' => 'private_name' , 'domain' => 24, 'src_col' =>  4, },
			{ 'id' =>  5, 'name' => 'private_email', 'domain' => 24, 'src_col' =>  5, },
			{ 'id' =>  6, 'name' => 'may_login'    , 'domain' => 19, 'src_col' =>  6, },
			{ 'id' =>  7, 'name' => 'max_sessions' , 'domain' =>  7, 'src_col' =>  7, },
			{ 'id' =>  8, 'name' => 'public_name'  , 'domain' => 25, 'src_col' =>  9, },
			{ 'id' =>  9, 'name' => 'public_email' , 'domain' => 25, 'src_col' => 10, },
			{ 'id' => 10, 'name' => 'web_url'      , 'domain' => 25, 'src_col' => 11, },
			{ 'id' => 11, 'name' => 'contact_net'  , 'domain' => 25, 'src_col' => 12, },
			{ 'id' => 12, 'name' => 'contact_phy'  , 'domain' => 25, 'src_col' => 13, },
			{ 'id' => 13, 'name' => 'bio'          , 'domain' => 25, 'src_col' => 14, },
			{ 'id' => 14, 'name' => 'plan'         , 'domain' => 25, 'src_col' => 15, },
			{ 'id' => 15, 'name' => 'comments'     , 'domain' => 25, 'src_col' => 16, },
		) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 1, 'lhs_src' => 1, 
				'rhs_src' => 2, 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 1, 'lhs_src_col' => 1, 'rhs_src_col' => 8, } },
		] },
	] } );

	$schema->create_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 3, 'name' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{ 'id' => 17, 'name' => 'user_id'   , 'domain' =>  9, 'mandatory' => 1, },
			{ 'id' => 18, 'name' => 'pref_name' , 'domain' => 26, 'mandatory' => 1, },
			{ 'id' => 19, 'name' => 'pref_value', 'domain' => 27, 'mandatory' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
				map { { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_ } } @{$_->[1]}
				] } } (
			[ { 'id' => 7, 'name' => 'primary', 'ind_type' => 'UNIQUE', },
				[ { 'id' => 7, 'table_col' => 17, }, 
				{ 'id' => 8, 'table_col' => 18, }, ],
			], 
			[ { 'id' => 8, 'name' => 'fk_user', 'ind_type' => 'FOREIGN', 'f_table' => 1, }, 
				[ { 'id' => 9, 'table_col' => 17, 'f_table_col' => 1 }, ],
			], 
		) ),
	] } );

	my $application = $model->create_node_tree( { 'NODE_TYPE' => 'application', 'ATTRS' => { 'id' => 1, }, } ); 

	$application->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 3, 
			'view_context' => 'APPLIC', 'view_type' => 'SINGLE', 
			'name' => 'user_theme', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 6, 'name' => 'user_pref', 
			'match_table' => 3, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 23, 'match_table_col' => 18, }, },
			{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 24, 'match_table_col' => 19, }, },
		] },
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'id' => 22, 'name' => 'theme_name' , 'domain' => 27, },
			{ 'id' => 23, 'name' => 'theme_count', 'domain' =>  9, },
		) ),
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
			'id' => 42, 'view_col' => 22, 'expr_type' => 'COL', 'src_col' => 24, }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
			'id' => 43, 'view_col' => 23, 'expr_type' => 'SFUNC', 'sfunc' => 'GCOUNT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 44, 'expr_type' => 'COL', 'src_col' => 24, }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'id' => 11, 'expr_type' => 'SFUNC', 'sfunc' => 'EQ', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 12, 'expr_type' => 'COL', 'src_col' => 23, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 13, 'expr_type' => 'LIT', 'lit_val' => 'theme', }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'GROUP', 
			'id' => 14, 'expr_type' => 'COL', 'src_col' => 24, }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'HAVING', 
				'id' => 15, 'expr_type' => 'SFUNC', 'sfunc' => 'GT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 16, 'expr_type' => 'SFUNC', 'sfunc' => 'GCOUNT', }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 17, 'expr_type' => 'LIT', 'lit_val' => '1', }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
			'id' => 55, 'expr_type' => 'MCOL', 'match_col' => 23, }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
			'id' => 56, 'expr_type' => 'MCOL', 'match_col' => 22, }, },
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 1, 'routine_type' => 'ANONYMOUS', 'name' => 'get_user', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 1, 'name' => 'curr_uid', }, },
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 5, 'view_context' => 'ROUTINE', 
				'view_type' => 'MATCH', 'match_all_cols' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 8, 'name' => 'm', 'match_view' => 1, }, 
					'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 30, 'match_view_col' => 1, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 31, 'match_view_col' => 2, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
					'id' => 1, 'expr_type' => 'SFUNC', 'sfunc' => 'EQ', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'id' => 2, 'expr_type' => 'COL', 'src_col' => 30, }, },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'id' => 3, 'expr_type' => 'ARG', 'routine_arg' => 1, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 51, 'expr_type' => 'COL', 'src_col' => 31, }, },
		] },
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 2, 'routine_type' => 'ANONYMOUS', 'name' => 'get_pwp', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 2, 'name' => 'srchw_fa', }, },
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 3, 'name' => 'srchw_mo', }, },
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 6, 'view_context' => 'ROUTINE', 
				'view_type' => 'MATCH', 'match_all_cols' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 9, 'name' => 'm', 'match_view' => 2, }, 
					'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 27, 'match_view_col' => 17, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 28, 'match_view_col' => 19, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 29, 'match_view_col' => 21, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
					'id' => 4, 'expr_type' => 'SFUNC', 'sfunc' => 'AND', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 5, 'expr_type' => 'SFUNC', 'sfunc' => 'LIKE', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 6, 'expr_type' => 'COL', 'src_col' => 28, }, },
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 7, 'expr_type' => 'ARG', 'routine_arg' => 2, }, },
				] },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 8, 'expr_type' => 'SFUNC', 'sfunc' => 'LIKE', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 9, 'expr_type' => 'COL', 'src_col' => 29, }, },
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 10, 'expr_type' => 'ARG', 'routine_arg' => 3, }, },
				] },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 52, 'expr_type' => 'COL', 'src_col' => 27, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 53, 'expr_type' => 'COL', 'src_col' => 28, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 54, 'expr_type' => 'COL', 'src_col' => 29, }, },
		] },
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 3, 'routine_type' => 'ANONYMOUS', 'name' => 'get_theme', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 7, 'view_context' => 'ROUTINE', 
				'view_type' => 'MATCH', 'match_all_cols' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 10, 'name' => 'm', 'match_view' => 3, }, },
		] },
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 4, 'routine_type' => 'ANONYMOUS', 'name' => 'get_person', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 4, 'view_context' => 'ROUTINE', 'view_type' => 'MATCH', 
				'match_all_cols' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 7, 'name' => 'person', 'match_table' => 4, }, },
		] }
	] } );

	return( $model );
}

######################################################################

sub expected_model_xml_output {
	return(
'<root>
	<elements>
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
		<domain id="22" name="sex" base_type="STR_CHAR" max_chars="1">
			<domain_opt id="1" domain="22" value="M" />
			<domain_opt id="2" domain="22" value="F" />
		</domain>
		<domain id="23" name="str20" base_type="STR_CHAR" max_chars="20" />
		<domain id="24" name="str100" base_type="STR_CHAR" max_chars="100" />
		<domain id="25" name="str250" base_type="STR_CHAR" max_chars="250" />
		<domain id="26" name="entitynm" base_type="STR_CHAR" max_chars="30" />
		<domain id="27" name="generic" base_type="STR_CHAR" max_chars="250" />
	</elements>
	<blueprints>
		<catalog id="1">
			<owner id="1" catalog="1" />
			<schema id="1" catalog="1" owner="1">
				<table id="4" schema="1" name="person">
					<table_col id="20" table="4" name="person_id" domain="9" mandatory="1" default_val="1" auto_inc="1" />
					<table_col id="21" table="4" name="alternate_id" domain="23" mandatory="0" />
					<table_col id="22" table="4" name="name" domain="24" mandatory="1" />
					<table_col id="23" table="4" name="sex" domain="22" mandatory="0" />
					<table_col id="24" table="4" name="father_id" domain="9" mandatory="0" />
					<table_col id="25" table="4" name="mother_id" domain="9" mandatory="0" />
					<table_ind id="9" table="4" name="primary" ind_type="UNIQUE">
						<table_ind_col id="10" table_ind="9" table_col="20" />
					</table_ind>
					<table_ind id="10" table="4" name="ak_alternate_id" ind_type="UNIQUE">
						<table_ind_col id="11" table_ind="10" table_col="21" />
					</table_ind>
					<table_ind id="11" table="4" name="fk_father" ind_type="FOREIGN" f_table="4">
						<table_ind_col id="12" table_ind="11" table_col="24" f_table_col="20" />
					</table_ind>
					<table_ind id="12" table="4" name="fk_mother" ind_type="FOREIGN" f_table="4">
						<table_ind_col id="13" table_ind="12" table_col="25" f_table_col="20" />
					</table_ind>
				</table>
				<view id="2" view_context="SCHEMA" view_type="MULTIPLE" schema="1" name="person_with_parents">
					<view_src id="3" view="2" name="self" match_table="4">
						<view_src_col id="17" src="3" match_table_col="20" />
						<view_src_col id="18" src="3" match_table_col="22" />
						<view_src_col id="25" src="3" match_table_col="24" />
						<view_src_col id="26" src="3" match_table_col="25" />
					</view_src>
					<view_src id="4" view="2" name="father" match_table="4">
						<view_src_col id="19" src="4" match_table_col="20" />
						<view_src_col id="20" src="4" match_table_col="22" />
					</view_src>
					<view_src id="5" view="2" name="mother" match_table="4">
						<view_src_col id="21" src="5" match_table_col="20" />
						<view_src_col id="22" src="5" match_table_col="22" />
					</view_src>
					<view_col id="16" view="2" name="self_id" domain="9" src_col="17" />
					<view_col id="17" view="2" name="self_name" domain="24" src_col="18" />
					<view_col id="18" view="2" name="father_id" domain="9" src_col="19" />
					<view_col id="19" view="2" name="father_name" domain="24" src_col="20" />
					<view_col id="20" view="2" name="mother_id" domain="9" src_col="21" />
					<view_col id="21" view="2" name="mother_name" domain="24" src_col="22" />
					<view_join id="2" view="2" lhs_src="3" rhs_src="4" join_type="LEFT">
						<view_join_col id="2" join="2" lhs_src_col="25" rhs_src_col="19" />
					</view_join>
					<view_join id="3" view="2" lhs_src="3" rhs_src="5" join_type="LEFT">
						<view_join_col id="3" join="3" lhs_src_col="26" rhs_src_col="21" />
					</view_join>
				</view>
				<table id="1" schema="1" name="user_auth">
					<table_col id="1" table="1" name="user_id" domain="9" mandatory="1" default_val="1" auto_inc="1" />
					<table_col id="2" table="1" name="login_name" domain="23" mandatory="1" />
					<table_col id="3" table="1" name="login_pass" domain="23" mandatory="1" />
					<table_col id="4" table="1" name="private_name" domain="24" mandatory="1" />
					<table_col id="5" table="1" name="private_email" domain="24" mandatory="1" />
					<table_col id="6" table="1" name="may_login" domain="19" mandatory="1" />
					<table_col id="7" table="1" name="max_sessions" domain="7" mandatory="1" default_val="3" />
					<table_ind id="1" table="1" name="primary" ind_type="UNIQUE">
						<table_ind_col id="1" table_ind="1" table_col="1" />
					</table_ind>
					<table_ind id="2" table="1" name="ak_login_name" ind_type="UNIQUE">
						<table_ind_col id="2" table_ind="2" table_col="2" />
					</table_ind>
					<table_ind id="3" table="1" name="ak_private_email" ind_type="UNIQUE">
						<table_ind_col id="3" table_ind="3" table_col="5" />
					</table_ind>
				</table>
				<table id="2" schema="1" name="user_profile">
					<table_col id="8" table="2" name="user_id" domain="9" mandatory="1" />
					<table_col id="9" table="2" name="public_name" domain="25" mandatory="1" />
					<table_col id="10" table="2" name="public_email" domain="25" mandatory="0" />
					<table_col id="11" table="2" name="web_url" domain="25" mandatory="0" />
					<table_col id="12" table="2" name="contact_net" domain="25" mandatory="0" />
					<table_col id="13" table="2" name="contact_phy" domain="25" mandatory="0" />
					<table_col id="14" table="2" name="bio" domain="25" mandatory="0" />
					<table_col id="15" table="2" name="plan" domain="25" mandatory="0" />
					<table_col id="16" table="2" name="comments" domain="25" mandatory="0" />
					<table_ind id="4" table="2" name="primary" ind_type="UNIQUE">
						<table_ind_col id="4" table_ind="4" table_col="8" />
					</table_ind>
					<table_ind id="5" table="2" name="ak_public_name" ind_type="UNIQUE">
						<table_ind_col id="5" table_ind="5" table_col="9" />
					</table_ind>
					<table_ind id="6" table="2" name="fk_user" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="6" table_ind="6" table_col="8" f_table_col="1" />
					</table_ind>
				</table>
				<view id="1" view_context="SCHEMA" view_type="MULTIPLE" schema="1" name="user">
					<view_src id="1" view="1" name="user_auth" match_table="1">
						<view_src_col id="1" src="1" match_table_col="1" />
						<view_src_col id="2" src="1" match_table_col="2" />
						<view_src_col id="3" src="1" match_table_col="3" />
						<view_src_col id="4" src="1" match_table_col="4" />
						<view_src_col id="5" src="1" match_table_col="5" />
						<view_src_col id="6" src="1" match_table_col="6" />
						<view_src_col id="7" src="1" match_table_col="7" />
					</view_src>
					<view_src id="2" view="1" name="user_profile" match_table="2">
						<view_src_col id="8" src="2" match_table_col="8" />
						<view_src_col id="9" src="2" match_table_col="9" />
						<view_src_col id="10" src="2" match_table_col="10" />
						<view_src_col id="11" src="2" match_table_col="11" />
						<view_src_col id="12" src="2" match_table_col="12" />
						<view_src_col id="13" src="2" match_table_col="13" />
						<view_src_col id="14" src="2" match_table_col="14" />
						<view_src_col id="15" src="2" match_table_col="15" />
						<view_src_col id="16" src="2" match_table_col="16" />
					</view_src>
					<view_col id="1" view="1" name="user_id" domain="9" src_col="1" />
					<view_col id="2" view="1" name="login_name" domain="23" src_col="2" />
					<view_col id="3" view="1" name="login_pass" domain="23" src_col="3" />
					<view_col id="4" view="1" name="private_name" domain="24" src_col="4" />
					<view_col id="5" view="1" name="private_email" domain="24" src_col="5" />
					<view_col id="6" view="1" name="may_login" domain="19" src_col="6" />
					<view_col id="7" view="1" name="max_sessions" domain="7" src_col="7" />
					<view_col id="8" view="1" name="public_name" domain="25" src_col="9" />
					<view_col id="9" view="1" name="public_email" domain="25" src_col="10" />
					<view_col id="10" view="1" name="web_url" domain="25" src_col="11" />
					<view_col id="11" view="1" name="contact_net" domain="25" src_col="12" />
					<view_col id="12" view="1" name="contact_phy" domain="25" src_col="13" />
					<view_col id="13" view="1" name="bio" domain="25" src_col="14" />
					<view_col id="14" view="1" name="plan" domain="25" src_col="15" />
					<view_col id="15" view="1" name="comments" domain="25" src_col="16" />
					<view_join id="1" view="1" lhs_src="1" rhs_src="2" join_type="LEFT">
						<view_join_col id="1" join="1" lhs_src_col="1" rhs_src_col="8" />
					</view_join>
				</view>
				<table id="3" schema="1" name="user_pref">
					<table_col id="17" table="3" name="user_id" domain="9" mandatory="1" />
					<table_col id="18" table="3" name="pref_name" domain="26" mandatory="1" />
					<table_col id="19" table="3" name="pref_value" domain="27" mandatory="0" />
					<table_ind id="7" table="3" name="primary" ind_type="UNIQUE">
						<table_ind_col id="7" table_ind="7" table_col="17" />
						<table_ind_col id="8" table_ind="7" table_col="18" />
					</table_ind>
					<table_ind id="8" table="3" name="fk_user" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="9" table_ind="8" table_col="17" f_table_col="1" />
					</table_ind>
				</table>
			</schema>
		</catalog>
		<application id="1">
			<view id="3" view_context="APPLIC" view_type="SINGLE" name="user_theme" application="1">
				<view_src id="6" view="3" name="user_pref" match_table="3">
					<view_src_col id="23" src="6" match_table_col="18" />
					<view_src_col id="24" src="6" match_table_col="19" />
				</view_src>
				<view_col id="22" view="3" name="theme_name" domain="27" />
				<view_col id="23" view="3" name="theme_count" domain="9" />
				<view_expr id="42" expr_type="COL" view="3" view_part="RESULT" view_col="22" src_col="24" />
				<view_expr id="43" expr_type="SFUNC" view="3" view_part="RESULT" view_col="23">
					<view_expr id="44" expr_type="COL" p_expr="43" src_col="24" />
				</view_expr>
				<view_expr id="11" expr_type="SFUNC" view="3" view_part="WHERE">
					<view_expr id="12" expr_type="COL" p_expr="11" src_col="23" />
					<view_expr id="13" expr_type="LIT" p_expr="11" lit_val="theme" />
				</view_expr>
				<view_expr id="14" expr_type="COL" view="3" view_part="GROUP" src_col="24" />
				<view_expr id="15" expr_type="SFUNC" view="3" view_part="HAVING">
					<view_expr id="16" expr_type="SFUNC" p_expr="15" />
					<view_expr id="17" expr_type="LIT" p_expr="15" lit_val="1" />
				</view_expr>
				<view_expr id="55" expr_type="MCOL" view="3" view_part="ORDER" match_col="23" />
				<view_expr id="56" expr_type="MCOL" view="3" view_part="ORDER" match_col="22" />
			</view>
			<routine id="1" routine_type="ANONYMOUS" application="1" name="get_user">
				<routine_arg id="1" routine="1" name="curr_uid" />
				<view id="5" view_context="ROUTINE" view_type="MATCH" routine="1" match_all_cols="1">
					<view_src id="8" view="5" name="m" match_view="1">
						<view_src_col id="30" src="8" match_view_col="1" />
						<view_src_col id="31" src="8" match_view_col="2" />
					</view_src>
					<view_expr id="1" expr_type="SFUNC" view="5" view_part="WHERE">
						<view_expr id="2" expr_type="COL" p_expr="1" src_col="30" />
						<view_expr id="3" expr_type="ARG" p_expr="1" routine_arg="1" />
					</view_expr>
					<view_expr id="51" expr_type="COL" view="5" view_part="ORDER" src_col="31" />
				</view>
			</routine>
			<routine id="2" routine_type="ANONYMOUS" application="1" name="get_pwp">
				<routine_arg id="2" routine="2" name="srchw_fa" />
				<routine_arg id="3" routine="2" name="srchw_mo" />
				<view id="6" view_context="ROUTINE" view_type="MATCH" routine="2" match_all_cols="1">
					<view_src id="9" view="6" name="m" match_view="2">
						<view_src_col id="27" src="9" match_view_col="17" />
						<view_src_col id="28" src="9" match_view_col="19" />
						<view_src_col id="29" src="9" match_view_col="21" />
					</view_src>
					<view_expr id="4" expr_type="SFUNC" view="6" view_part="WHERE">
						<view_expr id="5" expr_type="SFUNC" p_expr="4">
							<view_expr id="6" expr_type="COL" p_expr="5" src_col="28" />
							<view_expr id="7" expr_type="ARG" p_expr="5" routine_arg="2" />
						</view_expr>
						<view_expr id="8" expr_type="SFUNC" p_expr="4">
							<view_expr id="9" expr_type="COL" p_expr="8" src_col="29" />
							<view_expr id="10" expr_type="ARG" p_expr="8" routine_arg="3" />
						</view_expr>
					</view_expr>
					<view_expr id="52" expr_type="COL" view="6" view_part="ORDER" src_col="27" />
					<view_expr id="53" expr_type="COL" view="6" view_part="ORDER" src_col="28" />
					<view_expr id="54" expr_type="COL" view="6" view_part="ORDER" src_col="29" />
				</view>
			</routine>
			<routine id="3" routine_type="ANONYMOUS" application="1" name="get_theme">
				<view id="7" view_context="ROUTINE" view_type="MATCH" routine="3" match_all_cols="1">
					<view_src id="10" view="7" name="m" match_view="3" />
				</view>
			</routine>
			<routine id="4" routine_type="ANONYMOUS" application="1" name="get_person">
				<view id="4" view_context="ROUTINE" view_type="MATCH" routine="4" match_all_cols="1">
					<view_src id="7" view="4" name="person" match_table="4" />
				</view>
			</routine>
		</application>
	</blueprints>
	<tools />
	<sites />
	<circumventions />
</root>
'
	);
}

######################################################################

1;
