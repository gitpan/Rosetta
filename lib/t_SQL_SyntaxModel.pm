# This module contains test input and output data which is used in common 
# between SQL-SyntaxModel.t and SQL-SyntaxModel-SkipID.t.

package # hide this class name from PAUSE indexer
t_SQL_SyntaxModel;
use strict;
use warnings;

######################################################################

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new();

	$model->create_nodes( [ map { { 'NODE_TYPE' => 'data_type', 'ATTRS' => $_ } } (
		{ 'id' =>  1, 'name' => 'bin1k' , 'basic_type' => 'bin', 'size_in_bytes' =>  1_000, },
		{ 'id' =>  2, 'name' => 'bin32k', 'basic_type' => 'bin', 'size_in_bytes' => 32_000, },
		{ 'id' =>  3, 'name' => 'str4'  , 'basic_type' => 'str', 'size_in_chars' =>  4, 'store_fixed' => 1, 
			'str_encoding' => 'asc', 'str_trim_white' => 1, 'str_latin_case' => 'uc', 
			'str_pad_char' => ' ', 'str_trim_pad' => 1, },
		{ 'id' =>  4, 'name' => 'str10' , 'basic_type' => 'str', 'size_in_chars' => 10, 'store_fixed' => 1, 
			'str_encoding' => 'asc', 'str_trim_white' => 1, 'str_latin_case' => 'pr', 
			'str_pad_char' => ' ', 'str_trim_pad' => 1, },
		{ 'id' =>  5, 'name' => 'str30' , 'basic_type' => 'str', 'size_in_chars' =>    30, 
			'str_encoding' => 'asc', 'str_trim_white' => 1, },
		{ 'id' =>  6, 'name' => 'str2k' , 'basic_type' => 'str', 'size_in_chars' => 2_000, 'str_encoding' => 'u16', },
		{ 'id' =>  7, 'name' => 'byte' , 'basic_type' => 'num', 'size_in_bytes' => 1, 'num_precision' => 0, }, #  3 digits
		{ 'id' =>  8, 'name' => 'short', 'basic_type' => 'num', 'size_in_bytes' => 2, 'num_precision' => 0, }, #  5 digits
		{ 'id' =>  9, 'name' => 'int'  , 'basic_type' => 'num', 'size_in_bytes' => 4, 'num_precision' => 0, }, # 10 digits
		{ 'id' => 10, 'name' => 'long' , 'basic_type' => 'num', 'size_in_bytes' => 8, 'num_precision' => 0, }, # 19 digits
		{ 'id' => 11, 'name' => 'ubyte' , 'basic_type' => 'num', 'size_in_bytes' => 1, 
			'num_unsigned' => 1, 'num_precision' => 0, }, #  3 digits
		{ 'id' => 12, 'name' => 'ushort', 'basic_type' => 'num', 'size_in_bytes' => 2, 
			'num_unsigned' => 1, 'num_precision' => 0, }, #  5 digits
		{ 'id' => 13, 'name' => 'uint'  , 'basic_type' => 'num', 'size_in_bytes' => 4, 
			'num_unsigned' => 1, 'num_precision' => 0, }, # 10 digits
		{ 'id' => 14, 'name' => 'ulong' , 'basic_type' => 'num', 'size_in_bytes' => 8, 
			'num_unsigned' => 1, 'num_precision' => 0, }, # 19 digits
		{ 'id' => 15, 'name' => 'float' , 'basic_type' => 'num', 'size_in_bytes' => 4, },
		{ 'id' => 16, 'name' => 'double', 'basic_type' => 'num', 'size_in_bytes' => 8, },
		{ 'id' => 17, 'name' => 'dec10p2', 'basic_type' => 'num', 'size_in_digits' =>  10, 'num_precision' => 2, },
		{ 'id' => 18, 'name' => 'dec255' , 'basic_type' => 'num', 'size_in_digits' => 255, },
		{ 'id' => 19, 'name' => 'boolean', 'basic_type' => 'bool', },
		{ 'id' => 20, 'name' => 'datetime', 'basic_type' => 'datetime', 'datetime_calendar' => 'abs', },
		{ 'id' => 21, 'name' => 'dtchines', 'basic_type' => 'datetime', 'datetime_calendar' => 'chi', },
		{ 'id' => 22, 'name' => 'str1'  , 'basic_type' => 'str', 'size_in_chars' =>     1, },
		{ 'id' => 23, 'name' => 'str20' , 'basic_type' => 'str', 'size_in_chars' =>    20, },
		{ 'id' => 24, 'name' => 'str100', 'basic_type' => 'str', 'size_in_chars' =>   100, },
		{ 'id' => 25, 'name' => 'str250', 'basic_type' => 'str', 'size_in_chars' =>   250, },
		{ 'id' => 26, 'name' => 'entitynm', 'basic_type' => 'str', 'size_in_chars' =>  30, },
		{ 'id' => 27, 'name' => 'generic' , 'basic_type' => 'str', 'size_in_chars' => 250, },
	) ] );

	my $database = $model->create_node( { 'NODE_TYPE' => 'database', 'ATTRS' => { 'id' => 1, } } ); 

	my $namespace = $database->add_child_node( { 'NODE_TYPE' => 'namespace', 'ATTRS' => { 'id' => 1, } } ); 

	my $tbl_person = $namespace->add_child_node( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 4, 'name' => 'person', 'order' => 4, 'public_syn' => 'person', 
			'storage_file' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{
				'id' => 20, 'name' => 'person_id', 'order' => 1, 'data_type' => 9, 'required_val' => 1,
				'default_val' => 1, 'auto_inc' => 1,
			},
			{ 'id' => 21, 'name' => 'alternate_id', 'order' => 2, 'data_type' => 23, 'required_val' => 0, },
			{ 'id' => 22, 'name' => 'name'        , 'order' => 3, 'data_type' => 24, 'required_val' => 1, },
			{ 'id' => 23, 'name' => 'sex'         , 'order' => 4, 'data_type' => 22, 'required_val' => 0, },
			{ 'id' => 24, 'name' => 'father_id'   , 'order' => 5, 'data_type' =>  9, 'required_val' => 0, },
			{ 'id' => 25, 'name' => 'mother_id'   , 'order' => 6, 'data_type' =>  9, 'required_val' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'id' =>  9, 'name' => 'primary'        , 'order' => 1, 'ind_type' => 'unique', }, 
				{ 'id' => 10, 'table_col' => 20, 'order' => 1, }, ], 
			[ { 'id' => 10, 'name' => 'ak_alternate_id', 'order' => 2, 'ind_type' => 'unique', }, 
				{ 'id' => 11, 'table_col' => 21, 'order' => 1, }, ], 
			[ { 'id' => 11, 'name' => 'fk_father', 'order' => 3, 'ind_type' => 'foreign', 'f_table' => 4, }, 
				{ 'id' => 12, 'table_col' => 24, 'order' => 1, 'f_table_col' => 20 }, ], 
			[ { 'id' => 12, 'name' => 'fk_mother', 'order' => 4, 'ind_type' => 'foreign', 'f_table' => 4, }, 
				{ 'id' => 13, 'table_col' => 25, 'order' => 1, 'f_table_col' => 20 }, ], 
		) ),
	] } );

	my $vw_person = $namespace->add_child_node( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 4, 
			'name' => 'person', 'may_write' => 1, 'view_type' => 'caller', 'match_table' => 4 }, } );

	my $vw_person_with_parents = $namespace->add_child_node( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 2, 
			'name' => 'person_with_parents', 'may_write' => 0, 'view_type' => 'caller', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'id' => 16, 'name' => 'self_id'    , 'order' => 1, 'data_type' =>  9, },
			{ 'id' => 17, 'name' => 'self_name'  , 'order' => 2, 'data_type' => 24, 'sort_priority' => 1, },
			{ 'id' => 18, 'name' => 'father_id'  , 'order' => 3, 'data_type' =>  9, },
			{ 'id' => 19, 'name' => 'father_name', 'order' => 4, 'data_type' => 24, 'sort_priority' => 2, },
			{ 'id' => 20, 'name' => 'mother_id'  , 'order' => 5, 'data_type' =>  9, },
			{ 'id' => 21, 'name' => 'mother_name', 'order' => 6, 'data_type' => 24, 'sort_priority' => 3, },
		) ),
		{ 'NODE_TYPE' => 'view_rowset', 'ATTRS' => { 'id' => 2, 'p_rowset_order' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 3, 'name' => 'self'  , 'order' => 1, 
					'match_table' => 4, }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 17, 'match_table_col' => 20, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 18, 'match_table_col' => 22, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 25, 'match_table_col' => 24, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 26, 'match_table_col' => 25, }, },
			] },
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 4, 'name' => 'father', 'order' => 2, 
					'match_table' => 4, }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 19, 'match_table_col' => 20, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 20, 'match_table_col' => 22, }, },
			] },
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 5, 'name' => 'mother', 'order' => 3, 
					'match_table' => 4, }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 21, 'match_table_col' => 20, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 22, 'match_table_col' => 22, }, },
			] },
			{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 2, 'lhs_src' => 3, 
					'rhs_src' => 4, 'join_type' => 'left', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 2, 'lhs_src_col' => 25, 'rhs_src_col' => 19, } },
			] },
			{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 3, 'lhs_src' => 3, 
					'rhs_src' => 5, 'join_type' => 'left', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 3, 'lhs_src_col' => 26, 'rhs_src_col' => 21, } },
			] },
			( map { { 'NODE_TYPE' => 'view_col_def', 'ATTRS' => $_ } } (
				{ 'id' => 16, 'view_col' => 16, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 17, },
				{ 'id' => 17, 'view_col' => 17, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 18, },
				{ 'id' => 18, 'view_col' => 18, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 19, },
				{ 'id' => 19, 'view_col' => 19, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 20, },
				{ 'id' => 20, 'view_col' => 20, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 21, },
				{ 'id' => 21, 'view_col' => 21, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 22, },
			) ),
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
					'id' => 4, 'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'and', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
						'id' => 5, 'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'like', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
						'id' => 6, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 20, }, },
					{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
						'id' => 7, 'p_expr_order' => 2, 'expr_type' => 'var', 'command_var' => 'srchw_fa', }, },
				] },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
						'id' => 8, 'p_expr_order' => 2, 'expr_type' => 'sfunc', 'sfunc' => 'like', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
						'id' => 9, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 22, }, },
					{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
						'id' => 10, 'p_expr_order' => 2, 'expr_type' => 'var', 'command_var' => 'srchw_mo', }, },
				] },
			] },
		] },
	] } );

	my $tbl_user_auth = $namespace->add_child_node( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 1, 'name' => 'user_auth', 'order' => 1, 'public_syn' => 'user_auth', 
			'storage_file' => 'user', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{
				'id' => 1, 'name' => 'user_id', 'order' => 1, 'data_type' => 9, 'required_val' => 1,
				'default_val' => 1, 'auto_inc' => 1,
			},
			{ 'id' => 2, 'name' => 'login_name'   , 'order' => 2, 'data_type' => 23, 'required_val' => 1, },
			{ 'id' => 3, 'name' => 'login_pass'   , 'order' => 3, 'data_type' => 23, 'required_val' => 1, },
			{ 'id' => 4, 'name' => 'private_name' , 'order' => 4, 'data_type' => 24, 'required_val' => 1, },
			{ 'id' => 5, 'name' => 'private_email', 'order' => 5, 'data_type' => 24, 'required_val' => 1, },
			{ 'id' => 6, 'name' => 'may_login'    , 'order' => 6, 'data_type' => 19, 'required_val' => 1, },
			{ 
				'id' => 7, 'name' => 'max_sessions', 'order' => 7, 'data_type' => 7, 'required_val' => 1, 
				'default_val' => 3, 
			},
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'id' => 1, 'name' => 'primary'         , 'order' => 1, 'ind_type' => 'unique', }, 
				{ 'id' => 1, 'table_col' => 1, 'order' => 1, }, ], 
			[ { 'id' => 2, 'name' => 'ak_login_name'   , 'order' => 2, 'ind_type' => 'unique', }, 
				{ 'id' => 2, 'table_col' => 2, 'order' => 1, }, ], 
			[ { 'id' => 3, 'name' => 'ak_private_email', 'order' => 3, 'ind_type' => 'unique', }, 
				{ 'id' => 3, 'table_col' => 5, 'order' => 1, }, ], 
		) ),
	] } );

	my $tbl_user_profile = $namespace->add_child_node( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 2, 'name' => 'user_profile', 'order' => 2, 'public_syn' => 'user_profile', 
			'storage_file' => 'user', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{ 'id' =>  8, 'name' => 'user_id'     , 'order' => 1, 'data_type' =>  9, 'required_val' => 1, },
			{ 'id' =>  9, 'name' => 'public_name' , 'order' => 2, 'data_type' => 25, 'required_val' => 1, },
			{ 'id' => 10, 'name' => 'public_email', 'order' => 3, 'data_type' => 25, 'required_val' => 0, },
			{ 'id' => 11, 'name' => 'web_url'     , 'order' => 4, 'data_type' => 25, 'required_val' => 0, },
			{ 'id' => 12, 'name' => 'contact_net' , 'order' => 5, 'data_type' => 25, 'required_val' => 0, },
			{ 'id' => 13, 'name' => 'contact_phy' , 'order' => 6, 'data_type' => 25, 'required_val' => 0, },
			{ 'id' => 14, 'name' => 'bio'         , 'order' => 7, 'data_type' => 25, 'required_val' => 0, },
			{ 'id' => 15, 'name' => 'plan'        , 'order' => 8, 'data_type' => 25, 'required_val' => 0, },
			{ 'id' => 16, 'name' => 'comments'    , 'order' => 9, 'data_type' => 25, 'required_val' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_->[1] } } } (
			[ { 'id' => 4, 'name' => 'primary'       , 'order' => 1, 'ind_type' => 'unique', }, 
				{ 'id' => 4, 'table_col' => 8, 'order' => 1, }, ], 
			[ { 'id' => 5, 'name' => 'ak_public_name', 'order' => 2, 'ind_type' => 'unique', }, 
				{ 'id' => 5, 'table_col' => 9, 'order' => 1, }, ], 
			[ { 'id' => 6, 'name' => 'fk_user'       , 'order' => 3, 'ind_type' => 'foreign', 'f_table' => 1, }, 
				{ 'id' => 6, 'table_col' => 8, 'order' => 1, 'f_table_col' => 1 }, ], 
		) ),
	] } );

	my $vw_user = $namespace->add_child_node( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 1, 
			'name' => 'user', 'may_write' => 1, 'view_type' => 'caller', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'id' =>  1, 'name' => 'user_id'      , 'order' =>  1, 'data_type' =>  9, },
			{ 'id' =>  2, 'name' => 'login_name'   , 'order' =>  2, 'data_type' => 23, 'sort_priority' => 1, },
			{ 'id' =>  3, 'name' => 'login_pass'   , 'order' =>  3, 'data_type' => 23, },
			{ 'id' =>  4, 'name' => 'private_name' , 'order' =>  4, 'data_type' => 24, },
			{ 'id' =>  5, 'name' => 'private_email', 'order' =>  5, 'data_type' => 24, },
			{ 'id' =>  6, 'name' => 'may_login'    , 'order' =>  6, 'data_type' => 19, },
			{ 'id' =>  7, 'name' => 'max_sessions' , 'order' =>  7, 'data_type' =>  7, },
			{ 'id' =>  8, 'name' => 'public_name'  , 'order' =>  8, 'data_type' => 25, },
			{ 'id' =>  9, 'name' => 'public_email' , 'order' =>  9, 'data_type' => 25, },
			{ 'id' => 10, 'name' => 'web_url'      , 'order' => 10, 'data_type' => 25, },
			{ 'id' => 11, 'name' => 'contact_net'  , 'order' => 11, 'data_type' => 25, },
			{ 'id' => 12, 'name' => 'contact_phy'  , 'order' => 12, 'data_type' => 25, },
			{ 'id' => 13, 'name' => 'bio'          , 'order' => 13, 'data_type' => 25, },
			{ 'id' => 14, 'name' => 'plan'         , 'order' => 14, 'data_type' => 25, },
			{ 'id' => 15, 'name' => 'comments'     , 'order' => 15, 'data_type' => 25, },
		) ),
		{ 'NODE_TYPE' => 'view_rowset', 'ATTRS' => { 'id' => 1, 'p_rowset_order' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 1, 'name' => 'user_auth', 'order' => 1, 
					'match_table' => 1, }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  1, 'match_table_col' =>  1, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  2, 'match_table_col' =>  2, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  3, 'match_table_col' =>  3, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  4, 'match_table_col' =>  4, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  5, 'match_table_col' =>  5, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  6, 'match_table_col' =>  6, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' =>  7, 'match_table_col' =>  7, }, },
			] },
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 2, 'name' => 'user_profile', 'order' => 2, 
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
			{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 1, 'lhs_src' => 1, 
					'rhs_src' => 2, 'join_type' => 'left', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 1, 'lhs_src_col' => 1, 'rhs_src_col' => 8, } },
			] },
			( map { { 'NODE_TYPE' => 'view_col_def', 'ATTRS' => $_ } } (
				{ 'id' =>  1, 'view_col' =>  1, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  1, },
				{ 'id' =>  2, 'view_col' =>  2, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  2, },
				{ 'id' =>  3, 'view_col' =>  3, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  3, },
				{ 'id' =>  4, 'view_col' =>  4, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  4, },
				{ 'id' =>  5, 'view_col' =>  5, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  5, },
				{ 'id' =>  6, 'view_col' =>  6, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  6, },
				{ 'id' =>  7, 'view_col' =>  7, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  7, },
				{ 'id' =>  8, 'view_col' =>  8, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' =>  9, },
				{ 'id' =>  9, 'view_col' =>  9, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 10, },
				{ 'id' => 10, 'view_col' => 10, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 11, },
				{ 'id' => 11, 'view_col' => 11, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 12, },
				{ 'id' => 12, 'view_col' => 12, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 13, },
				{ 'id' => 13, 'view_col' => 13, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 14, },
				{ 'id' => 14, 'view_col' => 14, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 15, },
				{ 'id' => 15, 'view_col' => 15, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 16, },
			) ),
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
					'id' => 1, 'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'eq', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'id' => 2, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 1, }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'id' => 3, 'p_expr_order' => 2, 'expr_type' => 'var', 'command_var' => 'curr_uid', }, },
			] },
		] },
	] } );

	my $tbl_user_pref = $namespace->add_child_node( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 3, 'name' => 'user_pref', 'order' => 3, 'public_syn' => 'user_pref', 
			'storage_file' => 'user', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_col', 'ATTRS' => $_ } } (
			{ 'id' => 17, 'name' => 'user_id'   , 'order' => 1, 'data_type' =>  9, 'required_val' => 1, },
			{ 'id' => 18, 'name' => 'pref_name' , 'order' => 2, 'data_type' => 26, 'required_val' => 1, },
			{ 'id' => 19, 'name' => 'pref_value', 'order' => 3, 'data_type' => 27, 'required_val' => 0, },
		) ),
		( map { { 'NODE_TYPE' => 'table_ind', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
				map { { 'NODE_TYPE' => 'table_ind_col', 'ATTRS' => $_ } } @{$_->[1]}
				] } } (
			[ { 'id' => 7, 'name' => 'primary', 'order' => 1, 'ind_type' => 'unique', },
				[ { 'id' => 7, 'table_col' => 17, 'order' => 1, }, 
				{ 'id' => 8, 'table_col' => 18, 'order' => 2, }, ],
			], 
			[ { 'id' => 8, 'name' => 'fk_user', 'order' => 2, 'ind_type' => 'foreign', 'f_table' => 1, }, 
				[ { 'id' => 9, 'table_col' => 17, 'order' => 1, 'f_table_col' => 1 }, ],
			], 
		) ),
	] } );

	my $vw_user_theme = $namespace->add_child_node( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 3, 
			'name' => 'user_theme', 'may_write' => 0, 'view_type' => 'caller', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_col', 'ATTRS' => $_ } } (
			{ 'id' => 22, 'name' => 'theme_name' , 'order' => 1, 'data_type' => 27, },
			{ 'id' => 23, 'name' => 'theme_count', 'order' => 2, 'data_type' =>  9, },
		) ),
		{ 'NODE_TYPE' => 'view_rowset', 'ATTRS' => { 'id' => 3, 'p_rowset_order' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 6, 'name' => 'user_pref', 'order' => 1, 
				'match_table' => 3, }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 23, 'match_table_col' => 18, }, },
				{ 'NODE_TYPE' => 'view_src_col', 'ATTRS' => { 'id' => 24, 'match_table_col' => 19, }, },
			] },
			{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'id' => 22, 'view_col' => 22, 
				'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 24, }, },
			{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'id' => 23, 'view_col' => 23, 
					'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'gcount', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_col_def', 'ATTRS' => { 'id' => 24, 
					'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 24, }, },
			] },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'where', 
					'id' => 11, 'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'eq', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'id' => 12, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 23, }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'id' => 13, 'p_expr_order' => 2, 'expr_type' => 'lit', 'lit_val' => 'theme', }, },
			] },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'group', 
				'id' => 14, 'p_expr_order' => 1, 'expr_type' => 'col', 'src_col' => 24, }, },
			{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 'view_part' => 'havin', 
					'id' => 15, 'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'gt', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'id' => 16, 'p_expr_order' => 1, 'expr_type' => 'sfunc', 'sfunc' => 'gcount', }, },
				{ 'NODE_TYPE' => 'view_part_def', 'ATTRS' => { 
					'id' => 17, 'p_expr_order' => 2, 'expr_type' => 'lit', 'lit_val' => '1', }, },
			] },
		] },
	] } );

	return( $model );
}

######################################################################

sub expected_model_xml_output {
	return(
'<root>
	<type_list>
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
	<database_list>
		<database id="1">
			<namespace id="1" database="1">
				<table id="4" name="person" namespace="1" order="4" public_syn="person" storage_file="person">
					<table_col id="20" auto_inc="1" data_type="9" default_val="1" name="person_id" order="1" required_val="1" table="4" />
					<table_col id="21" data_type="23" name="alternate_id" order="2" required_val="0" table="4" />
					<table_col id="22" data_type="24" name="name" order="3" required_val="1" table="4" />
					<table_col id="23" data_type="22" name="sex" order="4" required_val="0" table="4" />
					<table_col id="24" data_type="9" name="father_id" order="5" required_val="0" table="4" />
					<table_col id="25" data_type="9" name="mother_id" order="6" required_val="0" table="4" />
					<table_ind id="9" ind_type="unique" name="primary" order="1" table="4">
						<table_ind_col id="10" order="1" table_col="20" table_ind="9" />
					</table_ind>
					<table_ind id="10" ind_type="unique" name="ak_alternate_id" order="2" table="4">
						<table_ind_col id="11" order="1" table_col="21" table_ind="10" />
					</table_ind>
					<table_ind id="11" f_table="4" ind_type="foreign" name="fk_father" order="3" table="4">
						<table_ind_col id="12" f_table_col="20" order="1" table_col="24" table_ind="11" />
					</table_ind>
					<table_ind id="12" f_table="4" ind_type="foreign" name="fk_mother" order="4" table="4">
						<table_ind_col id="13" f_table_col="20" order="1" table_col="25" table_ind="12" />
					</table_ind>
				</table>
				<view id="4" match_table="4" may_write="1" name="person" namespace="1" view_type="caller" />
				<view id="2" may_write="0" name="person_with_parents" namespace="1" view_type="caller">
					<view_col id="16" data_type="9" name="self_id" order="1" view="2" />
					<view_col id="17" data_type="24" name="self_name" order="2" sort_priority="1" view="2" />
					<view_col id="18" data_type="9" name="father_id" order="3" view="2" />
					<view_col id="19" data_type="24" name="father_name" order="4" sort_priority="2" view="2" />
					<view_col id="20" data_type="9" name="mother_id" order="5" view="2" />
					<view_col id="21" data_type="24" name="mother_name" order="6" sort_priority="3" view="2" />
					<view_rowset id="2" p_rowset_order="1" view="2">
						<view_src id="3" match_table="4" name="self" order="1" rowset="2">
							<view_src_col id="17" match_table_col="20" src="3" />
							<view_src_col id="18" match_table_col="22" src="3" />
							<view_src_col id="25" match_table_col="24" src="3" />
							<view_src_col id="26" match_table_col="25" src="3" />
						</view_src>
						<view_src id="4" match_table="4" name="father" order="2" rowset="2">
							<view_src_col id="19" match_table_col="20" src="4" />
							<view_src_col id="20" match_table_col="22" src="4" />
						</view_src>
						<view_src id="5" match_table="4" name="mother" order="3" rowset="2">
							<view_src_col id="21" match_table_col="20" src="5" />
							<view_src_col id="22" match_table_col="22" src="5" />
						</view_src>
						<view_join id="2" join_type="left" lhs_src="3" rhs_src="4" rowset="2">
							<view_join_col id="2" join="2" lhs_src_col="25" rhs_src_col="19" />
						</view_join>
						<view_join id="3" join_type="left" lhs_src="3" rhs_src="5" rowset="2">
							<view_join_col id="3" join="3" lhs_src_col="26" rhs_src_col="21" />
						</view_join>
						<view_col_def id="16" expr_type="col" p_expr_order="1" rowset="2" src_col="17" view_col="16" />
						<view_col_def id="17" expr_type="col" p_expr_order="1" rowset="2" src_col="18" view_col="17" />
						<view_col_def id="18" expr_type="col" p_expr_order="1" rowset="2" src_col="19" view_col="18" />
						<view_col_def id="19" expr_type="col" p_expr_order="1" rowset="2" src_col="20" view_col="19" />
						<view_col_def id="20" expr_type="col" p_expr_order="1" rowset="2" src_col="21" view_col="20" />
						<view_col_def id="21" expr_type="col" p_expr_order="1" rowset="2" src_col="22" view_col="21" />
						<view_part_def id="4" expr_type="sfunc" p_expr_order="1" rowset="2" sfunc="and" view_part="where">
							<view_part_def id="5" expr_type="sfunc" p_expr="4" p_expr_order="1" rowset="2" sfunc="like" view_part="where">
								<view_part_def id="6" expr_type="col" p_expr="5" p_expr_order="1" rowset="2" src_col="20" view_part="where" />
								<view_part_def id="7" command_var="srchw_fa" expr_type="var" p_expr="5" p_expr_order="2" rowset="2" view_part="where" />
							</view_part_def>
							<view_part_def id="8" expr_type="sfunc" p_expr="4" p_expr_order="2" rowset="2" sfunc="like" view_part="where">
								<view_part_def id="9" expr_type="col" p_expr="8" p_expr_order="1" rowset="2" src_col="22" view_part="where" />
								<view_part_def id="10" command_var="srchw_mo" expr_type="var" p_expr="8" p_expr_order="2" rowset="2" view_part="where" />
							</view_part_def>
						</view_part_def>
					</view_rowset>
				</view>
				<table id="1" name="user_auth" namespace="1" order="1" public_syn="user_auth" storage_file="user">
					<table_col id="1" auto_inc="1" data_type="9" default_val="1" name="user_id" order="1" required_val="1" table="1" />
					<table_col id="2" data_type="23" name="login_name" order="2" required_val="1" table="1" />
					<table_col id="3" data_type="23" name="login_pass" order="3" required_val="1" table="1" />
					<table_col id="4" data_type="24" name="private_name" order="4" required_val="1" table="1" />
					<table_col id="5" data_type="24" name="private_email" order="5" required_val="1" table="1" />
					<table_col id="6" data_type="19" name="may_login" order="6" required_val="1" table="1" />
					<table_col id="7" data_type="7" default_val="3" name="max_sessions" order="7" required_val="1" table="1" />
					<table_ind id="1" ind_type="unique" name="primary" order="1" table="1">
						<table_ind_col id="1" order="1" table_col="1" table_ind="1" />
					</table_ind>
					<table_ind id="2" ind_type="unique" name="ak_login_name" order="2" table="1">
						<table_ind_col id="2" order="1" table_col="2" table_ind="2" />
					</table_ind>
					<table_ind id="3" ind_type="unique" name="ak_private_email" order="3" table="1">
						<table_ind_col id="3" order="1" table_col="5" table_ind="3" />
					</table_ind>
				</table>
				<table id="2" name="user_profile" namespace="1" order="2" public_syn="user_profile" storage_file="user">
					<table_col id="8" data_type="9" name="user_id" order="1" required_val="1" table="2" />
					<table_col id="9" data_type="25" name="public_name" order="2" required_val="1" table="2" />
					<table_col id="10" data_type="25" name="public_email" order="3" required_val="0" table="2" />
					<table_col id="11" data_type="25" name="web_url" order="4" required_val="0" table="2" />
					<table_col id="12" data_type="25" name="contact_net" order="5" required_val="0" table="2" />
					<table_col id="13" data_type="25" name="contact_phy" order="6" required_val="0" table="2" />
					<table_col id="14" data_type="25" name="bio" order="7" required_val="0" table="2" />
					<table_col id="15" data_type="25" name="plan" order="8" required_val="0" table="2" />
					<table_col id="16" data_type="25" name="comments" order="9" required_val="0" table="2" />
					<table_ind id="4" ind_type="unique" name="primary" order="1" table="2">
						<table_ind_col id="4" order="1" table_col="8" table_ind="4" />
					</table_ind>
					<table_ind id="5" ind_type="unique" name="ak_public_name" order="2" table="2">
						<table_ind_col id="5" order="1" table_col="9" table_ind="5" />
					</table_ind>
					<table_ind id="6" f_table="1" ind_type="foreign" name="fk_user" order="3" table="2">
						<table_ind_col id="6" f_table_col="1" order="1" table_col="8" table_ind="6" />
					</table_ind>
				</table>
				<view id="1" may_write="1" name="user" namespace="1" view_type="caller">
					<view_col id="1" data_type="9" name="user_id" order="1" view="1" />
					<view_col id="2" data_type="23" name="login_name" order="2" sort_priority="1" view="1" />
					<view_col id="3" data_type="23" name="login_pass" order="3" view="1" />
					<view_col id="4" data_type="24" name="private_name" order="4" view="1" />
					<view_col id="5" data_type="24" name="private_email" order="5" view="1" />
					<view_col id="6" data_type="19" name="may_login" order="6" view="1" />
					<view_col id="7" data_type="7" name="max_sessions" order="7" view="1" />
					<view_col id="8" data_type="25" name="public_name" order="8" view="1" />
					<view_col id="9" data_type="25" name="public_email" order="9" view="1" />
					<view_col id="10" data_type="25" name="web_url" order="10" view="1" />
					<view_col id="11" data_type="25" name="contact_net" order="11" view="1" />
					<view_col id="12" data_type="25" name="contact_phy" order="12" view="1" />
					<view_col id="13" data_type="25" name="bio" order="13" view="1" />
					<view_col id="14" data_type="25" name="plan" order="14" view="1" />
					<view_col id="15" data_type="25" name="comments" order="15" view="1" />
					<view_rowset id="1" p_rowset_order="1" view="1">
						<view_src id="1" match_table="1" name="user_auth" order="1" rowset="1">
							<view_src_col id="1" match_table_col="1" src="1" />
							<view_src_col id="2" match_table_col="2" src="1" />
							<view_src_col id="3" match_table_col="3" src="1" />
							<view_src_col id="4" match_table_col="4" src="1" />
							<view_src_col id="5" match_table_col="5" src="1" />
							<view_src_col id="6" match_table_col="6" src="1" />
							<view_src_col id="7" match_table_col="7" src="1" />
						</view_src>
						<view_src id="2" match_table="2" name="user_profile" order="2" rowset="1">
							<view_src_col id="8" match_table_col="8" src="2" />
							<view_src_col id="9" match_table_col="9" src="2" />
							<view_src_col id="10" match_table_col="10" src="2" />
							<view_src_col id="11" match_table_col="11" src="2" />
							<view_src_col id="12" match_table_col="12" src="2" />
							<view_src_col id="13" match_table_col="13" src="2" />
							<view_src_col id="14" match_table_col="14" src="2" />
							<view_src_col id="15" match_table_col="15" src="2" />
							<view_src_col id="16" match_table_col="16" src="2" />
						</view_src>
						<view_join id="1" join_type="left" lhs_src="1" rhs_src="2" rowset="1">
							<view_join_col id="1" join="1" lhs_src_col="1" rhs_src_col="8" />
						</view_join>
						<view_col_def id="1" expr_type="col" p_expr_order="1" rowset="1" src_col="1" view_col="1" />
						<view_col_def id="2" expr_type="col" p_expr_order="1" rowset="1" src_col="2" view_col="2" />
						<view_col_def id="3" expr_type="col" p_expr_order="1" rowset="1" src_col="3" view_col="3" />
						<view_col_def id="4" expr_type="col" p_expr_order="1" rowset="1" src_col="4" view_col="4" />
						<view_col_def id="5" expr_type="col" p_expr_order="1" rowset="1" src_col="5" view_col="5" />
						<view_col_def id="6" expr_type="col" p_expr_order="1" rowset="1" src_col="6" view_col="6" />
						<view_col_def id="7" expr_type="col" p_expr_order="1" rowset="1" src_col="7" view_col="7" />
						<view_col_def id="8" expr_type="col" p_expr_order="1" rowset="1" src_col="9" view_col="8" />
						<view_col_def id="9" expr_type="col" p_expr_order="1" rowset="1" src_col="10" view_col="9" />
						<view_col_def id="10" expr_type="col" p_expr_order="1" rowset="1" src_col="11" view_col="10" />
						<view_col_def id="11" expr_type="col" p_expr_order="1" rowset="1" src_col="12" view_col="11" />
						<view_col_def id="12" expr_type="col" p_expr_order="1" rowset="1" src_col="13" view_col="12" />
						<view_col_def id="13" expr_type="col" p_expr_order="1" rowset="1" src_col="14" view_col="13" />
						<view_col_def id="14" expr_type="col" p_expr_order="1" rowset="1" src_col="15" view_col="14" />
						<view_col_def id="15" expr_type="col" p_expr_order="1" rowset="1" src_col="16" view_col="15" />
						<view_part_def id="1" expr_type="sfunc" p_expr_order="1" rowset="1" sfunc="eq" view_part="where">
							<view_part_def id="2" expr_type="col" p_expr="1" p_expr_order="1" rowset="1" src_col="1" view_part="where" />
							<view_part_def id="3" command_var="curr_uid" expr_type="var" p_expr="1" p_expr_order="2" rowset="1" view_part="where" />
						</view_part_def>
					</view_rowset>
				</view>
				<table id="3" name="user_pref" namespace="1" order="3" public_syn="user_pref" storage_file="user">
					<table_col id="17" data_type="9" name="user_id" order="1" required_val="1" table="3" />
					<table_col id="18" data_type="26" name="pref_name" order="2" required_val="1" table="3" />
					<table_col id="19" data_type="27" name="pref_value" order="3" required_val="0" table="3" />
					<table_ind id="7" ind_type="unique" name="primary" order="1" table="3">
						<table_ind_col id="7" order="1" table_col="17" table_ind="7" />
						<table_ind_col id="8" order="2" table_col="18" table_ind="7" />
					</table_ind>
					<table_ind id="8" f_table="1" ind_type="foreign" name="fk_user" order="2" table="3">
						<table_ind_col id="9" f_table_col="1" order="1" table_col="17" table_ind="8" />
					</table_ind>
				</table>
				<view id="3" may_write="0" name="user_theme" namespace="1" view_type="caller">
					<view_col id="22" data_type="27" name="theme_name" order="1" view="3" />
					<view_col id="23" data_type="9" name="theme_count" order="2" view="3" />
					<view_rowset id="3" p_rowset_order="1" view="3">
						<view_src id="6" match_table="3" name="user_pref" order="1" rowset="3">
							<view_src_col id="23" match_table_col="18" src="6" />
							<view_src_col id="24" match_table_col="19" src="6" />
						</view_src>
						<view_col_def id="22" expr_type="col" p_expr_order="1" rowset="3" src_col="24" view_col="22" />
						<view_col_def id="23" expr_type="sfunc" p_expr_order="1" rowset="3" sfunc="gcount" view_col="23">
							<view_col_def id="24" expr_type="col" p_expr="23" p_expr_order="1" rowset="3" src_col="24" view_col="23" />
						</view_col_def>
						<view_part_def id="11" expr_type="sfunc" p_expr_order="1" rowset="3" sfunc="eq" view_part="where">
							<view_part_def id="12" expr_type="col" p_expr="11" p_expr_order="1" rowset="3" src_col="23" view_part="where" />
							<view_part_def id="13" expr_type="lit" lit_val="theme" p_expr="11" p_expr_order="2" rowset="3" view_part="where" />
						</view_part_def>
						<view_part_def id="14" expr_type="col" p_expr_order="1" rowset="3" src_col="24" view_part="group" />
						<view_part_def id="15" expr_type="sfunc" p_expr_order="1" rowset="3" sfunc="gt" view_part="havin">
							<view_part_def id="16" expr_type="sfunc" p_expr="15" p_expr_order="1" rowset="3" sfunc="gcount" view_part="havin" />
							<view_part_def id="17" expr_type="lit" lit_val="1" p_expr="15" p_expr_order="2" rowset="3" view_part="havin" />
						</view_part_def>
					</view_rowset>
				</view>
			</namespace>
		</database>
	</database_list>
	<application_list />
</root>
'
	);
}

######################################################################

1;
