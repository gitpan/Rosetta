=head1 NAME

SQL::SyntaxModel::SkipID - Use SQL::SyntaxModels without inputting Node IDs

=cut

######################################################################

package SQL::SyntaxModel::SkipID;
require 5.004;
use strict;
use warnings;
use vars qw($VERSION @ISA);
$VERSION = '0.06';

######################################################################

=head1 COPYRIGHT AND LICENSE

This file is an optional part of the SQL::SyntaxModel library (libSQLSM).

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

	SQL::SyntaxModel 0.06 (parent class)

=cut

######################################################################

use Carp;
use SQL::SyntaxModel 0.06;
@ISA = qw( SQL::SyntaxModel );

######################################################################

=head1 SYNOPSIS

	use strict;
	use warnings;

	use SQL::SyntaxModel::SkipID;

	my $model = SQL::SyntaxModel::SkipID->new();

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

=head1 DESCRIPTION

This Perl 5 object class is a completely optional extension to
SQL::SyntaxModel, and is implemented as a sub-class of that module.  The public
interface to this module is essentially the same as the other one, with the
difference being that SQL::SyntaxModel::SkipID will accept a wider variety of
input data formats into its methods.  Therefore, this module's documentation 
does not list or explain its methods (see the parent class for that), but it 
will mention any differences from the parent.

The extension is intended to be fully parent-compatible, meaning that if
you provide it input which would be acceptable to the stricter bare parent
class, then you will get the same behaviour.  Where you will see the difference
is when you provide certain kinds of input which would cause the parent class
to return an error and/or throw an exception.

One significant added feature, which is part of this module's name-sake, is
that it will automatically generate (by serial number) a new Node's "id"
attribute when your input doesn't provide one.  A related name-sake feature is
that, when you want to refer to an earlier created Node by a later one, for
purposes of linking them, you can refer to the earlier Node by a more
human-readable attribute than the Node's "id" (or Node ref), such as its 'name'
(which is also what actual SQL uses).  Between these two name-sake features, it
is possible to use SQL::SyntaxModel without ever having to explicitely see a
Node's "id" attribute.

Note that, for the sake of avoiding conflicts, you should not be explicitely
setting ids for some Nodes of a type, and having others auto-generated, unless
you take extra precautions.  This is because while auto-generated Node ids will
not conflict with prior explicit ones, later provided explicit ones may
conflict with auto-generated ones.  How you can resolve this is to use the
parent class' get_node() method to see if the id you want is already in use.
The same caveats apply as if the auto-generator was a second concurrent user
editing the object.  This said, you can mix references from one Node to another
between id and non-id ref types without further consequence, because they don't
change the id of a Node.

Another added feature is that this class can automatically assign a parent Node
for a newly created Node that doesn't explicitely specify a parent in some way,
such as in a create_node() argument or by the fact you are calling
add_child_node().  This automatic assignment is context-sensitive, whereby the
most recent previously-created Node which is capable of becoming the new one's
parent will do so.

This module's added features can make it "easier to use" in some circumstances
than the bare-bones SQL::SyntaxModel, including an appearance more like actual
SQL strings, because matching descriptive terms can be used in multiple places.

However, the functionality has its added cost in code complexity and
reliability; for example, since non-id attributes are not unique, the module
can "guess wrong" about what you wanted to do, and it won't work at all in some
circumstances.  Additionally, since your code, by using this module, would use
descriptive attributes to link Nodes together, you will have to update every
place you use the attribute value when you change the original, so they
continue to match; this is unlike the bare parent class, which always uses
non-descriptive attributes for links, which you are unlikely to ever change.
The added logic also makes the code slower and use more memory.

=cut

######################################################################

# These are duplicate declarations of properties in the SQL::SyntaxModel parent class.
my $MPROP_CONTAINER = 'container'; # holds all the actual Container properties for this class
my $CPROP_ALL_NODES  = 'all_nodes'; # hash of hashes of Node refs; find any Node by node_type:node_id quickly
my $NPROP_CONTAINER   = 'container'; # ref to Container this Node lives in
my $NPROP_NODE_TYPE   = 'node_type'; # str - what type of Node this is
my $NPROP_PARENT_NODE = 'parent_node'; # ref to primary parent Node; dupl attr unl parent is supernode
my $NPROP_ATTRIBUTES  = 'attributes'; # hash - attributes of this Node, incl refs to all parent Nodes
my $NPROP_CHILD_NODES = 'child_nodes'; # array - list of refs to other Nodes citing self as parent

# These are Container properties that SQL::SyntaxModel::SkipID added:
my $CPROP_LAST_NODES = 'last_nodes'; # hash of node refs; find last node created of each node type
my $CPROP_HIGH_IDS   = 'last_id'; # hash of int; = highest node_id num currently in use by each node_type

# These are duplicate declarations of arguments taken by the create_node() parent method:
my $ARG_NODE_TYPE = 'NODE_TYPE'; # str - what type of Node we are
my $ARG_ATTRS     = 'ATTRS'; # hash - our attributes, including refs/ids of parents we will have

# Duplicate declaration: names of special Node attributes are declared here:
my $ATTR_ID = 'id'; # int - unique identifier for a Node within its type

# Duplicate declaration: this is used by error messages; errors will be reimplemented later:
my $CLSNMC = 'SQL::SyntaxModel::SkipID';
my $CLSNMN = 'SQL::SyntaxModel::SkipID::_::Node';

# This constant is used by the related node searching feature, and relates 
# to the %NODE_TYPES_EXTRA_DETAILS hash, below.
#my $R = '/'; # start at the model's root node
my $S = '.'; # when same node type directly inside itself, make sure on parentmost of current
my $P = '..'; # means go up one parent level
my $HACK1 = '[]'; # means use [view_src.name+table_col.name] to find a view_src_col in current view_rowset

my %NODE_TYPES_EXTRA_DETAILS = (
	'data_type' => {
		'link_search_attr' => 'name',
		'def_attr' => 'basic_type',
		'attr_defaults' => {
			'id' => ['uid'],
			'basic_type' => ['lit','str'],
		},
	},
	'database' => {
		'link_search_attr' => 'name',
		'def_attr' => 'id',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'namespace' => {
		'link_search_attr' => 'name',
		'def_attr' => 'id',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'table' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
			'order' => ['uid'],
		},
	},
	'table_col' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
			'order' => ['uid'],
			'required_val' => ['lit',0],
		},
	},
	'table_ind' => {
		'search_paths' => {
			'f_table' => [$P,$P], # match child table in current namespace
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
			'order' => ['uid'],
		},
	},
	'table_ind_col' => {
		'search_paths' => {
			'table_col' => [$P,$P], # match child col in current table
			'f_table_col' => [$P,'f_table'], # match child col in foreign table
		},
		'def_attr' => 'table_col',
		'attr_defaults' => {
			'id' => ['uid'],
			'order' => ['uid'],
		},
	},
	'view' => {
		'search_paths' => {
			'match_table' => [$P], # match child table in current namespace
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
			'view_type' => ['lit','caller'],
			'may_write' => ['lit',0],
		},
	},
	'view_col' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
			'order' => ['uid'],
		},
	},
	'view_rowset' => {
		'attr_defaults' => {
			'id' => ['uid'],
			'p_rowset_order' => ['uid'],
		},
	},
	'view_src' => {
		'search_paths' => {
			'match_table' => [$P,$S,$P,$P], # match child table in current namespace
			'match_view' => [$P,$S,$P,$P], # match child view in current namespace
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
			'order' => ['uid'],
		},
	},
	'view_src_col' => {
		'search_paths' => {
			'match_table_col' => [$P,'match_table'], # match child col in other table
			'match_view_col' => [$P,'match_view'], # match child col in other view
		},
		'link_search_attr' => 'match_table_col',
		'def_attr' => 'match_table_col',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'view_join' => {
		'search_paths' => {
			'lhs_src' => [$P], # match child view_src in current view_rowset
			'rhs_src' => [$P], # match child view_src in current view_rowset
		},
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'view_join_col' => {
		'search_paths' => {
			'lhs_src_col' => [$P,'lhs_src',['table_col',[$P,'match_table']]], # ... recursive code
			'rhs_src_col' => [$P,'rhs_src',['table_col',[$P,'match_table']]], # ... recursive code
		},
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'view_col_def' => {
		'search_paths' => {
			'view_col' => [$S,$P,$S,$P], # match child col in current view
			'src_col' => [$S,$P,$HACK1,['table_col',[$P,'match_table']]], # match a src+table_col in current namespace
			'f_view' => [$S,$P,$S,$P,$P], # match child view in current namespace
			'ufunc' => [$S,$P,$S,$P,$P], # match child block in current namespace
		},
		'attr_defaults' => {
			'id' => ['uid'],
			'p_expr_order' => ['uid'],
		},
	},
	'view_part_def' => {
		'search_paths' => {
			'src_col' => [$S,$P,$HACK1,['table_col',[$P,'match_table']]], # match a src+table_col in current namespace
			'f_view' => [$S,$P,$S,$P,$P], # match child view in current namespace
			'ufunc' => [$S,$P,$S,$P,$P], # match child block in current namespace
		},
		'attr_defaults' => {
			'id' => ['uid'],
			'p_expr_order' => ['uid'],
		},
	},
	'sequence' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'block' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'block_var' => {
		'search_paths' => {
			'data_type' => [$P,$S,$P,$P,$P], # match child datatype of root
			'c_view' => [$P,$S,$P], # match child view in current namespace
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
	},
	'block_stmt' => {
		'search_paths' => {
			'dest_var' => [$P], # match child block_var in current block
			'c_block' => [$P], # link to child block of current block
		},
	},
	'block_expr' => {
		'search_paths' => {
			'src_var' => [$S,$P,$P], # match child block_var in current block
			'ufunc' => [$S,$P,$S,$P,$P], # match child block in current namespace
		},
	},
	'user' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'privilege' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'application' => {
		'link_search_attr' => 'name',
		'def_attr' => 'id',
		'attr_defaults' => {
			'id' => ['uid'],
		},
	},
	'command_var' => {
		'link_search_attr' => 'name',
		'def_attr' => 'name',
	},
);

######################################################################

sub _get_container_class_name {
	return( 'SQL::SyntaxModel::SkipID::_::Container' );
}

sub _set_initial_container_props {
	my $container = $_[0]->{$MPROP_CONTAINER};
	my $node_types = $container->_get_static_const_node_types();
	$container->{$CPROP_LAST_NODES} = { map { ($_ => undef) } keys %{$node_types} };
	$container->{$CPROP_HIGH_IDS} = { map { ($_ => 0) } keys %{$node_types} };
	$_[0]->SUPER::_set_initial_container_props();
}

######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::SkipID::_::Container;
use vars qw(@ISA);
@ISA = qw( SQL::SyntaxModel::_::Container );

######################################################################

sub create_node {
	my ($self, $args) = @_;
	unless( ref( $args ) eq 'HASH' ) {
		$args = { $ARG_NODE_TYPE => $args };
	}
	return( $self->SUPER::create_node( $args ) );
}

sub _get_node_class_name {
	return( 'SQL::SyntaxModel::SkipID::_::Node' );
}

sub _create_node__do_when_parent_not_set {
	# Called either if a PARENT arg not given, or if it matched nothing.
	my ($self, $node) = @_;
	my $node_types = $self->_get_static_const_node_types();
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $type_info = $node_types->{$node_type};
	my $attr_name = $type_info->{'parent_node_attr'};
	my $exp_node_type = $type_info->{'attributes'}->{$attr_name}->[1];
	if( my $parent = $self->{$CPROP_LAST_NODES}->{$exp_node_type} ) {
		$node->_make_child_to_parent_link( $parent, $attr_name );
	} else {
		$self->SUPER::_create_node__do_when_parent_not_set( $node );
	}
}

sub _create_node__post_proc {
	my ($self, $node) = @_;
	my $node_type = $node->{$NPROP_NODE_TYPE};
	$self->{$CPROP_LAST_NODES}->{$node_type} = $node; # assign reference
	my $super_node_types = $self->_get_static_const_super_node_types();
	unless( $super_node_types->{$node_type} ) {
		my $node_id = $node->{$NPROP_ATTRIBUTES}->{$ATTR_ID};
		if( $node_id > $self->{$CPROP_HIGH_IDS}->{$node_type} ) {
			$self->{$CPROP_HIGH_IDS}->{$node_type} = $node_id;
		}
	}
}

######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::SkipID::_::Node;
use vars qw(@ISA);
@ISA = qw( SQL::SyntaxModel::_::Node );

######################################################################

sub _set_parent_node__do_when_no_id_match {
	# Method only gets called when $new_parent is valued and doesn't match an id or Node.
	my ($self, $new_parent, $attr_name, $exp_node_type) = @_; # $self eq $new_child
	# See if PARENT matches a non-id node attribute we can link to.
	# Note that this will only work properly if used attribute value is unique.
	if( my $found = $self->_find_node_by_link_search_attr( $exp_node_type, $new_parent ) ) {
		return( $self->_make_child_to_parent_link( $new_parent, $attr_name ) );
	}
	# If we get here there was no match, a value will be taken later from LAST NODES.
}

sub _find_node_by_link_search_attr {
	my ($self, $exp_node_type, $attr_value) = @_;
	my $container = $self->{$NPROP_CONTAINER};
	my $link_search_attr = $NODE_TYPES_EXTRA_DETAILS{$exp_node_type}->{'link_search_attr'};
	foreach my $scn (values %{$container->{$CPROP_ALL_NODES}->{$exp_node_type}}) {
		if( $scn->{$NPROP_ATTRIBUTES}->{$link_search_attr} eq $attr_value ) {
			return( $scn );
		}
	}
}

######################################################################

sub _add_attributes {
	my ($self, $attrs) = @_;
	defined( $attrs ) or $attrs = {};

	my $node_type = $self->{$NPROP_NODE_TYPE};
	my $node_info_extras = $NODE_TYPES_EXTRA_DETAILS{$node_type};

	unless( ref($attrs) eq 'HASH' ) {
		my $def_attr = $node_info_extras->{'def_attr'};
		unless( $def_attr ) {
			Carp::confess( "$CLSNMN->add_attributes(): invalid ATTRS argument; ".
				"it is not a hash ref, but rather is '$attrs'; ".
				"also, nodes of type '$node_type' have no default ".
				"attribute to associate the given value with" );
		}
		$attrs = { $def_attr => $attrs };
	}

	my $container = $self->{$NPROP_CONTAINER};

	my $attr_defaults = $node_info_extras && $node_info_extras->{'attr_defaults'};
	# This is placed here so that default strs can be processed into nodes below.
	if( $attr_defaults ) {
		foreach my $attr_name (keys %{$attr_defaults}) {
			unless( exists( $self->{$NPROP_ATTRIBUTES}->{$attr_name} ) ) {
				unless( exists( $attrs->{$attr_name} ) ) {
					my ($def_type,$arg) = @{$attr_defaults->{$attr_name}};
					if( $def_type eq 'uid' ) { # meant for 'id', but same values given to 'order'
						$attrs->{$attr_name} = 1 + $container->{$CPROP_HIGH_IDS}->{$node_type};
					} else { # $def_type eq 'lit'
						$attrs->{$attr_name} = $arg;
					}
				}
			}
		}
	}

	$self->SUPER::_add_attributes( $attrs );
}

sub _sort_attrs_for_insert_order {
	my ($self, $attrs) = @_;
	my $node_types = $self->{$NPROP_CONTAINER}->_get_static_const_node_types();
	my $type_info = $node_types->{$self->{$NPROP_NODE_TYPE}};
	my $selfnode_attr = $type_info->{'parent_selfnode_attr'};
	my $parent_attr = $type_info->{'parent_node_attr'};
	return( 
		$ATTR_ID, 
		(($selfnode_attr and exists($attrs->{$selfnode_attr})) ? $selfnode_attr : ()), 
		(($parent_attr and exists($attrs->{$parent_attr})) ? $parent_attr : ()), 
		(sort grep { 
			$_ ne $ATTR_ID 
			and not ($parent_attr and $_ eq $parent_attr) 
			and not ($selfnode_attr and $_ eq $selfnode_attr) 
		} keys %{$attrs}), 
	);
}

sub _add_attributes__do_when_no_id_match {
	# Method only gets called when $attr_value is valued and doesn't match an id or Node.
	my ($self, $attr_name, $attr_value, $exp_node_type) = @_;

	my $container = $self->{$NPROP_CONTAINER};
	my $node_type = $self->{$NPROP_NODE_TYPE};

	my $node_info_extras = $NODE_TYPES_EXTRA_DETAILS{$node_type};
	my $search_path = $node_info_extras->{'search_paths'}->{$attr_name};

	my $attr_value_out = undef;
	if( !$search_path ) {
		# No specific search path given, so search all nodes of the type.
		$attr_value_out = $self->_find_node_by_link_search_attr( $exp_node_type, $attr_value );
	} elsif( $attr_value ) { # note: attr_value may be a defined empty string
		unless( $self->{$NPROP_PARENT_NODE} ) {
			# Note: due to the above sorting, any attrs which could have set the 
			# parent would be evaluated before ...no_id_match called for first time.
			# We auto-set the parent here, earlier than create_node() would have, 
			# so that the current unresolved attr can use it in its search path.
			$container->_create_node__do_when_parent_not_set( $self );
		}
		my $curr_node = $self;
		$attr_value_out = $self->_search_for_node( 
			$attr_value, $exp_node_type, $search_path, $curr_node );
	}

	if( $attr_value_out ) {
		return( $attr_value_out );
	} else {
		$self->SUPER::_add_attributes__do_when_no_id_match( 
			$attr_name, $attr_value, $exp_node_type );
	}
}

sub _search_for_node {
	my ($self, $search_attr_value, $exp_node_type, $search_path, $curr_node) = @_;

	my $recurse_next = undef;

	foreach my $path_seg (@{$search_path}) {
		if( ref($path_seg) eq 'ARRAY' ) {
			# We have arrived at the parent of a possible desired node, but picking 
			# the correct child is more complicated, and will be done below.
			$recurse_next = $path_seg;
			last;
		} elsif( $path_seg eq $S ) {
			# Want to progress search via consec parents of same node type to first.
			my $start_type = $curr_node->{$NPROP_NODE_TYPE};
			while( $curr_node->{$NPROP_PARENT_NODE} and $start_type eq
					$curr_node->{$NPROP_PARENT_NODE}->{$NPROP_NODE_TYPE} ) {
				$curr_node = $curr_node->{$NPROP_PARENT_NODE};
			}
		} elsif( $path_seg eq $P ) {
			# Want to progress search to the parent of the current node.
			if( $curr_node->{$NPROP_PARENT_NODE} ) {
				# There is a parent node, so move to it.
				$curr_node = $curr_node->{$NPROP_PARENT_NODE};
			} else {
				# There is no parent node; search has failed.
				$curr_node = undef;
				last;
			}
		} elsif( $path_seg eq $HACK1 ) {
			# Assume curr_node is now a 'view_rowset'; we want to find a view_src_col below it.
			# search_attr_value should be an array having 2 elements: view_src.name+table_col.name.
			# Progress search down one child node, so curr_node becomes a 'view_src'.
			my $to_be_curr_node = undef;
			my ($col_name, $src_name) = @{$search_attr_value};
			foreach my $scn (@{$curr_node->{$NPROP_CHILD_NODES}}) {
				if( $scn->{$NPROP_NODE_TYPE} eq 'view_src' ) {
					if( $scn->{$NPROP_ATTRIBUTES}->{'name'} eq $src_name ) {
						# We found a node in the correct path that we can link.
						$to_be_curr_node = $scn;
						$search_attr_value = $col_name;
						last;
					}
				}
			}
			$curr_node = $to_be_curr_node;
		} else {
			# Want to progress search via an attribute of the current node.
			if( $curr_node->{$NPROP_ATTRIBUTES}->{$path_seg} ) {
				# The current node has that attribute, so move to it.
				$curr_node = $curr_node->{$NPROP_ATTRIBUTES}->{$path_seg};
			} else {
				# There is no attribute present; search has failed.
				$curr_node = undef;
				last;
			}
		}
	}

	my $node_to_link = undef;

	if( $curr_node ) {
		# Since curr_node is still defined, the search succeeded, 
		# or the search path was an empty list (means search self).
		my $link_search_attr = $NODE_TYPES_EXTRA_DETAILS{$exp_node_type}->{'link_search_attr'};
		foreach my $scn (@{$curr_node->{$NPROP_CHILD_NODES}}) {
			if( $scn->{$NPROP_NODE_TYPE} eq $exp_node_type ) {
				if( $recurse_next ) {
					my ($i_exp_node_type, $i_search_path) = @{$recurse_next};
					my $i_node_to_link = undef;
					$i_node_to_link = $self->_search_for_node( 
						$search_attr_value, $i_exp_node_type, $i_search_path, $scn );

					if( $i_node_to_link ) {
						if( $scn->{$NPROP_ATTRIBUTES}->{$link_search_attr} eq $i_node_to_link ) {
							$node_to_link = $scn;
							last;
						}
					}
				} else {
					if( $scn->{$NPROP_ATTRIBUTES}->{$link_search_attr} eq $search_attr_value ) {
						# We found a node in the correct path that we can link.
						$node_to_link = $scn;
						last;
					}
				}
			}
		}
	}

	return( $node_to_link );
}

######################################################################

1;
__END__

=head1 BUGS

First of all, see the BUGS main documentation section of the SQL::SyntaxModel,
as everything said there applies to this module also.  Exceptions are below.

This module is currently in alpha development status.  All of the code in the
SYNOPSIS section has been executed, which tests most internal functions and
data, but no other tests have been made.

The mechanisms for automatically linking nodes to each other, and particularly
for resolving parent-child node relationships, are under-developed (somewhat
hackish) at the moment and probably won't work properly in all situations.
However, they do work for the sample code.  This linking code will gradually be
improved if there is a need.  

Please note that SkipID.pm is not a priority for me in further development, and
it mainly exists for historical sake, so that some older functionality that I
went to the trouble to create for SQL::SyntaxModel in versions 0.01 thru 0.05
would not simply vanish when I trimmed it from the core module.  Those who want
the older functionality can still use it.  Any further development on my part
will be limited mainly to keeping it compatible with changes to
SQL::SyntaxModel such that it can still execute its SYNOPSIS Perl code
correctly.  I have no plans to add significant new features to this module.

Likewise, if you would like to adopt SQL::SyntaxModel::SkipID with respect to
CPAN and become the primary maintainer, then please write me to arrange it. 
The main things that I ask in return are to be credited as the original author,
and for you to keep the module functionally compatible with new versions of the
parent module as they are released (I will try to make it easy).

=head1 SEE ALSO

SQL::SyntaxModel, and other items in its SEE ALSO documentation.

=cut
