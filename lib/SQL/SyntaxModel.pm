=head1 NAME

SQL::SyntaxModel - An abstract syntax tree for all types of SQL

=cut

######################################################################

package SQL::SyntaxModel;
require 5.004;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.06';

######################################################################

=head1 COPYRIGHT AND LICENSE

This file is part of the SQL::SyntaxModel library (libSQLSM).

SQL::SyntaxModel is Copyright (c) 1999-2003, Darren R. Duncan.  All rights
reserved.  Address comments, suggestions, and bug reports to
B<perl@DarrenDuncan.net>, or visit "http://www.DarrenDuncan.net" for more
information.

SQL::SyntaxModel is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License (GPL) version 2 as published
by the Free Software Foundation (http://www.fsf.org/).  You should have
received a copy of the GPL as part of the SQL::SyntaxModel distribution, in the
file named "LICENSE"; if not, write to the Free Software Foundation, Inc., 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA.

Any versions of SQL::SyntaxModel that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits. SQL::SyntaxModel is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GPL for more details.

Linking SQL::SyntaxModel statically or dynamically with other modules is making
a combined work based on SQL::SyntaxModel.  Thus, the terms and conditions of
the GPL cover the whole combination.

As a special exception, the copyright holders of SQL::SyntaxModel give you
permission to link SQL::SyntaxModel with independent modules that are
interfaces to or implementations of databases, regardless of the license terms
of these independent modules, and to copy and distribute the resulting combined
work under terms of your choice, provided that every copy of the combined work
is accompanied by a complete copy of the source code of SQL::SyntaxModel (the
version of SQL::SyntaxModel used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on SQL::SyntaxModel, and
which is fully useable when not linked to SQL::SyntaxModel in any form.

Note that people who make modified versions of SQL::SyntaxModel are not
obligated to grant this special exception for their modified versions; it is
their choice whether to do so.  The GPL gives permission to release a modified
version without this exception; this exception also makes it possible to
release a modified version which carries forward this exception.

While it is by no means required, the copyright holders of SQL::SyntaxModel
would appreciate being informed any time you create a modified version of
SQL::SyntaxModel that you are willing to distribute, because that is a
practical way of suggesting improvements to the standard version.

=head1 DEPENDENCIES

Perl Version:

	5.004

Standard Modules:

	Carp

Nonstandard Modules:

I<none>

=cut

######################################################################

use Carp;

######################################################################

=head1 SYNOPSIS

	use strict;
	use warnings;

	use SQL::SyntaxModel;

	my $model = SQL::SyntaxModel->new();

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

=head1 DESCRIPTION

This Perl 5 object class is intended to be a powerful but easy to use
replacement for SQL strings (including support for placeholders), which you can
use to make queries against a database.  Each SQL::SyntaxModel object can
represent a non-ambiguous structured command for a database to execute, or one
can be a non-ambiguous structured description of a database schema object.  This
class supports all types of database operations, including both data
manipulation and schema manipulation, as well as managing database instances
and users.  You typically construct a database query by setting appropriate
attributes of these objects, and you execute a database query by evaluating the
same attributes.  SQL::SyntaxModel objects are designed to be equivalent to SQL
in both the type of information they carry and in their conceptual structure.
This is analagous to how XML DOMs are objects that are equivalent to XML
strings, and they can be converted back and forth at will.  If you know SQL, or
even just relational database theory in general, then this module should be
easy to learn.

SQL::SyntaxModels are intended to represent all kinds of SQL, both DML and DDL,
both ANSI standard and RDBMS vendor extensions.  Unlike basically all of the
other SQL generating/parsing modules I know about, which are limited to basic
DML and only support table definition DDL, this class supports arbitrarily
complex select statements, with composite keys and unions, and calls to stored
functions; this class can also define views and stored procedures and triggers.
Some of the existing modules, even though they construct complete SQL, will
take/require fragments of SQL as input (such as "where" clauses)  By contrast,
SQL::SyntaxModel takes no SQL fragments.  All of its inputs are atomic, which
means it is also easier to analyse the objects for implementing a wider range
of functionality than previously expected; for example, it is much easier to
analyse any select statement and generate update/insert/delete statements for
the virtual rows fetched with it (a process known as updateable views).

Considering that each database product has its own dialect of SQL which it
implements, you would have to code SQL differently depending on which database
you are using.  One common difference is the syntax for specifying an outer
join in a select query.  Another common difference is how to specify that a
table column is an integer or a boolean or a character string.  Moreover, each
database has a distinct feature set, so you may be able to do tasks with one
database that you can't do with another.  In fact, some databases don't support
SQL at all, but have similar features that are accessible thorough alternate
interfaces. SQL::SyntaxModel is designed to represent a normalized superset of
all database features that one may reasonably want to use.  "Superset" means
that if even one database supports a feature, you will be able to invoke it
with this class. You can also reference some features which no database
currently implements, but it would be reasonable for one to do so later.
"Normalized" means that if multiple databases support the same feature but have
different syntax for referencing it, there will be exactly one way of referring
to it with SQL::SyntaxModel.  So by using this class, you will never have to
change your database-using code when moving between databases, as long as both
of them support the features you are using (or they are emulated).  That said,
it is generally expected that if a database is missing a specific feature that
is easy to emulate, then code which evaluates SQL::SyntaxModels will emulate it
(for example, emulating "left()" with "substr()"); in such cases, it is
expected that when you use such features they will work with any database.  For
example, if you want a model-specified boolean data type, you will always get
it, whether it is implemented  on a per-database-basis as a "boolean" or an
"int(1)" or a "number(1,0)".  Or a model-specified "str" data type you will
always get it, whether it is called "text" or "varchar2" or "sql_varchar".

SQL::SyntaxModel is intended to be just a stateless container for database
query or schema information.  It does not talk to any databases by itself and
it does not generate or parse any SQL; rather, it is intended that other third
party modules or code of your choice will handle this task.  In fact,
SQL::SyntaxModel is designed so that many existing database related modules
could be updated to use it internally for storing state information, including
SQL generating or translating modules, and schema management modules, and
modules which implement object persistence in a database.  Conceptually
speaking, the DBI module itself could be updated to take SQL::SyntaxModel
objects as arguments to its "prepare" method, as an alternative (optional) to
the SQL strings it currently takes.  Code which implements the things that
SQL::SyntaxModel describes can do this in any way that they want, which can
mean either generating and executing SQL, or generating Perl code that does the
same task and evaling it, should they want to (the latter can be a means of
emulation).  This class should make all of that easy.

SQL::SyntaxModel is especially suited for use with applications or modules that
make use of data dictionaries to control what they do.  It is common in
applications that they interpret their data dictionaries and generate SQL to
accomplish some of their work, which means making sure generated SQL is in the
right dialect or syntax, and making sure literal values are escaped correctly.
By using this module, applications can simply copy appropriate individual
elements in their data dictionaries to SQL::SyntaxModel properties, including
column names, table names, function names, literal values, bind variable names,
and they don't have to do any string parsing or assembling.

Now, I can only imagine why all of the other SQL generating/parsing modules
that I know about have excluded privileged support for more advanced database
features like stored procedures.  Either the authors didn't have a need for it,
or they figured that any other prospective users wouldn't need it, or they
found it too difficult to implement so far and maybe planned to do it later. As
for me, I can see tremendous value in various advanced features, and so I have
included privileged support for them in SQL::SyntaxModel.  You simply have to
work on projects of a significant size to get an idea that these features would
provide a large speed, reliability, and security savings for you.  Look at many
large corporate or government systems, such as those which have hundreds of
tables or millions of records, and that may have complicated business logic
which governs whether data is consistent/valid or not.  Within reasonable
limits, the more work you can get the database to do internally, the better.  I
believe that if these features can also be represented in a database-neutral
format, such as what SQL::SyntaxModel attempts to do, then users can get the
full power of a database without being locked into a single vendor due to all
their investment in vendor-specific SQL stored procedure code.  If customers
can move a lot more easily, it will help encourage database vendors to keep
improving their products or lower prices to keep their customers, and users in
general would benefit.  So I do have reasons for trying to tackle the advanced
database features in SQL::SyntaxModel.

=head1 STRUCTURE

The internal structure of a SQL::SyntaxModel object is conceptually a cross
between an XML DOM and an object-relational database, with a specific schema.
This module is implemented with two main classes that work together, Containers
and Nodes. The Container object is an environment or context in which Node
objects must live.  A typical application will only need to create one
Container object (returned by the module's 'new' function), and then a set of
Nodes which live within that Container.  The Nodes are related sometimes with
single or multiple cardinality to each other.

SQL::SyntaxModel is expressly designed so that its data is easy to convert
between different representations, mainly in-memory data structures linked by
references, and multi-table record sets stored in relational databases, and
node sets in XML documents.  A Container corresponds to an XML document or a
complete database, and each Node corresponds to an XML node or a database
record.  Each Node has a specific node_type (a case-sensitive string), which
corresponds to a database table or an XML tag name.  See the BRIEF NODE TYPE
LIST main documentation section to see which ones exist.  The node_type is set
when the Node is created and it can not be changed later.

A Node has a specific set of allowed attributes that are determined by the
node_type, each of which corresponds to a database table column or an XML node
attribute.  Every Node of a common node_type has a unique 'id' attribute (a
positive integer) by which it is referenced; that attribute corresponds to the
database table's single-column primary key.  Each other Node attribute is
either a scalar value of some data type, or an enumerated value, or a reference
to another Node of a specific node_type, which has a foreign-key constraint on
it.  Foreign-key constraints are enforced by this module, so you will have to
add Nodes in the appropriate order, just as when adding records to a database.
Any Node which is referenced in an attribute (cited in a foreign-key
constraint) of another is a parent of the other; as a corollary, the second
Node is a child of the first.  The order of child Nodes under a parent is the
same as that in which the parent-child relationship was assigned; however, for
Node types that form part of a data dictionary where an explicit order is
important, they also have an 'order' attribute to define that.

When SQL::SyntaxModels are converted to XML, one referencing attribute is given
higher precedence than the others and becomes the single parent XML node.  For
example, the XML parent of a 'table_col' Node is always a 'table' Node, even
though a 'data_type' Node is also referenced.  While Nodes of most types always
have Nodes of a single other type as their parents, there are some exceptions.
Nodes of certain types, such as view_rowset or *_expr, may have either another
Node of the same type as itself, or of a specific other type as its parent,
depending on the context; these Nodes form trees of their own type, and it is
the root Node of each tree which has a different Node type as its parent. 

Finally, any Node of certain types will always have a specific super-node as
its single parent, which it does not reference in an attribute, and which can
not be changed.  All 4 super-nodes have no attributes, even 'id', and only one
of each exists; they are created by default with the Container they are part
of, forming the top 2 levels of the Node tree, and can not be removed.  They
are: 'root' (the single level-1 Node which is parent to the other super-nodes
but no normal Nodes), 'type_list' (parent to 'data_type' Nodes),
'database_list' (parent to 'database' Nodes), and 'application_list' (parent to
'application' Nodes).  All other Node types have normal Nodes as parents.

Note that this module does not support the concept of 'document fragments',
which is a set of Nodes not linked to the main tree.  Every Node (save the
super-node root) must have a primary parent Node at all times.  However, Node
trees can still be moved around at any time by reassigning their primary parent
attribute.  Also, individual Nodes can still always be referred to externally.

You should look at the POD-only files named SQL::SyntaxModel::DataDictionary
and SQL::SyntaxModel::XMLSchema, which came with this distribution.  They serve
to document all of the possible Node types, with attributes, constraints, and
allowed relationships with other Node types, by way of describing either a
suitable database schema or XML schema for storing these nodes in, such as was
mentioned in the previous paragraphs.  As the SQL::SyntaxModel class itself has
very few properties and methods, all being highly generic (much akin to an XML
DOM), the POD of this PM file will only describe how to use said methods, and
will not list all the allowed inputs or constraints to said methods.  With only
simple guidance in SyntaxModel.pm, you should be able to interpret
DataDictionary.pod and XMLSchema.pod to get all the nitty gritty details.  You
should also look at the tutorial or example files which will be in the
distribution when ready, or any SYNOPSIS code here.

=head1 BRIEF NODE RELATIONSHIP LIST

Here is a diagram showing just the conceptually high-level Node types, grouped 
in their logical parent-child relationships (which may go through lower level 
Node types that aren't shown here); a complete diagram is in XMLSchema.pod:

	+-root (may or may not actually be used; a convenience)
	   +-data_type (describes a table column or a view interface or a block variable)
	   +-database (contains everything that is "in the database schema"; what you connect to)
	   |  +-namespace (akin to an Oracle "schema", or can just be name prefix for following)
	   |  |  +-table
	   |  |  |  +-trigger (an un-named block that fires on a table event)
	   |  |  |     +-block (the body of the trigger)
	   |  |  +-view (a named view)
	   |  |  |  +-view (a subquery)
	   |  |  +-sequence    
	   |  |  +-block (a named global procedure, function, or "package")
	   |  |     +-block (a block nested or declared inside one of the above)
	   |  |     +-view (a cursor declaration)
	   |  +-user
	   +-application
	      +-command (SQL that is not "part of a schema", although it includes DML for schema)
	         +-view (a select statement usually)
	         +-block (an anonymous block or set of normal SQL to run in sequence)

=head1 BRIEF NODE TYPE LIST

This is a brief list of all the valid types that a SQL::SyntaxModel Node can
be.  Descriptions can be found by looking up the corresponding table names in
SQL::SyntaxModel::DataDictionary, although a more detailed summary is planned
to be added here.  The list is subject to be revised, of course.

ROOT SUPER-NODES

	root
	type_list
	database_list
	application_list

DATA TYPES

	data_type

DATABASES AND NAME SPACES

	database
	namespace

TABLES

	table
	table_col
	table_ind
	table_ind_col
	trigger

VIEWS

	view
	view_col
	view_rowset
	view_src
	view_src_col
	view_join
	view_join_col
	view_hierarchy
	view_col_def
	view_part_def

SEQUENCES

	sequence

BLOCKS

	block
	block_var
	block_stmt
	block_expr

USERS

	user
	privilege

APPLICATIONS, COMMANDS AND RESULTS

	application
	command
	command_var

=cut

######################################################################

# Names of properties for objects of the SQL::SyntaxModel class are declared here:
my $MPROP_CONTAINER = 'container'; # holds all the actual Container properties for this class
	# We use two classes internally where user sees one so that no internal refs point to the 
	# parentmost object, and hence DESTROY() will be called properly when all external refs go away.

# Names of properties for objects of the SQL::SyntaxModel::_::Container class are declared here:
my $CPROP_ALL_NODES  = 'all_nodes'; # hash of hashes of Node refs; find any Node by node_type:node_id quickly
my $CPROP_ROOT_NODE  = 'root_node'; # reference to the root Node of the Node tree
#my $CPROP_CURR_NODE = 'curr_node'; # ref to a Node; used when "streaming" to or from XML
	# To do: store error codes or messages being generated
	# To do: have attribute, or protected section, like an mutex, to indicate an edit in progress 
		# or that there was a failure resulting in inconsistant data

# Names of properties for objects of the SQL::SyntaxModel::_::Node class are declared here:
my $NPROP_CONTAINER   = 'container'; # ref to Container this Node lives in
my $NPROP_NODE_TYPE   = 'node_type'; # str - what type of Node this is
my $NPROP_PARENT_NODE = 'parent_node'; # ref to primary parent Node; dupl attr unl parent is supernode
my $NPROP_ATTRIBUTES  = 'attributes'; # hash - attributes of this Node, incl refs to all parent Nodes
my $NPROP_CHILD_NODES = 'child_nodes'; # array - list of refs to other Nodes citing self as parent
	# When converting to XML, we use PARENT_NODE to determine if we connect or not; 
	# of our child nodes, only those whose primary parent points back to us is our XML child.

# Named arguments corresponding to properties for objects of this class are
# declared here; they are currently only used with the create_node() function:
my $ARG_NODE_TYPE = 'NODE_TYPE'; # str - what type of Node we are
my $ARG_PARENT    = 'PARENT'; # ref to new primary parent for current Node
my $ARG_ATTRS     = 'ATTRS'; # hash - our attributes, including refs/ids of parents we will have
my $ARG_CHILDREN  = 'CHILDREN'; # list of refs to new Nodes we will become primary parent of

# Names of special Node attributes are declared here:
my $ATTR_ID = 'id'; # int - unique identifier for a Node within its type

# This is used by error messages; errors will be reimplemented later:
my $CLSNMC = 'SQL::SyntaxModel';
my $CLSNMN = 'SQL::SyntaxModel::_::Node';

# These are programmatically recognized enumerations of values that 
# particular Node attributes are allowed to have.  They are given names 
# here so that multiple Node types can make use of the same value lists.  
# Currently only the codes are shown, but attributes may be attached later.
my %CONSTANT_CODE_TYPES = (
	'cct_basic_var_type' => { map { ($_ => 1) } qw(
		scalar record array cursor ref
	) },
	'cct_basic_data_type' => { map { ($_ => 1) } qw(
		bin str num bool datetime
	) },
	'cct_str_enc' => { map { ($_ => 1) } qw(
		u8 u16 u32 asc ebs
	) },
	'cct_str_latin_case' => { map { ($_ => 1) } qw(
		pr uc lc
	) },
	'cct_datetime_calendar' => { map { ($_ => 1) } qw(
		abs gre jul chi heb isl jpn
	) },
	'cct_index_type' => { map { ($_ => 1) } qw(
		noconstr unique foreign uforeign
	) },
	'cct_view_type' => { map { ($_ => 1) } qw(
		object caller cursor inside
	) },
	'cct_rs_merge_type' => { map { ($_ => 1) } qw(
		dis all uni int exc min
	) },
	'cct_rs_join_type' => { map { ($_ => 1) } qw(
		equal left
	) },
	'cct_view_part' => { map { ($_ => 1) } qw(
		where group havin order
	) },
	'cct_basic_expr_type' => { map { ($_ => 1) } qw(
		lit var col view sfunc ufunc
	) },
	'cct_standard_func' => { map { ($_ => 1) } qw(
		to_str to_num to_int to_bool to_date
		not and or xor
		eq ne lt gt le ge is_null nvl switch like
		add sub mul div divi mod round exp log min max avg
		sconcat slength sindex substr srepeat strim spad spadl lc uc
		gcount gmin gmax gsum gavg gconcat gevery gany gsome
		crowid crownum clevel
	) },
	'cct_block_type' => { map { ($_ => 1) } qw(
		pack trig proc func loop cond
	) },
	'cct_basic_stmt_type' => { map { ($_ => 1) } qw(
		sproc uproc assig logic
	) },
	'cct_standard_proc' => { map { ($_ => 1) } qw(
	) },
	'cct_command_type' => { map { ($_ => 1) } qw(
		db_list db_info db_verify db_open db_close db_ping 
		db_create db_delete db_clone db_move
		user_list user_info user_verify
		user_create user_delete user_clone user_update user_grant user_revoke
		table_list table_info table_verify
		table_create table_delete table_clone table_update
		view_list view_info view_verify
		view_create view_delete view_clone view_update
		block_list block_info block_verify 
		block_create block_delete block_clone block_update
		rec_fetch rec_verify rec_insert rec_update rec_c_update 
		rec_delete rec_replace rec_clone rec_lock rec_unlock
		tra_start tra_commit tra_rollback
		call_proc call_func
	) },
);

# These are the allowed Node types, with their allowed attributes and their 
# allowed child Node types.  They are used for method input checking and 
# other related tasks.
my $SQLSM_ROOT_NODE_TYPE = 'root';
my $SQLSM_L2_TYPE_LIST = 'type_list';
my $SQLSM_L2_DTBS_LIST = 'database_list';
my $SQLSM_L2_APPL_LIST = 'application_list';

my %SUPER_NODE_TYPES = map { ($_ => 1) } 
	($SQLSM_ROOT_NODE_TYPE, $SQLSM_L2_TYPE_LIST, $SQLSM_L2_DTBS_LIST, $SQLSM_L2_APPL_LIST);
my $SUPER_NODE_FILE_ID = 1;

my %NODE_TYPES = (
	$SQLSM_ROOT_NODE_TYPE => {},
	$SQLSM_L2_TYPE_LIST => {
		'parent_supernode_type' => $SQLSM_ROOT_NODE_TYPE,
	},
	$SQLSM_L2_DTBS_LIST => {
		'parent_supernode_type' => $SQLSM_ROOT_NODE_TYPE,
	},
	$SQLSM_L2_APPL_LIST => {
		'parent_supernode_type' => $SQLSM_ROOT_NODE_TYPE,
	},
	'data_type' => {
		'attributes' => {
			'id' => 'nid',
			'name' => 'str',
			'basic_type' => ['enum','cct_basic_data_type'],
			'size_in_bytes' => 'uint',
			'size_in_chars' => 'uint',
			'size_in_digits' => 'uint',
			'store_fixed' => 'bool',
			'str_encoding' => ['enum','cct_str_enc'],
			'str_trim_white' => 'bool',
			'str_latin_case' => ['enum','cct_str_latin_case'],
			'str_pad_char' => 'str',
			'str_trim_pad' => 'bool',
			'num_unsigned' => 'bool',
			'num_precision' => 'uint',
			'datetime_calendar' => ['enum','cct_datetime_calendar'],
		},
		'parent_supernode_type' => $SQLSM_L2_TYPE_LIST,
		'req_attrs' => [qw( id name basic_type )],
	},
	'database' => {
		'attributes' => {
			'id' => 'nid',
			'name' => 'str',
		},
		'parent_supernode_type' => $SQLSM_L2_DTBS_LIST,
		'req_attrs' => [qw( id )],
	},
	'namespace' => {
		'attributes' => {
			'id' => 'nid',
			'database' => ['node','database'],
			'name' => 'str',
		},
		'parent_node_attr' => 'database',
		'req_attrs' => [qw( id database )],
	},
	'table' => {
		'attributes' => {
			'id' => 'nid',
			'namespace' => ['node','namespace'],
			'name' => 'str',
			'order' => 'uint',
			'public_syn' => 'str',
			'storage_file' => 'str',
		},
		'parent_node_attr' => 'namespace',
		'req_attrs' => [qw( id namespace name order )],
	},
	'table_col' => {
		'attributes' => {
			'id' => 'nid',
			'table' => ['node','table'],
			'name' => 'str',
			'order' => 'uint',
			'data_type' => ['node','data_type'],
			'required_val' => 'bool',
			'default_val' => 'str',
			'auto_inc' => 'bool',
		},
		'parent_node_attr' => 'table',
		'req_attrs' => [qw( id table name order data_type required_val )],
	},
	'table_ind' => {
		'attributes' => {
			'id' => 'nid',
			'table' => ['node','table'],
			'name' => 'str',
			'order' => 'uint',
			'ind_type' => ['enum','cct_index_type'],
			'f_table' => ['node','table'],
		},
		'parent_node_attr' => 'table',
		'req_attrs' => [qw( id table name order ind_type )],
	},
	'table_ind_col' => {
		'attributes' => {
			'id' => 'nid',
			'table_ind' => ['node','table_ind'],
			'table_col' => ['node','table_col'],
			'order' => 'uint',
			'f_table_col' => ['node','table_col'],
		},
		'parent_node_attr' => 'table_ind',
		'req_attrs' => [qw( id table_ind table_col order )],
	},
	'trigger' => {
		'attributes' => {
			'id' => 'nid',
			'table' => ['node','table'],
			'block' => 'uint',
			'run_before' => 'bool',
			'run_after' => 'bool',
			'on_insert' => 'bool',
			'on_update' => 'bool',
			'on_delete' => 'bool',
			'for_each_row' => 'bool',
		},
		'parent_node_attr' => 'table',
		'req_attrs' => [qw( id table block run_before run_after on_insert on_update on_delete for_each_row )],
	},
	'view' => {
		'attributes' => {
			'id' => 'nid',
			'view_type' => ['enum','cct_view_type'],
			'p_view' => ['node','view'],
			'namespace' => ['node','namespace'],
			'name' => 'str',
			'order' => 'uint',
			'public_syn' => 'str',
			'may_write' => 'bool',
			'match_table' => ['node','table'],
		},
		'parent_selfnode_attr' => 'p_view',
		'parent_node_attr' => 'namespace',
		'req_attrs' => [qw( id view_type may_write )],
	},
	'view_col' => {
		'attributes' => {
			'id' => 'nid',
			'view' => ['node','view'],
			'name' => 'str',
			'order' => 'uint',
			'data_type' => ['node','data_type'],
			'sort_priority' => 'uint',
		},
		'parent_node_attr' => 'view',
		'req_attrs' => [qw( id view name order data_type )],
	},
	'view_rowset' => {
		'attributes' => {
			'id' => 'nid',
			'view' => ['node','view'],
			'p_rowset' => ['node','view_rowset'],
			'p_rowset_order' => 'uint',
			'c_merge_type' => ['enum','cct_rs_merge_type'],
		},
		'parent_selfnode_attr' => 'p_rowset',
		'parent_node_attr' => 'view',
		'req_attrs' => [qw( id view p_rowset_order )],
	},
	'view_src' => {
		'attributes' => {
			'id' => 'nid',
			'rowset' => ['node','view_rowset'],
			'name' => 'str',
			'order' => 'uint',
			'match_table' => ['node','table'],
			'match_view' => ['node','view'],
		},
		'parent_node_attr' => 'rowset',
		'req_attrs' => [qw( id rowset name order )],
	},
	'view_src_col' => {
		'attributes' => {
			'id' => 'nid',
			'src' => ['node','view_src'],
			'match_table_col' => ['node','table_col'],
			'match_view_col' => ['node','view_col'],
		},
		'parent_node_attr' => 'src',
		'req_attrs' => [qw( id src )],
	},
	'view_join' => {
		'attributes' => {
			'id' => 'nid',
			'rowset' => ['node','view_rowset'],
			'lhs_src' => ['node','view_src'],
			'rhs_src' => ['node','view_src'],
			'join_type' => ['enum','cct_rs_join_type'],
		},
		'parent_node_attr' => 'rowset',
		'req_attrs' => [qw( id rowset lhs_src rhs_src join_type )],
	},
	'view_join_col' => {
		'attributes' => {
			'id' => 'nid',
			'join' => ['node','view_join'],
			'lhs_src_col' => ['node','view_src_col'],
			'rhs_src_col' => ['node','view_src_col'],
		},
		'parent_node_attr' => 'join',
		'req_attrs' => [qw( id join lhs_src_col rhs_src_col )],
	},
	'view_hierarchy' => {
		'attributes' => {
			'id' => 'nid',
			'rowset' => ['node','view_rowset'],
			'start_src_col' => ['node','view_src_col'],
			'start_lit_val' => 'str',
			'start_block_var' => ['node','block_var'],
			'start_command_var' => 'str', #temp haxie; should say: ['node','command_var'],
			'conn_src_col' => ['node','view_src_col'],
			'p_conn_src_col' => ['node','view_src_col'],
		},
		'parent_node_attr' => 'rowset',
		'req_attrs' => [qw( id rowset start_src_col conn_src_col p_conn_src_col )],
	},
	'view_col_def' => {
		'attributes' => {
			'id' => 'nid',
			'view_col' => ['node','view_col'],
			'rowset' => ['node','view_rowset'],
			'p_expr' => ['node','view_col_def'],
			'p_expr_order' => 'uint',
			'expr_type' => ['enum','cct_basic_expr_type'],
			'lit_val' => 'str',
			'block_var' => ['node','block_var'],
			'command_var' => 'str', #temp haxie; should say: ['node','command_var'],
			'src_col' => ['node','view_src_col'],
			'f_view' => ['node','view'],
			'sfunc' => ['enum','cct_standard_func'],
			'ufunc' => ['node','block'],
		},
		'parent_selfnode_attr' => 'p_expr',
		'parent_node_attr' => 'rowset',
		'inherited_selfnode_attrs' => [qw( view_col rowset )],
		'req_attrs' => [qw( id view_col rowset p_expr_order expr_type )],
	},
	'view_part_def' => {
		'attributes' => {
			'id' => 'nid',
			'rowset' => ['node','view_rowset'],
			'view_part' => ['enum','cct_view_part'],
			'p_expr' => ['node','view_part_def'],
			'p_expr_order' => 'uint',
			'expr_type' => ['enum','cct_basic_expr_type'],
			'lit_val' => 'str',
			'block_var' => ['node','block_var'],
			'command_var' => 'str', #temp haxie; should say: ['node','command_var'],
			'src_col' => ['node','view_src_col'],
			'f_view' => ['node','view'],
			'sfunc' => ['enum','cct_standard_func'],
			'ufunc' => ['node','block'],
		},
		'parent_selfnode_attr' => 'p_expr',
		'parent_node_attr' => 'rowset',
		'inherited_selfnode_attrs' => [qw( rowset view_part )],
		'req_attrs' => [qw( id rowset view_part p_expr_order expr_type )],
	},
	'sequence' => {
		'attributes' => {
			'id' => 'nid',
			'namespace' => ['node','namespace'],
			'name' => 'str',
			'public_syn' => 'str',
		},
		'parent_node_attr' => 'namespace',
		'req_attrs' => [qw( id name )],
	},
	'block' => {
		'attributes' => {
			'id' => 'nid',
			'block_type' => ['enum','cct_block_type'],
			'p_block' => ['node','block'],
			'namespace' => ['node','namespace'],
			'name' => 'str',
			'order' => 'uint',
			'public_syn' => 'str',
		},
		'parent_selfnode_attr' => 'p_block',
		'parent_node_attr' => 'namespace',
		'req_attrs' => [qw( id block_type )],
	},
	'block_var' => {
		'attributes' => {
			'id' => 'nid',
			'block' => ['node','block'],
			'name' => 'str',
			'order' => 'uint',
			'var_type' => ['enum','cct_basic_var_type'],
			'is_argument' => 'bool',
			'data_type' => ['node','data_type'],
			'init_lit_val' => 'str',
			'c_view' => ['node','view'],
		},
		'parent_node_attr' => 'block',
		'req_attrs' => [qw( id block name order var_type is_argument )],
	},
	'block_stmt' => {
		'attributes' => {
			'id' => 'nid',
			'block' => ['node','block'],
			'order' => 'uint',
			'stmt_type' => ['enum','cct_basic_stmt_type'],
			'dest_var' => ['node','block_var'],
			'sproc' => ['enum','cct_standard_proc'],
			'uproc' => ['node','block'],
			'c_block' => ['node','block'],
		},
		'parent_node_attr' => 'block',
		'req_attrs' => [qw( id block order stmt_type )],
	},
	'block_expr' => {
		'attributes' => {
			'id' => 'nid',
			'stmt' => ['node','block_stmt'],
			'p_expr' => ['node','block_expr'],
			'p_expr_order' => 'uint',
			'expr_type' => ['enum','cct_basic_expr_type'],
			'lit_val' => 'str',
			'src_var' => ['node','block_var'],
			'sfunc' => ['enum','cct_standard_func'],
			'ufunc' => ['node','block'],
		},
		'parent_selfnode_attr' => 'p_expr',
		'parent_node_attr' => 'stmt',
		'req_attrs' => [qw( id stmt p_expr_order expr_type )],
	},
	'user' => {
		'attributes' => {
			'id' => 'nid',
			'database' => ['node','database'],
			'name' => 'str',
		},
		'parent_node_attr' => 'database',
		'req_attrs' => [qw( id database name )],
	},
	'privilege' => {
		'attributes' => {
			'id' => 'nid',
			'user' => ['node','user'],
			'name' => 'str',
		},
		'parent_node_attr' => 'user',
		'req_attrs' => [qw( id user name )],
	},
	'application' => {
		'attributes' => {
			'id' => 'nid',
			'name' => 'str',
		},
		'parent_supernode_type' => $SQLSM_L2_APPL_LIST,
		'req_attrs' => [qw( id )],
	},
	'command' => {
		'attributes' => {
			'id' => 'nid',
			'application' => ['node','application'],
			'p_command' => ['node','command'],
			'command_type' => ['enum','cct_command_type'],
		},
		'parent_selfnode_attr' => 'p_command',
		'parent_node_attr' => 'application',
		'req_attrs' => [qw( id application command_type )],
	},
	'command_var' => {
		'attributes' => {
			'id' => 'nid',
			'command' => ['node','command'],
			'name' => 'str',
		},
		'parent_node_attr' => 'command',
		'req_attrs' => [qw( id command name )],
	},
);

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 CONSTRUCTOR FUNCTIONS AND CONTAINER METHODS

=head2 new()

	my $model = SQL::SyntaxModel->new();

This function creates a new SQL::SyntaxModel (or subclass) object/container and
returns it.  This object has contains a set of super-nodes, and nothing else.

=cut

######################################################################

sub new {
	my ($class) = @_;
	my $self = bless( {}, ref($class) || $class );
	$self->{$MPROP_CONTAINER} = bless( {}, $self->_get_container_class_name() );
	$self->_set_initial_container_props();
	return( $self );
}

sub _get_container_class_name {
	return( 'SQL::SyntaxModel::_::Container' );
}

sub _set_initial_container_props {
	my $container = $_[0]->{$MPROP_CONTAINER};
	$container->{$CPROP_ALL_NODES} = { map { ($_ => {}) } keys %NODE_TYPES };
	$container->{$CPROP_ROOT_NODE} = $container->create_node( { 
		$ARG_NODE_TYPE => $SQLSM_ROOT_NODE_TYPE, 
		$ARG_CHILDREN => [
			{ $ARG_NODE_TYPE => $SQLSM_L2_TYPE_LIST, },
			{ $ARG_NODE_TYPE => $SQLSM_L2_DTBS_LIST, },
			{ $ARG_NODE_TYPE => $SQLSM_L2_APPL_LIST, },
		],
	} );
}

sub DESTROY {
	$_[0]->_destroy_container_props();
}

sub _destroy_container_props {
	my $container = $_[0]->{$MPROP_CONTAINER};
	foreach my $nodes_by_type (values %{$container->{$CPROP_ALL_NODES}}) {
		foreach my $node (values %{$nodes_by_type}) {
			%{$node} = ();
		}
	}
	%{$container} = ();
}

######################################################################

=head2 initialize()

	my $model->initialize();

This method resets the Container to the state it was in when it was returned by
new().  All of its member Nodes are destroyed, and new super-nodes are created.

=cut

######################################################################

sub initialize {
	my ($self) = @_;
	$self->_destroy_container_props();
	$self->_set_initial_container_props();
}

######################################################################
# Shims for methods declared in Container class.

sub get_root_node {
	return( $_[0]->{$MPROP_CONTAINER}->get_root_node() );
}

sub get_node {
	return( $_[0]->{$MPROP_CONTAINER}->get_node( $_[1], $_[2] ) );
}

sub create_node {
	return( $_[0]->{$MPROP_CONTAINER}->create_node( $_[1] ) );
}

sub create_nodes {
	$_[0]->{$MPROP_CONTAINER}->create_nodes( $_[1] );
}

######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::_::Container;

######################################################################

sub _get_static_const_super_node_types {
	return( \%SUPER_NODE_TYPES );
}

sub _get_static_const_node_types {
	return( \%NODE_TYPES );
}

######################################################################

=head2 get_root_node()

	my $root = $model->get_root_node();

This method returns a reference to this object's single root Node.

=cut

######################################################################

sub get_root_node {
	return( $_[0]->{$CPROP_ROOT_NODE} );
}

######################################################################

=head2 get_node( NODE_TYPE[, NODE_ID] )

	my $database_node = $model->get_node( 'database', 1 );
	my $database_list_supernode = $model->get_node( 'database_list' );

This method returns a reference to one of this object's member Nodes, which has
a Node type of NODE_TYPE, and an 'id' attribute of NODE_ID.  The NODE_ID
argument is ignored if the requested type is one of the 4 super-nodes;
otherwise it is required.

=cut

######################################################################

sub get_node {
	my ($self, $node_type, $node_id) = @_;
	$node_type or return( undef );
	if( $SUPER_NODE_TYPES{$node_type} ) {
		$node_id = $SUPER_NODE_FILE_ID;
	}
	$node_id and return( $self->{$CPROP_ALL_NODES}->{$node_type}->{$node_id} );
}

######################################################################

=head2 create_node( { NODE_TYPE, ATTRS[, PARENT][, CHILDREN] } )

	my $node = $model->create_node( 
		{ 'NODE_TYPE' => 'database', 'ATTRS' => { 'id' => 1, } } ); 

This function creates a new Node object within the context of the current
Container and returns it.  It takes a hash ref containing up to 4 named
arguments: NODE_TYPE, ATTRS, PARENT, CHILDREN.  The first argument, NODE_TYPE,
is a string which specifies the "node_type" property of the new Node.  Only
specific values are allowed, which you can see in the previous POD section
"BRIEF NODE TYPE LIST".  A Node's type must be set on instantiation and it can
not be changed afterwards.  The second argument, ATTRS, is a hash ref whose
elements will go in the "attributes" property of the new Node; at least one
attribute, 'id', is mandatory and must be provided.  Any attributes which will
refer to another Node can be passed in as either a Node object reference or an
integer which matches the 'id' attribute of an already created Node.  The third
(optional) argument, PARENT, is a ref or integer matching an existing Node that
you want to explicitely set as the new Node's primary parent; it will go in the
"parent_node" property.  The fourth (optional) argument, CHILDREN, is an array
ref whose elements will go in the "child_nodes" property of the new object. 
Elements in CHILDREN are always processed after the other arguments.

=cut

######################################################################

sub create_node {
	my ($self, $args) = @_;

	unless( ref( $args ) eq 'HASH' ) {
		Carp::confess( "$CLSNMC->create_node(): invalid argument list; ".
			"no hash ref was passed, but rather '@{[defined($args)?$args:'']}'" );
	}

	my $node = bless( {}, $self->_get_node_class_name() );

	$node->{$NPROP_CONTAINER} = $self;

	my $node_type = $args->{$ARG_NODE_TYPE}; 
	my $type_info = $NODE_TYPES{$node_type};
	unless( $type_info ) {
		Carp::confess( "$CLSNMC->create_node(): invalid NODE_TYPE argument; ".
			"there is no Node type named '$node_type'" );
	}
	$node->{$NPROP_NODE_TYPE} = $node_type;

	$node->{$NPROP_ATTRIBUTES} = {}; # an attr may get set in set_parent
	$node->{$NPROP_CHILD_NODES} = [];

	$node->set_parent_node( $args->{$ARG_PARENT} ); # or parent may be set by attrs
	$node->_add_attributes( $args->{$ARG_ATTRS} ); # also adds to ALL_NODES when 'id' met
	unless( $node->{$NPROP_PARENT_NODE} or $node_type eq $SQLSM_ROOT_NODE_TYPE ) {
		$self->_create_node__do_when_parent_not_set( $node );
	}
	$node->_check_for_required_attributes();

	$self->_create_node__post_proc( $node );

	$node->add_child_nodes( $args->{$ARG_CHILDREN} );

	return( $node );
}

sub _get_node_class_name {
	return( 'SQL::SyntaxModel::_::Node' );
}

sub _create_node__do_when_parent_not_set {
	my ($self, $node) = @_;
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $node_id = $node->{$NPROP_ATTRIBUTES}->{$ATTR_ID};
	Carp::confess( "$CLSNMC->create_node(): invalid argument list; ".
		"the Node you are trying to create, of type '$node_type' and id ".
		"'$node_id', has no primary parent Node, and one is required" );
}

sub _create_node__post_proc {}

######################################################################

=head2 create_nodes( LIST )

	$model->create_nodes( [{ ... }, { ... }] );
	$model->create_nodes( { ... } );

This function takes an array ref in its single LIST argument, and calls
create_node() for each element found in it.

=cut

######################################################################

sub create_nodes {
	my ($self, $list) = @_;
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$self->create_node( $element );
	}
}

######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::_::Node;

######################################################################

=head1 INDIVIDUAL NODE PROPERTY ACCESSOR METHODS

=head2 get_container()

	my $model = $node->get_container();

This method returns the SQL::SyntaxModel object which this Node belongs to.

=cut

######################################################################

sub get_container {
	return( $_[0]->{$NPROP_CONTAINER} );
}

######################################################################

=head2 get_node_type()

	my $type = $node->get_node_type();

This method returns the "node_type" scalar property of this object.  You can
not change this property on an existing Node, but you can set it on a new one.

=cut

######################################################################

sub get_node_type {
	return( $_[0]->{$NPROP_NODE_TYPE} );
}

######################################################################

=head2 get_parent_node()

	my $parent = $node->get_parent_node();

This method returns the parent Node of this object, if there is one.

=cut

######################################################################

sub get_parent_node {
	return( $_[0]->{$NPROP_PARENT_NODE} );
}

######################################################################

=head2 set_parent_node( PARENT )

	$node->set_parent_node( $parent );

This method allows you to replace this object's parent Node with a new Node. 
The argument PARENT must either be a Node ref that can be a parent or an 'id'
number that would match the current Node's default parent Node type.

=cut

######################################################################

sub set_parent_node {
	my ($self, $parent) = @_;

	my $container = $self->{$NPROP_CONTAINER};
	my $node_type = $self->{$NPROP_NODE_TYPE};
	my $type_info = $NODE_TYPES{$node_type};

	$node_type eq $SQLSM_ROOT_NODE_TYPE and return( 1 ); # Root Node never has a parent.

	if( my $supernode_type = $type_info->{'parent_supernode_type'} ) {
		# This current Node will always have a specific super-node as its parent.
		$self->{$NPROP_PARENT_NODE} and return( 1 ); # Assume already correct.
		$parent = $container->{$CPROP_ALL_NODES}->{$supernode_type}->{$SUPER_NODE_FILE_ID};
		$self->{$NPROP_PARENT_NODE} = $parent;
		push( @{$parent->{$NPROP_CHILD_NODES}}, $self );
		return( 1 );
	}

	# If we get here, any parent of the current Node will be a normal Node.

	$parent or return( 0 ); # Called with no argument whether or not we should have one.

	if( ref($parent) eq ref($self) ) {
		# The PARENT argument is a Node ref.

		# If $parent is same as current parent, nothing to change.
		$self->{$NPROP_PARENT_NODE} and $parent eq $self->{$NPROP_PARENT_NODE} and return( 1 );

		unless( $parent->{$NPROP_CONTAINER} eq $self->{$NPROP_CONTAINER} ) {
			Carp::confess( "$CLSNMN->set_parent_node(): invalid PARENT argument; ".
				"that Node is not in the same container as the current Node" );
		}

		my $p_node_type = $parent->{$NPROP_NODE_TYPE};

		if( $type_info->{'parent_selfnode_attr'} and $p_node_type eq $node_type ) {
			# The current Node may have parent of same type, and we have such.
			my $attr_name = $type_info->{'parent_selfnode_attr'};
			return( $self->_make_child_to_parent_link( $parent, $attr_name ) );
		}

		my $attr_name = $type_info->{'parent_node_attr'};
		my $exp_node_type = $type_info->{'attributes'}->{$attr_name}->[1];
		if( $p_node_type eq $exp_node_type ) {
			return( $self->_make_child_to_parent_link( $parent, $attr_name ) );
		}

		Carp::confess( "$CLSNMN->set_parent_node(): invalid PARENT argument; ".
			"a Node of type '$node_type' may not have a parent Node of type ".
			"'$p_node_type' which isn't linked through an attribute" );
	}

	# If we get here, PARENT is not a Node ref, so it needs to be an 'id' value.

	my $attr_name = $type_info->{'parent_node_attr'};
	my $exp_node_type = $type_info->{'attributes'}->{$attr_name}->[1];
	if( $container->{$CPROP_ALL_NODES}->{$exp_node_type}->{$parent} ) {
		# PARENT matches a valid Node id that we can link to.
		$parent = $container->{$CPROP_ALL_NODES}->{$exp_node_type}->{$parent};
		return( $self->_make_child_to_parent_link( $parent, $attr_name ) );
	}

	return( $self->_set_parent_node__do_when_no_id_match( 
		$parent, $attr_name, $exp_node_type ) );
}

sub _set_parent_node__do_when_no_id_match {
	# Method only gets called when $new_parent is valued and doesn't match an id or Node.
	my ($new_child, $new_parent, $attr_name, $exp_node_type) = @_; # $self eq $new_child
	Carp::confess( "$CLSNMN->set_parent_node(): invalid PARENT argument; ".
		"'@{[defined($new_parent)?$new_parent:'']}' is not a Node ref and it does not ".
		"match the id of any existing '$exp_node_type' node" );
}

sub _make_child_to_parent_link {
	# Method never called for super-nodes, so there is always an associated attribute.
	my ($new_child, $new_parent, $attr_name) = @_; # $self eq $new_child

	if( $new_child->{$NPROP_PARENT_NODE} ) {
		$new_child->_remove_parent_ref_to_child( $new_child->{$NPROP_PARENT_NODE} );
		# The two links in the child to the old parent are overwritten below.
	}

	push( @{$new_parent->{$NPROP_CHILD_NODES}}, $new_child );
	$new_child->{$NPROP_ATTRIBUTES}->{$attr_name} = $new_parent;
	$new_child->{$NPROP_PARENT_NODE} = $new_parent;
}

sub _remove_parent_ref_to_child {
	# Method never called for super-nodes, so there is always an associated attribute.
	my ($child, $old_parent) = @_;
	my $c_node_type = $child->{$NPROP_NODE_TYPE};
	my $c_type_info = $NODE_TYPES{$c_node_type};
	my $c_attr_info = $c_type_info->{'attributes'};
	# The next line first gets names of all child attributes that take a Node ref 
	# as their value, where the type of node is the same as the parent.
	# Then it reduces the list further to those who 'are' the same Node.
	# It is assumed to return at least one attribute name, since a Node's 
	# parent always matches one of its attributes when parent not a super-node.
	my @candidate_attr_names = grep { 
			$child->{$NPROP_ATTRIBUTES}->{$_} eq $old_parent
		} grep { 
			ref($c_attr_info->{$_}) eq 'ARRAY' and 
			$c_attr_info->{$_}->[0] eq 'node' and $c_attr_info->{$_}->[1] eq $c_node_type
		} keys %{$c_attr_info};
	# The link in the old parent that points to the child is broken iif there is exactly 
	# one child attribute pointing to it, since that is what we are replacing.
	if( scalar( @candidate_attr_names ) == 1 ) {
		my $siblings = $old_parent->{$NPROP_CHILD_NODES};
		@{$siblings} = grep { $_ ne $child } @{$siblings};
	}
}

######################################################################

=head2 attribute( KEY[, VALUE] )

	my $curr_val = $node->attribute( 'name' );
	my $curr_val = $node->attribute( 'name', $new_val );

This method is an accessor for the "node_attrs" hash property of this object,
and allows you to retrieve or set the one hash element that is matched by KEY.
If VALUE is defined, the element is set to that value.  The current value is
then always returned.

=cut

######################################################################

sub attribute {
	my ($self, $key, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->add_attributes( { $key => $new_value } );
	}
	return( $self->{$NPROP_ATTRIBUTES}->{$key} );
}

######################################################################

=head2 get_attributes()

	my $rh_attrs = $node->get_attributes();

This method returns a shallow copy of the "node_type" hash property of this
object, which is returned as a hash ref.

=cut

######################################################################

sub get_attributes {
	return( {%{$_[0]->{$NPROP_NODE_TYPE}}} );
}

######################################################################

=head2 add_attributes( ATTRS )

	$node->add_attributes( $rh_attrs );

This method allows you to add key/value pairs to the "node_attrs" hash property
of this object, as provided in the ATTRS hash ref argument; any like-named keys
will overwrite existing ones, but different-named ones will coexist.

=cut

######################################################################

sub add_attributes {
	my ($self, $attrs) = @_;
	$self->_add_attributes( $attrs );
	$self->_check_for_required_attributes();
}

sub _add_attributes {
	my ($self, $attrs) = @_;

	my $container = $self->{$NPROP_CONTAINER};
	my $node_type = $self->{$NPROP_NODE_TYPE};
	my $type_info = $NODE_TYPES{$node_type};

	if( $SUPER_NODE_TYPES{$node_type} ) { # super-nodes never have attributes
		# Only one of each type of super-node is allowed to exist in a model.
		if( $container->{$CPROP_ALL_NODES}->{$node_type}->{$SUPER_NODE_FILE_ID} ) {
			Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
				"a '$node_type' Node already exists in this model; you may not make another" );
		}
		# Register Node here, since it won't be registered by an 'id' attribute below.
		# Note: this code probably shouldn't be in the add_attributes() method, but elsewhere.
		$container->{$CPROP_ALL_NODES}->{$node_type}->{$SUPER_NODE_FILE_ID} = $self;
		return( 1 );
	}

	unless( ref($attrs) eq 'HASH' ) {
		Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument for '$node_type' Node; ".
			"it is not a hash ref, but rather is '@{[defined($attrs)?$attrs:'']}'" );
	}

	foreach my $attr_name ($self->_sort_attrs_for_insert_order( $attrs )) {
		my $attr_info = $type_info->{'attributes'}->{$attr_name};
		unless( $attr_info ) {
			Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
				"there is no attribute named '$attr_name' in '$node_type' Nodes" );
		}
		my ($attr_type, $exp_ref_type) = 
			ref($attr_info) eq 'ARRAY' ? @{$attr_info} : $attr_info;
		my $attr_value = $attrs->{$attr_name};

		if( my $old_attr_value = $self->{$NPROP_ATTRIBUTES}->{$attr_name} ) {
			if( ref($attr_value) eq ref($old_attr_value) and $attr_value eq $old_attr_value ) {
				next; # New value same as old value, nothing to change.
			}
		}

		if( $attr_name eq $ATTR_ID or $attr_type eq 'nid' ) {
			# Currently processing an 'id' attribute; treat it special.
			if( !$attr_value or $attr_value < 1 or int($attr_value) ne $attr_value ) {
				Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
					"the '$ATTR_ID' attribute in all Nodes may only be a positive integer; ".
					"you tried to set it to '@{[defined($attr_value)?$attr_value:'']}'" );
			}
			if( $container->{$CPROP_ALL_NODES}->{$node_type}->{$attr_value} ) {
				# Note: you should never get here if you explicitely set the same 'id' this Node already has  
				Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
					"the '$ATTR_ID' attribute value of '$attr_value' you tried to set for this ".
					"'$node_type' Node is already in use by an existing Node; it must be unique" );
			}
			if( my $old_node_id = $self->{$NPROP_ATTRIBUTES}->{$ATTR_ID} ) {
				# This Node already had an 'id' attribute, meaning we are trying to change it.
				delete( $container->{$CPROP_ALL_NODES}->{$node_type}->{$old_node_id} );
			}
			$container->{$CPROP_ALL_NODES}->{$node_type}->{$attr_value} = $self; # register Node

		} elsif( !defined( $attr_value ) ) {
			# This is an attempt to erase the attribute; do nothing here.

		} elsif( $attr_type eq 'enum' ) {
			unless( $CONSTANT_CODE_TYPES{$exp_ref_type}->{$attr_value} ) {
				Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
					"the attribute named '$attr_name' in '$node_type' Nodes ".
					"may not have a value of '$attr_value'" );
			}

		} elsif( $attr_type eq 'node' ) {
			if( ref($attr_value) eq ref($self) ) {
				unless( $attr_value->{$NPROP_CONTAINER} eq $container ) {
					Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
						"that Node is not in the same container as the current Node" );
				}
				my $f_node_type = $attr_value->{$NPROP_NODE_TYPE};
				unless( $f_node_type eq $exp_ref_type ) {
					Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
						"the attribute named '$attr_name' in '$node_type' Nodes may ".
						"only reference a Node of type '$exp_ref_type', but the ".
						"given Node is of type '$f_node_type'" );
				}
			} elsif( $container->{$CPROP_ALL_NODES}->{$exp_ref_type}->{$attr_value} ) {
				# Attribute matches a valid Node id that we can link to.
				$attr_value = $container->{$CPROP_ALL_NODES}->{$exp_ref_type}->{$attr_value};
			} else {
				# Either throw an error, or a subclass can try to match a Node.
				$attr_value = $self->_add_attributes__do_when_no_id_match( 
					$attr_name, $attr_value, $exp_ref_type );
			}

		} elsif( $attr_type eq 'bool' ) {
			if( int($attr_value) ne $attr_value or ($attr_value != 0 and $attr_value != 1) ) {
				Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
					"the attribute named '$attr_name' in '$node_type' may only be a boolean value, ".
					"as expressed by '0' or '1'; you tried to set it to '$attr_value'" );
			}

		} elsif( $attr_type eq 'uint' ) {
			if( $attr_value < 0 or int($attr_value) ne $attr_value ) {
				Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
					"the attribute named '$attr_name' in '$node_type' may only be a non-negative ".
					"integer; you tried to set it to '$attr_value'" );
			}

		} else {} # $attr_type eq 'str'; no change to value needed

		if( !defined( $attr_value ) ) {
			if( exists( $self->{$NPROP_ATTRIBUTES}->{$attr_name} ) ) {
				if( $attr_type eq 'node' ) {
					# Note: the following method will also delete an attribute.
					$self->_make_attribute_to_parent_link( $attr_name );
				} else {
					delete( $self->{$NPROP_ATTRIBUTES}->{$attr_name} );
				}
			}
		} elsif( $attr_type eq 'node' ) {
			$self->_make_attribute_to_parent_link( $attr_name, $attr_value );
		} else {
			$self->{$NPROP_ATTRIBUTES}->{$attr_name} = $attr_value;
		}
	}

	my $inh_attrs = $type_info->{'inherited_selfnode_attrs'};
	# When the parent of a node is the same type as it, inherit/copy these attributes.
	# These always override any explicitely set ATTRS input values.
	if( $inh_attrs ) {
		my $parent = $self->{$NPROP_PARENT_NODE};
		if( $parent->{$NPROP_NODE_TYPE} eq $node_type ) {
			foreach my $attr_name (@{$inh_attrs}) {
				my $attr_value = $parent->{$NPROP_ATTRIBUTES}->{$attr_name};
				my $attr_info = $type_info->{'attributes'}->{$attr_name};
				if( ref($attr_info) eq 'ARRAY' and $attr_info->[0] eq 'node' ) {
					$self->_make_attribute_to_parent_link( $attr_name, $attr_value );
				} else {
					$self->{$NPROP_ATTRIBUTES}->{$attr_name} = $attr_value;
				}
			}
		}
	}
}

sub _sort_attrs_for_insert_order {
	my ($self, $attrs) = @_;
	return( sort keys %{$attrs} ); # sorting ensures tests see same result on all platforms
}

sub _check_for_required_attributes {
	my ($self) = @_;
	my $node_type = $self->{$NPROP_NODE_TYPE};
	my $type_info = $NODE_TYPES{$node_type};
	my $req_attrs = $type_info->{'req_attrs'};
	# Enforcing required attributes right now may seem dubious, as one may want to add 
	# them individually later.  However, we'll try doing it here anyway.
	if( $req_attrs ) {
		foreach my $attr_name (@{$req_attrs}) {
			unless( defined( $self->{$NPROP_ATTRIBUTES}->{$attr_name} ) ) {
				Carp::confess( "$CLSNMN->add_attributes(): missing ATTRS argument element; ".
					"the attribute named '$attr_name' in '$node_type' Nodes ".
					"must be given a value" );
			}
		}
	}
}

sub _add_attributes__do_when_no_id_match {
	# Method only gets called when $new_parent is valued and doesn't match an id or Node.
	my ($new_child, $attr_name, $attr_value, $exp_node_type) = @_; # $self eq $new_child
	my $node_type = $new_child->{$NPROP_NODE_TYPE};
	Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument element; ".
		"'@{[defined($attr_value)?$attr_value:'']}' is not a Node ref and it does not ".
		"match the id of any existing '$exp_node_type' node" );
}

sub _make_attribute_to_parent_link {
	# Method never called for super-nodes, so there is always an associated attribute.
	# This method has been overloaded to also handle deleting of an attribute.
	my ($new_child, $attr_name, $new_parent) = @_; # $self eq $new_child

	if( $new_child->{$NPROP_ATTRIBUTES}->{$attr_name} ) {
		$new_child->_remove_parent_ref_to_child( $new_child->{$NPROP_ATTRIBUTES}->{$attr_name} );
		# The link or two in the child to the old parent are overwritten below.
	}

	if( defined( $new_parent ) ) { # we are adding a link
		push( @{$new_parent->{$NPROP_CHILD_NODES}}, $new_child );
		$new_child->{$NPROP_ATTRIBUTES}->{$attr_name} = $new_parent;
	} else { # we are deleting a link
		delete( $new_child->{$NPROP_ATTRIBUTES}->{$attr_name} );
	}

	my $c_type_info = $NODE_TYPES{$new_child->{$NPROP_NODE_TYPE}};
	if( my $selfnode_attr = $c_type_info->{'parent_selfnode_attr'} ) {
		if( $attr_name eq $selfnode_attr ) {
			$new_child->{$NPROP_PARENT_NODE} = $new_parent;
		} elsif( $attr_name eq $c_type_info->{'parent_node_attr'} ) {
			unless( $new_child->{$NPROP_ATTRIBUTES}->{$selfnode_attr} ) {
				$new_child->{$NPROP_PARENT_NODE} = $new_parent;
			}
		}
	} elsif( $attr_name eq $c_type_info->{'parent_node_attr'} ) {
		$new_child->{$NPROP_PARENT_NODE} = $new_parent;
	}
}

######################################################################

=head2 get_child_nodes([ NODE_TYPE ])

	my $ra_node_list = $node->get_child_nodes();
	my $ra_node_list = $node->get_child_nodes( 'table' );

This method returns a list of this object's child Nodes, in a new array ref. 
If the optional argument NODE_TYPE is defined, then only child Nodes of that
node type are returned; otherwise, all child Nodes are returned.  All Nodes 
are returned in the same order they were added.

=cut

######################################################################

sub get_child_nodes {
	my ($self, $node_type) = @_;
	if( defined( $node_type ) ) {
		return( [grep { $_->{$NPROP_NODE_TYPE} eq $node_type } @{$self->{$NPROP_CHILD_NODES}}] );
	} else {
		return( [@{$self->{$NPROP_CHILD_NODES}}] );
	}
}

######################################################################

=head2 add_child_node( CHILD || { NODE_TYPE, ATTRS[, CHILDREN] } )

	$node->add_child_node( $child );
	my $child = $node->add_child_node( 
		{ 'NODE_TYPE' => 'namespace', 'ATTRS' => { 'id' => 1, } } ); 

This method allows you to add a new child Node to this object, which is
provided as the single method argument.  The new child Node is appended to the
list of existing Nodes; all existing Nodes are preserved.  If the argument is a
Node ref, CHILD, then that Node's parent will be changed to this current node
if possible.  If the argument is a Hash ref, then a new Node will be
constructed from it (see the 'create_node' method documentation), with this
current node being its parent.  The new child is returned.

=cut

######################################################################

sub add_child_node {
	my ($self, $child) = @_;
	if( ref($child) eq ref($self) ) {
		$child->set_parent_node( $self ); # Should die if in separate container.
		return( $child );
	} elsif( ref($child) eq 'HASH' ) {
		$child->{$ARG_PARENT} = $self;
		return( $self->{$NPROP_CONTAINER}->create_node( $child ) );
	} else {
		Carp::confess( "$CLSNMN->add_child_nodes(): invalid CHILD argument element; ".
			"'@{[defined($child)?$child:'']}' is not a Node ref or a hash ref" );
	}
}

######################################################################

=head2 add_child_nodes( LIST )

	$model->add_child_nodes( [$child1,$child2] );
	$model->add_child_nodes( $child );

This function takes an array ref in its single LIST argument, and calls
add_child_node() for each element found in it.

=cut

######################################################################

sub add_child_nodes {
	my ($self, $list) = @_;
	$list or return( undef );
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$self->add_child_node( $element );
	}
}

######################################################################

=head2 delete_node()

	$node->delete_node();

This method will destroy the Node object that it is invoked from, if it can. 
You are only allowed to delete Nodes that have no child Nodes; if your chosen
Node has children, you must delete them first.  Following this method call, the
Node ref you used to hold will be non-functional.

=cut

######################################################################

sub delete_node {
	my ($self) = @_;

	my $container = $self->{$NPROP_CONTAINER};
	my $node_type = $self->{$NPROP_NODE_TYPE};
	my $node_id = $self->{$NPROP_ATTRIBUTES}->{$ATTR_ID};

	if( $SUPER_NODE_TYPES{$node_type} ) {
		Carp::confess( "$CLSNMN->delete_node(): this '$node_type' Node".
			"is a mandatory super-node, which can not be deleted" );
	}

	if( scaler( @{$self->{$NPROP_CHILD_NODES}} ) > 0 ) {
		Carp::confess( "$CLSNMN->delete_node(): you may not delete this ".
			"Node, which has type '$node_type' and id '$node_id', because ".
			"it has child nodes" );
	}

	# Break references from parent Nodes to ourself.
	foreach my $parent (values %{$self->{$NPROP_ATTRIBUTES}}) {
		my $siblings = $parent->{$NPROP_CHILD_NODES};
		@{$siblings} = grep { $_ ne $self } @{$siblings};
	}

	# Break references from our Container to ourself.
	delete( $container->{$CPROP_ALL_NODES}->{$node_type}->{$node_id} );

	# Break references to our Container from ourself (no children to break).
	%{$self} = ();
}

######################################################################

=head1 NODE METHODS FOR DEBUGGING

=head2 get_all_properties()

	$rh_node_properties = $node->get_all_properties();

This method returns a deep copy of all of the properties of this object as
non-blessed Perl data structures.  These data structures are also arranged in a
tree, but they do not have any circular references.  You may be able to take
the output of this method and recreate the original objects by passing it to
create_node(), although this may not work reliably.  The main purpose,
currently, of get_all_properties() is to make it easier to debug or test this
class; it makes it easier to see at a glance whether the other class methods
are doing what you expect.  The output of this method should also be easy to
serialize or unserialize to strings of Perl code or xml or other things, should
you want to compare your results easily by string compare (see
"get_all_properties_as_perl_str()" and "get_all_properties_as_xml_str()").

=cut

######################################################################

sub get_all_properties {
	return( $_[0]->_get_all_properties() );
}

sub _get_all_properties {
	my ($self) = @_;
	my %dump = ();

	$dump{$ARG_NODE_TYPE} = $self->{$NPROP_NODE_TYPE};

	my $attrs_in = $self->{$NPROP_ATTRIBUTES};
	$dump{$ARG_ATTRS} = {map { ( $_ => (
			ref($attrs_in->{$_}) eq ref($self) ? 
			$attrs_in->{$_}->{$NPROP_ATTRIBUTES}->{$ATTR_ID} : 
			$attrs_in->{$_}
		) ) } keys %{$attrs_in}};

	my @children_out = ();
	my %children_were_output = ();
	foreach my $child (@{$self->{$NPROP_CHILD_NODES}}) {
		if( $child->{$NPROP_PARENT_NODE} eq $self ) {
			# Only output child if we are its primary parent, not simply any parent.
			unless( $children_were_output{$child} ) {
				# Only output child once; a child may link to same parent multiple times.
				push( @children_out, $child->_get_all_properties() );
				$children_were_output{$child} = 1;
			}
		}
	}
	$dump{$ARG_CHILDREN} = \@children_out;

	return( \%dump );
}

######################################################################

=head2 get_all_properties_as_perl_str([ NO_INDENTS ])

	$perl_code_str = $node->get_all_properties_as_perl_str();
	$perl_code_str = $node->get_all_properties_as_perl_str( 1 );

This method is a wrapper for get_all_properties() that serializes its output
into a pretty-printed string of Perl code, suitable for humans to read.  You
should be able to eval this string and produce the original structure.  By
default, contents of lists are indented under the lists they are in (easier to
read); if the optional boolean argument NO_INDENTS is true, then all output
lines will be flush with the left, saving a fair amount of memory in what the
resulting string consumes.  (That said, even the indents are tabs, which take
up much less space than multiple spaces per indent level.)

=cut

######################################################################

sub get_all_properties_as_perl_str {
	return( $_[0]->_serialize_as_perl( $_[1], $_[0]->get_all_properties() ) );
}

sub _serialize_as_perl {
	my ($self, $ind, $input, $pad, $is_key, $is_val) = @_;
	$pad ||= '';
	my $padc = $ind ? "" : "$pad\t";
	my %key_order = ( $ARG_NODE_TYPE => 3, $ARG_ATTRS => 2, $ARG_CHILDREN => 1, );
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( ($is_val ? '' : $pad).'{ '.(%{$input}?"\n":''), ( map { 
				( $self->_serialize_as_perl( $ind,$_,$padc,1 ), 
				$self->_serialize_as_perl( $ind,$input->{$_},$padc,undef,1 ) ) 
			} sort { ($key_order{$b}||0) <=> ($key_order{$a}||0) } 
				keys %{$input} ), (%{$input}?$pad:'').'}, '."\n" ) 
		: ref($input) eq 'ARRAY' ? 
			( ($is_val ? '' : $pad).'[ '.(@{$input}?"\n":''), ( map { 
				( $self->_serialize_as_perl( $ind,$_,$padc ) ) 
			} @{$input} ), (@{$input}?$pad:'').'], '."\n" ) 
		: defined($input) ?
			($is_val ? '' : $pad)."'$input'".($is_key ? ' => ' : ', '."\n")
		: ($is_val ? '' : $pad)."undef".($is_key ? ' => ' : ', '."\n")
	) );
}

######################################################################

=head2 get_all_properties_as_xml_str([ NO_INDENTS ])

	$xml_doc_str = $node->get_all_properties_as_xml_str();
	$xml_doc_str = $node->get_all_properties_as_xml_str( 1 );

This method is a wrapper for get_all_properties() that serializes its output
into a pretty-printed string of XML, suitable for humans to read. By default,
child nodes are indented under their parent nodes (easier to read); if the
optional boolean argument NO_INDENTS is true, then all output lines will be
flush with the left, saving a fair amount of memory in what the resulting
string consumes.  (That said, even the indents are tabs, which take up much
less space than multiple spaces per indent level.)

=cut

######################################################################

sub get_all_properties_as_xml_str {
	return( $_[0]->_serialize_as_xml( $_[1], $_[0]->get_all_properties() ) );
}

sub _serialize_as_xml {
	my ($self, $ind, $node, $pad) = @_;
	$pad ||= '';
	my $padc = $ind ? "" : "$pad\t";
	my $attrs = $node->{$ARG_ATTRS};
	return( join( '', 
		$pad.'<'.$node->{$ARG_NODE_TYPE},
		(map { ' '.$_.'="'.$attrs->{$_}.'"' } sort { 
				# sort 'id' first and others follow alphabetically
				($a eq $ATTR_ID) ? -1 : ($b eq $ATTR_ID) ? 1 : ($a cmp $b) 
			} keys %{$attrs}),
		(scalar(@{$node->{$ARG_CHILDREN}}) ? (
			'>'."\n",
			(map { $self->_serialize_as_xml( $ind,$_,$padc ) } @{$node->{$ARG_CHILDREN}}),
			$pad.'</'.$node->{$ARG_NODE_TYPE}.'>'."\n",
		) : ' />'."\n"),
	) );
}

######################################################################

1;
__END__

=head1 BUGS

This module is currently in alpha development status, meaning that any part of
it stands a reasonable chance of being changed in the future, in incompatible
ways.  Also, the module hasn't been tested as much as I would like, but it has
tested the more commonly used areas.  All of the code in the SYNOPSIS section
has been executed, which tests most internal functions and data.

Some basic types of SQL or functionality that this module is supposed to
implement are not written yet; these correspond mostly to functionality that is
also lacking a description in DataDictionary.pod.  The mainly affected areas
are: applications, commands, command variables.  In addition, trying to declare
a view inside another view or a block probably won't work, as the currently
implemented rule set says they can only be declared as children of namespaces.
Related to this, some or all of the views that are shown in the SYNOPSIS (and
test script) would actually be declared in the application space rather than
the database space, because these views would not be stored in the database,
but rather be used as select-statements.  In fact, the 'command_var' expression
type used in some views would only work in an application-called select, as
those correspond to caller bind variables.  That said, updating this module and
DataDictionary.pod to add the functionality is in my first to-do priority.

This module currently throws exceptions whenever it is provided with bad input,
which include some details of what the bad input is; it uses Carp::confess to
throw the exceptions, as a stack trace should make bad input problems easier to
debug, considering that this module uses a fair amount of recursion and wrapper
methods.  Due to the fact that each individual input element is applied hot
once it is validated, these changes will still stick even if other input
elements you provided during the same method call were incorrect and generated
an exception; exceptions are also generated immediately, with subsequent inputs
not being processed.  Because of this, if you trap exceptions that this class
generates with your own eval block, you should know that both the
SQL::SyntaxModel Node that you were working on and quite possibly several other
nodes related to it are now in an inconsistant state.  If you continue to use
those Nodes, or others that are linked to them in any way, the program may
crash without the friendly exceptions, as data which this module expects to be
consistant (as it would be when there are no exceptions) would not be.  I
expect to deal with this problem at some time in the future, such as trying to 
defer the exception throw until I can clean up the state first.

This module currently does not prevent the user from creating circular
references between Nodes, such as "A is the child of B and B is the child of
A"; however, only a few types of Nodes (such as 'view' and 'block' and
'*_expr') even make this possible.

This module is still functionally biased towards adding new Nodes that are
correct on first insertion (and for fetching data from the Nodes), since that
is how it is expected the module would normally be used.  The functionality is
more lackluster in regards to making significant changes after the fact.  You
can not delete more than one Node at a time.  It isn't easy to create Nodes
piecemeal, such as one attribute at a time (at least the mandatory attributes
must be present on creation), and attaching it to the tree after the fact;
piecemeal business must be handled externally to the module, prior to
insertion.  Some of these will be addressed later when there is the need.

=head1 SEE ALSO

perl(1), SQL::SyntaxModel::DataDictionary, SQL::SyntaxModel::XMLSchema,
SQL::SyntaxModel::API_C, SQL::SyntaxModel::SkipID, Rosetta, Rosetta::Framework,
DBI, SQL::Statement, SQL::Translator, SQL::YASP, SQL::Generator, SQL::Schema,
SQL::Abstract, SQL::Snippet, SQL::Catalog, DB::Ent, DBIx::Abstract,
DBIx::AnyDBD, DBIx::DBSchema, DBIx::Namespace, DBIx::SearchBuilder,
TripleStore.

=cut
