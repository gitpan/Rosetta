=head1 NAME

SQL::ObjectModel - Unserialized SQL objects, use like XML DOM

=cut

######################################################################

package SQL::ObjectModel;
require 5.004;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.032';

######################################################################

=head1 COPYRIGHT AND LICENSE

This file is part of the SQL::ObjectModel library (libSOM).

SQL::ObjectModel is Copyright (c) 1999-2003, Darren R. Duncan.  All rights
reserved.  Address comments, suggestions, and bug reports to
B<perl@DarrenDuncan.net>, or visit "http://www.DarrenDuncan.net" for more
information.

SQL::ObjectModel is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License (GPL) version 2 as published
by the Free Software Foundation (http://www.fsf.org/).  You should have
received a copy of the GPL as part of the SQL::ObjectModel distribution, in the
file named "LICENSE"; if not, write to the Free Software Foundation, Inc., 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA.

Any versions of SQL::ObjectModel that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits. SQL::ObjectModel is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GPL for more details.

Linking SQL::ObjectModel statically or dynamically with other modules is making
a combined work based on SQL::ObjectModel.  Thus, the terms and conditions of
the GPL cover the whole combination.

As a special exception, the copyright holders of SQL::ObjectModel give you
permission to link SQL::ObjectModel with independent modules that are
interfaces to or implementations of databases, regardless of the license terms
of these independent modules, and to copy and distribute the resulting combined
work under terms of your choice, provided that every copy of the combined work
is accompanied by a complete copy of the source code of SQL::ObjectModel (the
version of SQL::ObjectModel used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on SQL::ObjectModel, and
which is fully useable when not linked to SQL::ObjectModel in any form.

Note that people who make modified versions of SQL::ObjectModel are not
obligated to grant this special exception for their modified versions; it is
their choice whether to do so.  The GPL gives permission to release a modified
version without this exception; this exception also makes it possible to
release a modified version which carries forward this exception.

While it is by no means required, the copyright holders of SQL::ObjectModel
would appreciate being informed any time you create a modified version of
SQL::ObjectModel that you are willing to distribute, because that is a
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

=head1 DESCRIPTION

This Perl 5 object class is intended to be a powerful but easy to use
replacement for SQL strings (including support for placeholders), which you can
use to make queries against a database.  Each SQL::ObjectModel object can
represent a non-ambiguous structured command for a database to execute, or one
can be a non-ambiguous structured description of a database schema object.  This
class supports all types of database operations, including both data
manipulation and schema manipulation, as well as managing database instances
and users.  You typically construct a database query by setting appropriate
attributes of these objects, and you execute a database query by evaluating the
same attributes.  SQL::ObjectModel objects are designed to be equivalent to SQL
in both the type of information they carry and in their conceptual structure.
This is analagous to how XML DOMs are objects that are equivalent to XML
strings, and they can be converted back and forth at will.  If you know SQL, or
even just relational database theory in general, then this module should be
easy to learn.

SQL::ObjectModels are intended to represent all kinds of SQL, both DML and DDL,
both ANSI standard and RDBMS vendor extensions.  Unlike basically all of the
other SQL generating/parsing modules I know about, which are limited to basic
DML and only support table definition DDL, this class supports arbitrarily
complex select statements, with composite keys and unions, and calls to stored
functions; this class can also define views and stored procedures and triggers.
Some of the existing modules, even though they construct complete SQL, will
take/require fragments of SQL as input (such as "where" clauses)  By contrast,
SQL::ObjectModel takes no SQL fragments.  All of its inputs are atomic, which
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
interfaces. SQL::ObjectModel is designed to represent a normalized superset of
all database features that one may reasonably want to use.  "Superset" means
that if even one database supports a feature, you will be able to invoke it
with this class. You can also reference some features which no database
currently implements, but it would be reasonable for one to do so later.
"Normalized" means that if multiple databases support the same feature but have
different syntax for referencing it, there will be exactly one way of referring
to it with SQL::ObjectModel.  So by using this class, you will never have to
change your database-using code when moving between databases, as long as both
of them support the features you are using (or they are emulated).  That said,
it is generally expected that if a database is missing a specific feature that
is easy to emulate, then code which evaluates SQL::ObjectModels will emulate it
(for example, emulating "left()" with "substr()"); in such cases, it is
expected that when you use such features they will work with any database.  For
example, if you want a model-specified boolean data type, you will always get
it, whether it is implemented  on a per-database-basis as a "boolean" or an
"int(1)" or a "number(1,0)".  Or a model-specified "str" data type you will
always get it, whether it is called "text" or "varchar2" or "sql_varchar".

SQL::ObjectModel is intended to be just a stateless container for database
query or schema information.  It does not talk to any databases by itself and
it does not generate or parse any SQL; rather, it is intended that other third
party modules or code of your choice will handle this task.  In fact,
SQL::ObjectModel is designed so that many existing database related modules
could be updated to use it internally for storing state information, including
SQL generating or translating modules, and schema management modules, and
modules which implement object persistence in a database.  Conceptually
speaking, the DBI module itself could be updated to take SQL::ObjectModel
objects as arguments to its "prepare" method, as an alternative (optional) to
the SQL strings it currently takes.  Code which implements the things that
SQL::ObjectModel describes can do this in any way that they want, which can
mean either generating and executing SQL, or generating Perl code that does the
same task and evaling it, should they want to (the latter can be a means of
emulation).  This class should make all of that easy.

SQL::ObjectModel is especially suited for use with applications or modules that
make use of data dictionaries to control what they do.  It is common in
applications that they interpret their data dictionaries and generate SQL to
accomplish some of their work, which means making sure generated SQL is in the
right dialect or syntax, and making sure literal values are escaped correctly.
By using this module, applications can simply copy appropriate individual
elements in their data dictionaries to SQL::ObjectModel properties, including
column names, table names, function names, literal values, bind variable names,
and they don't have to do any string parsing or assembling.

Now, I can only imagine why all of the other SQL generating/parsing modules
that I know about have excluded privileged support for more advanced database
features like stored procedures.  Either the authors didn't have a need for it,
or they figured that any other prospective users wouldn't need it, or they
found it too difficult to implement so far and maybe planned to do it later. As
for me, I can see tremendous value in various advanced features, and so I have
included privileged support for them in SQL::ObjectModel.  You simply have to
work on projects of a significant size to get an idea that these features would
provide a large speed, reliability, and security savings for you.  Look at many
large corporate or government systems, such as those which have hundreds of
tables or millions of records, and that may have complicated business logic
which governs whether data is consistent/valid or not.  Within reasonable
limits, the more work you can get the database to do internally, the better.  I
believe that if these features can also be represented in a database-neutral
format, such as what SQL::ObjectModel attempts to do, then users can get the
full power of a database without being locked into a single vendor due to all
their investment in vendor-specific SQL stored procedure code.  If customers
can move a lot more easily, it will help encourage database vendors to keep
improving their products or lower prices to keep their customers, and users in
general would benefit.  So I do have reasons for trying to tackle the advanced
database features in SQL::ObjectModel.

=head1 STRUCTURE

A SQL::ObjectModel is implemented as a set of one or more related nodes (that
have named attributes) which are organized into a structure resembling a tree,
except that the tree can have more than one "root" (a node without parents),
and that branches can join with other branches.  Only one Perl class is needed
currently (called SQL::ObjectModel), with each class object being one node. 
One node is quite simple and generic in structure, and has only basic rules
governing when and how it can link with specific other nodes, based mainly on
its "node_type" object property; this property is set only when a node is
instantiated and can not be changed afterwards.  But that is all it takes to
implement the needed features.  

Note: It is possible in the future that more classes may be added, some of
which may subclass the basic node class, and others which don't.  If we end up
with an explicit "document" or "container" or "context" class in which all
nodes would live, as normal XML DOMs do, then SQL::ObjectModel will probably
become that container.  Until then, SQL::ObjectModel is the node class itself.

These are the 4 conceptual properties of a SQL::ObjectModel object:

=over 4

=item 0

B<node_type> (mandatory) - A string with a limited set of allowed values.

=item 0

B<node_attrs> (recommended) - A hash ref whose allowed keys depend on the value
of node_type, and whose values can be either a scalar or a reference to another
node.  Each attribute value may be constrained to a certain data type or to a
value from an enumerated list.

=item 0

B<parent_node> (optional) - A reference to another node.  The other node can
only be of a type which the current node is allowed to be a child of.

=item 0

B<child_nodes> (optional) - An array ref whose elements are references to other
nodes. The allowed types of child nodes depend on the type of the current node.

=back

A node could represent a table or a view or a block (procedure) or a DML
command or a part of any of those, or another schema object used by one or more
of those, or a variety of other things.  Each node is related to another by
only one of mainly two ways, which is either "B is a part of A" or "B is used
by A".  In the first scenario, B is a child node of A and A is the parent node
of B.  In the second scenario, a reference to B is an attribute of A, but
neither is a parent or child of the other.

If a SQL::ObjectModel were converted into an XML DOM or an XML Document, then
each node would be an XML "tag", with the "tag name" being the "node_type",
node attributes being tag attributes, parent-child node relationships being
exactly the same in XML, and "joined branches" being specific attribute values
in one tag that are the same as specific attributes in a different tag.  Also,
the multiplicity of SQL::ObjectModel "root" nodes would also be first children
of a new single XML root node, or a similar arrangement.

If a SQL::ObjectModel were converted into a data dictionary and stored in a
database, then each node would conceptually be one record in the database, and
each node attribute would be a field value in that record.  Each "node_type"
would be a distinct database table having said records, and each table would
have different columns, as each node type specifies a different set of node
attributes.  When two nodes are in a parent-child relationship (B is a part of
A), the database record of the child node would have a foreign key constraint
on it that references the table of the parent node; this would be the "main"
foreign key constraint on the child table.  A table would also have foreign key
constraints for each "B is used by A" relationship between two nodes, but that
would not be the "main" relationship.  When you represent a SQL::ObjectModel
with a relational database, the so-called "joined branches" are indirect 
many-to-many table relationships.

You should look at the POD-only file named SQL::ObjectModel::DataDictionary,
which came with this distribution.  It serves to document all of the possible
node types, with attributes, constraints, and allowed relationships with other
node types, by way of describing a suitable database schema for storing these
nodes in, such as was mentioned in the previous paragraph.  As the
SQL::ObjectModel class itself has very few properties and methods, all being
highly generic (much akin to an XML DOM), the POD of this PM file will only
describe how to use said methods, and will not list all the allowed inputs or
constraints to said methods.  With only simple guidance in ObjectMode.pm, you
should be able to interpret DataDictionary.pod to get all the nitty gritty
details.  You should also look at the tutorial or example files which will be
in the distribution when ready, or such sample code here.

Here is a diagram showing just the conceptually high-level node types, grouped 
in their logical "B is part of A" relationships (which may go through lower level 
node types that aren't shown here):

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
	   +-command (SQL that is not "part of a schema", although it includes DML for schema)
	      +-view (a select statement usually)
	      +-block (an anonymous block or set of normal SQL to run in sequence)

=head1 BRIEF NODE TYPE LIST

This is a brief list of all the valid types that a SQL::ObjectModel node can
be.  Descriptions can be found by looking up the corresponding table names in
SQL::ObjectModel::DataDictionary, although a more detailed summary is planned
to be added here.  Note that this list isn't finalized and will be subject to 
various changes; these will also have corresponding changes in DataDictionary.

SQL OBJECT MODEL ROOT NODE

	root

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

COMMANDS AND RESULTS

	command

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $PROP_NODE_TYPE   = 'node_type'; # str - akin to dd table name
my $PROP_PARENT_NODE = 'parent_node'; # ref to parent node, if any (main parent rec)
my $PROP_NODE_ATTRS  = 'node_attrs'; # hash - akin to dd record values
my $PROP_CHILD_NODES = 'child_nodes'; # list of refs to child nodes, if any (main child recs)
	# at least conceptually; is actually a hash ref of array refs, one per allowed child type

# Named arguments corresponding to properties for objects of this class are
# declared here; they are currently only used with the new() function:
my $ARG_NODE_TYPE = 'NODE_TYPE'; # str - akin to dd table name
my $ARG_PARENT    = 'PARENT'; # ref to parent node, if any (main parent rec)
my $ARG_ATTRS     = 'ATTRS'; # hash - akin to dd record values
my $ARG_CHILDREN  = 'CHILDREN'; # list of refs to child nodes, if any (main child recs)

# These "args" is not currently used for any inputs, but the debugging methods will 
# output it in addition to the above (except for PARENT, which isn't returned).
my $ARG___OUT_NODE_NUM = '__OUT_NODE_NUM'; # unlike following, this should always have same numbers;
my $ARG___PNID = '__PNID'; # perl node id, the internal perl reference used; 
my $ARG___ATTRS_PNID = '__ATTRS_PNID'; # like above, but for attrs that are nodes;
	# exclude these when testing, as different perl executions won't return same numbers

# This is used by error messages; errors will be reimplemented later:
my $CLSNM = 'SQL::ObjectModel';

# These are programmatically recognized enumerations of values that 
# particular node attributes are allowed to have.  They are given names 
# here so that multiple node types can make use of the same value lists.  
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

# This constant is used by the related node searching feature, and relates 
# to the %NODE_TYPES hash, below.
my $S = '.'; # when same node type directly inside itself, make sure on parentmost of current
my $P = '..'; # means go up one parent level

# These are the allowed node types, with their allowed attributes and their 
# allowed child node types.  They are used for method input checking and 
# other related tasks.
my $SOM_ROOT_NODE_TYPE = 'root';
my %NODE_TYPES = (
	$SOM_ROOT_NODE_TYPE => {
		'children' => { map { ($_ => 1) } qw( data_type database command ) },
	},
	'data_type' => {
		'attributes' => {
			'name' => 'str',
			'basic_type' => ['enum','cct_basic_data_type'],
			'size_in_bytes' => 'int',
			'size_in_chars' => 'int',
			'size_in_digits' => 'int',
			'store_fixed' => 'bool',
			'str_encoding' => ['enum','cct_str_enc'],
			'str_trim_white' => 'bool',
			'str_latin_case' => ['enum','cct_str_latin_case'],
			'str_pad_char' => 'str',
			'str_trim_pad' => 'bool',
			'num_unsigned' => 'bool',
			'num_precision' => 'int',
			'datetime_calendar' => ['enum','cct_datetime_calendar'],
		},
		'link_search_attr' => 'name',
		'def_attr' => 'basic_type',
		'attr_defaults' => {
			'basic_type' => 'str',
		},
		'req_attr' => [qw( name basic_type )],
	},
	'database' => {
		'attributes' => {
			'id' => 'int',
			'name' => 'str',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'id',
		'attr_defaults' => {
			'id' => 1,
		},
		'req_attr' => [qw( id )],
		'children' => { map { ($_ => 1) } qw( namespace ) },
	},
	'namespace' => {
		'attributes' => {
			'id' => 'int',
			'name' => 'str',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'id',
		'attr_defaults' => {
			'id' => 1,
		},
		'req_attr' => [qw( id )],
		'children' => { map { ($_ => 1) } qw( table view sequence block ) },
	},
	'table' => {
		'attributes' => {
			'id' => 'int',
			'name' => 'str',
			'public_syn' => 'str',
			'storage_file' => 'str',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => 1,
		},
		'req_attr' => [qw( id name )],
		'children' => { map { ($_ => 1) } qw( table_col table_ind trigger ) },
	},
	'table_col' => {
		'attributes' => {
			'name' => 'str',
			'data_type' => ['node','data_type',[$P,$P,$P,$P]], # match child datatype of root
			'required_val' => 'bool',
			'default_val' => 'str',
			'auto_inc' => 'bool',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'data_type' => {}, # make a node with its own default values
		},
		'req_attr' => [qw( name data_type required_val )],
	},
	'table_ind' => {
		'attributes' => {
			'name' => 'str',
			'ind_type' => ['enum','cct_index_type'],
			'f_table' => ['node','table',[$P,$P]], # match child table in current namespace
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'req_attr' => [qw( name ind_type )],
		'children' => { map { ($_ => 1) } qw( table_ind_col ) },
	},
	'table_ind_col' => {
		'attributes' => {
			'col' => ['node','table_col',[$P,$P]], # match child col in current table
			'f_col' => ['node','table_col',[$P,'f_table']], # match child col in foreign table
		},
		'def_attr' => 'col',
		'req_attr' => [qw( col )],
	},
	'trigger' => {
		'attributes' => {
			'run_before' => 'bool',
			'run_after' => 'bool',
			'on_insert' => 'bool',
			'on_update' => 'bool',
			'on_delete' => 'bool',
			'for_each_row' => 'bool',
		},
		'req_attr' => [qw( run_before run_after on_insert on_update on_delete for_each_row )],
		'children' => { map { ($_ => 1) } qw( block ) },
	},
	'view' => {
		'attributes' => {
			'id' => 'int',
			'view_type' => ['enum','cct_view_type'],
			'name' => 'str',
			'public_syn' => 'str',
			'may_write' => 'bool',
			'match_table' => ['node','table',[$P]], # match child table in current namespace
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => 1,
			'view_type' => 'caller',
			'may_write' => 0,
		},
		'req_attr' => [qw( id type may_write )],
		'children' => { map { ($_ => 1) } qw( view_col view_rowset ) },
	},
	'view_col' => {
		'attributes' => {
			'name' => 'str',
			'data_type' => ['node','data_type',[$P,$P,$P,$P]], # match child datatype of root
			'sort_priority' => 'int',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'data_type' => {}, # make a node with its own default values
		},
		'req_attr' => [qw( name data_type )],
	},
	'view_rowset' => {
		'attributes' => {
			'c_merge_type' => ['enum','cct_rs_merge_type'],
		},
		'children' => { map { ($_ => 1) } qw( 
			view_rowset view_src view_join view_hierarchy view_col_def view_part_def
		) },
	},
	'view_src' => {
		'attributes' => {
			'name' => 'str',
			'match_table' => ['node','table',[$P,$S,$P,$P]], # match child table in current namespace
			'match_view' => ['node','view',[$P,$S,$P,$P]], # match child view in current namespace
				# as a special case (?), anonymous views are also linked thru this attr; are not child nodes
				# using this is the same as creating an anon datatype, which is also stored in attr
				# may be changed later, now is easier to handle programmatically (no extra code)
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'req_attr' => [qw( name )],
		'children' => { map { ($_ => 1) } qw( view_src_col ) },
	},
	'view_src_col' => {
		'attributes' => {
			'name' => 'str',
			'table_col' => ['node','table_col',[$P,'match_table']], # match child col in other table
			'view_col' => ['node','view_col',[$P,'match_view']], # match child col in other view
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'req_attr' => [qw( name )],
	},
	'view_join' => {
		'attributes' => {
			'lhs_src' => ['node','view_src',[$P]], # match child view_src in current view_rowset
			'rhs_src' => ['node','view_src',[$P]], # match child view_src in current view_rowset
			'join_type' => ['enum','cct_rs_join_type'],
		},
		'req_attr' => [qw( lhs_src rhs_src join_type )],
		'children' => { map { ($_ => 1) } qw( view_join_col ) },
	},
	'view_join_col' => {
		'attributes' => {
			'lhs_src_col' => ['node','view_src_col',[$P,'lhs_src']], # match child view_src_col in linked view_src
			'rhs_src_col' => ['node','view_src_col',[$P,'rhs_src']], # match child view_src_col in linked view_src
		},
		'req_attr' => [qw( lhs_src_col rhs_src_col )],
	},
	'view_hierarchy' => {
		'attributes' => {
			'src' => ['node','view_src',[$P]], # match child view_src in current view_rowset
			'start_src_col' => ['node','view_src_col',['src']], # match child view_src_col of view_src
			'start_lit_val' => 'str',
			'start_var_name' => 'str',
			'conn_src_col' => ['node','view_src_col',['src']], # match child view_src_col of view_src
			'p_conn_src_col' => ['node','view_src_col',['src']], # match child view_src_col of view_src
		},
		'first_attrs'  => { map { ($_ => 1) } qw( src ) },
		'req_attr' => [qw( start_src_col conn_src_col p_conn_src_col )],
	},
	'view_col_def' => {
		'attributes' => {
			'name' => ['node','view_col',[$S,$P,$S,$P]], # match child col in current view
			'expr_type' => ['enum','cct_basic_expr_type'],
			'lit_val' => 'str',
			'var_name' => 'str',
			'src' => ['node','view_src',[$S,$P]], # match child view_src in current view_rowset
			'src_col' => ['node','view_src_col',['src']], # match child view_src_col of view_src
			'f_view' => ['node','view',[$S,$P,$S,$P,$P]], # match child view in current namespace
				# this would also create/link anonymous views
			'sfunc' => ['enum','cct_standard_func'],
			'ufunc' => ['node','block',[$S,$P,$S,$P,$P]], # match child block in current namespace
		},
		'first_attrs'  => { map { ($_ => 1) } qw( src ) },
		'req_attr' => [qw( expr_type )],
		'children' => { map { ($_ => 1) } qw( view_col_def ) },
	},
	'view_part_def' => {
		'attributes' => {
			'view_part' => ['enum','cct_view_part'],
			'expr_type' => ['enum','cct_basic_expr_type'],
			'lit_val' => 'str',
			'var_name' => 'str',
			'src' => ['node','view_src',[$S,$P]], # match child view_src in current view_rowset
			'src_col' => ['node','view_src_col',['src']], # match child view_src_col of view_src
			'sfunc' => ['enum','cct_standard_func'],
			'ufunc' => ['node','block',[$S,$P,$S,$P,$P]], # match child block in current namespace
		},
		'first_attrs'  => { map { ($_ => 1) } qw( src ) },
		'req_attr' => [qw( expr_type )],
		'children' => { map { ($_ => 1) } qw( view_part_def ) },
	},
	'sequence' => {
		'attributes' => {
			'id' => 'int',
			'name' => 'str',
			'public_syn' => 'str',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => 1,
		},
		'req_attr' => [qw( id name )],
	},
	'block' => {
		'attributes' => {
			'id' => 'int',
			'block_type' => ['enum','cct_block_type'],
			'name' => 'str',
			'public_syn' => 'str',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => 1,
		},
		'req_attr' => [qw( id type )],
		'children' => { map { ($_ => 1) } qw( block block_var block_stmt ) },
	},
	'block_var' => {
		'attributes' => {
			'name' => 'str',
			'var_type' => ['enum','cct_basic_var_type'],
			'is_argument' => 'bool',
			'data_type' => ['node','data_type',[$P,$S,$P,$P,$P]], # match child datatype of root
			'init_lit_val' => 'str',
			'view' => ['node','view',[$P,$S,$P]], # match child view in current namespace
				# this would also create/link anonymous views
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'req_attr' => [qw( name var_type is_argument )],
	},
	'block_stmt' => {
		'attributes' => {
			'stmt_type' => ['enum','cct_basic_stmt_type'],
			'dest_var' => ['node','block_var',[$P]], # match child block_var in current block
			'sproc' => ['enum','cct_standard_proc'],
			'c_block' => ['node','block',[$P]], # link to child block of current block
		},
		'req_attr' => [qw( stmt_type )],
		'children' => { map { ($_ => 1) } qw( block_expr ) },
	},
	'block_expr' => {
		'attributes' => {
			'expr_type' => ['enum','cct_basic_expr_type'],
			'lit_val' => 'str',
			'var_name' => 'str',
			'src_var' => ['node','block_var',[$S,$P,$P]], # match child block_var in current block
			'sfunc' => ['enum','cct_standard_func'],
			'ufunc' => ['node','block',[$S,$P,$S,$P,$P]], # match child block in current namespace
		},
		'req_attr' => [qw( expr_type )],
		'children' => { map { ($_ => 1) } qw( block_expr ) },
	},
	'user' => {
		'attributes' => {
			'id' => 'int',
			'name' => 'str',
		},
		'link_search_attr' => 'name',
		'def_attr' => 'name',
		'attr_defaults' => {
			'id' => 1,
		},
		'req_attr' => [qw( id name )],
	},
	'command' => {
		'attributes' => {
			'command_type' => ['enum','cct_command_type'],
		},
		'req_attr' => [qw( comm_type )],
		'children' => { map { ($_ => 1) } qw( view block ) },
	},
);

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 CONSTRUCTOR FUNCTIONS AND METHODS

=head2 new( NODE_TYPE | { NODE_TYPE[, PARENT][, ATTRS][, CHILDREN] } )

This function creates a new SQL::ObjectModel (or subclass) object/node and
returns it.  It takes one actual argument, which is either the scalar NODE_TYPE
or a hash ref containing up to 4 named arguments: NODE_TYPE, PARENT, ATTRS,
CHILDREN.  The first argument, NODE_TYPE, is a string which specifies the
"node_type" property of the new object.  Only specific values are allowed,
which you can see in the previous POD section "BRIEF NODE TYPE LIST".  A node's
type must be set on instantiation and it can not be changed afterwards.  The
second (optional) argument, PARENT, is an object of this class which will go in
the "parent_node" property of the new object; it can be changed later.  The
third (optional) argument, ATTRS, is a hash ref whose elements will go in the
"node_attrs" property of the new object; they can be changed later.  The fourth
(optional) argument, CHILDREN, is an array ref whose elements will go in the
"child_nodes" property of the new object; they can be changed later.  The four
arguments are processed in the order shown above, with each being stored
immediately; this means that elements in CHILDREN can make references to nodes
in ATTRS elements and both can make reference to other nodes linked through a
new PARENT, this is true even if said items were created as part of the same
call to new().

=cut

######################################################################

sub new {
	my ($class, $args) = @_;
	my $self = bless( {}, ref($class) || $class );

	unless( ref( $args ) eq 'HASH' ) {
		$args = { $ARG_NODE_TYPE => $args };
	}

	my $node_type = $args->{$ARG_NODE_TYPE} || $SOM_ROOT_NODE_TYPE;
	my $type_info = $NODE_TYPES{$node_type};
	unless( $type_info ) {
		Carp::confess( "$CLSNM->new(): invalid NODE_TYPE argument; ".
			"there is no node type named '$node_type'" );
	}
	$self->{$PROP_NODE_TYPE} = $node_type;

	$self->set_parent_node( $args->{$ARG_PARENT} );
	$self->set_node_attributes( $args->{$ARG_ATTRS} );
	$self->set_child_nodes( $args->{$ARG_CHILDREN} );

	return( $self );
}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object
properties recognized by SQL::ObjectModel are set in the clone; other
properties are not changed.  Child nodes are deep-copied (a node can only have 
one parent), but references to nodes in attribute values are copied.

=cut

######################################################################

sub clone {
	my ($self, $clone) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );

	$clone->{$PROP_NODE_TYPE} = $self->{$PROP_NODE_TYPE};
	$clone->{$PROP_PARENT_NODE} = $self->{$PROP_PARENT_NODE};
	$clone->{$PROP_NODE_ATTRS} = {%{$self->{$PROP_NODE_ATTRS}}};

	$clone->{$PROP_CHILD_NODES} = {};
	foreach my $node_type (keys %{$self->{$PROP_CHILD_NODES}}) {
		my @clone_children = ();
		foreach my $self_child (@{$self->{$PROP_CHILD_NODES}->{$node_type}}) {
			my $clone_child = $self_child->clone();
			$clone_child->{$PROP_PARENT_NODE} = $clone; # don't point to old parent
		}
		$clone->{$PROP_CHILD_NODES}->{$node_type} = \@clone_children;
	}

	return( $clone );
}

######################################################################

=head1 INDIVIDUAL PROPERTY ACCESSOR METHODS

=head2 get_node_type()

This method returns the "node_type" scalar property of this object.  You can
not change this property on an existing node, but you can set it on a new one.

=cut

######################################################################

sub get_node_type {
	return( $_[0]->{$PROP_NODE_TYPE} );
}

######################################################################

=head2 get_parent_node()

This method returns the parent node of this object, if there is one.

=cut

######################################################################

sub get_parent_node {
	return( $_[0]->{$PROP_PARENT_NODE} );
}

######################################################################

=head2 set_parent_node( PARENT )

This method allows you to replace this object's parent node with a new node,
which is provided by the PARENT argument.  If PARENT is not defined, then the
existing parent node will simply be unlinked from this object.

=cut

######################################################################

sub set_parent_node {
	my ($self, $parent) = @_;

	if( $self->{$PROP_PARENT_NODE} ) {  # not called by new()
		$self->_unlink_parent_node_from_self();
	}

	if( defined( $parent ) ) {
		my $node_type = $self->{$PROP_NODE_TYPE};
		unless( UNIVERSAL::isa($parent,'SQL::ObjectModel') ) {
			Carp::confess( "$CLSNM->set_parent_node(): invalid PARENT argument; ".
				"it is not a $CLSNM object, but rather is '$parent'" );
		}
		my $p_node_type = $parent->{$PROP_NODE_TYPE};
		my $p_type_info = $NODE_TYPES{$p_node_type};
		unless( $p_type_info->{'children'}->{$node_type} ) {
			Carp::confess( "$CLSNM->set_parent_node(): invalid PARENT argument; ".
				"a node of type '$p_node_type' may not have ".
				"a child node of type '$node_type'" );
		}
		$self->{$PROP_PARENT_NODE} = $parent;
		push( @{$parent->{$PROP_CHILD_NODES}->{$node_type}}, $self );
	}
}

sub _unlink_parent_node_from_self {
	my ($self) = @_;
	my $siblings = $self->{$PROP_PARENT_NODE}->{$PROP_CHILD_NODES}->{$self->{$PROP_NODE_TYPE}};
	# Not sure if this will work.  I want to compare two references 
	# to see if they are pointing at the same object.  Hopefully it 
	# won't corrupt the reference or throw a warning or something.
	@{$siblings} = grep { $_ ne $self } @{$siblings};
	$self->{$PROP_PARENT_NODE} = undef;
}

######################################################################

=head2 node_attribute( KEY[, VALUE] )

This method is an accessor for the "node_attrs" hash property of this object,
and allows you to retrieve or set the one hash element that is matched by KEY.
If VALUE is defined, the element is set to that value.  The current value is
then always returned.

=cut

######################################################################

sub node_attribute {
	my ($self, $key, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->add_node_attributes( { $key => $new_value } );
	}
	return( $self->{$PROP_NODE_ATTRS}->{$key} );
}

######################################################################

=head2 get_node_attributes()

This method returns a shallow copy of the "node_type" hash property of this
object, which is returned as a hash ref.

=cut

######################################################################

sub get_node_attributes {
	return( {%{$_[0]->{$PROP_NODE_TYPE}}} );
}

######################################################################

=head2 set_node_attributes( ATTRS )

This method allows you to set the "node_attrs" hash property of this object;
all of the existing hash key/value pairs are replaced with the ones in the
ATTRS hash ref argument.  If ATTRS is empty, then the "node_attrs" will simply
be emptied.

=cut

######################################################################

sub set_node_attributes {
	my ($self, $attrs) = @_;
	$self->{$PROP_NODE_ATTRS} = {};
	$self->add_node_attributes( $attrs );
}

######################################################################

=head2 add_node_attributes( ATTRS )

This method allows you to add key/value pairs to the "node_attrs" hash property
of this object, as provided in the ATTRS hash ref argument; any like-named keys
will overwrite existing ones, but different-named ones will coexist.

=cut

######################################################################

sub add_node_attributes {
	my ($self, $attrs) = @_;
	defined( $attrs ) or return( 0 );

	my $node_type = $self->{$PROP_NODE_TYPE};
	my $type_info = $NODE_TYPES{$node_type};

	unless( ref($attrs) eq 'HASH' ) {
		my $def_attr = $type_info->{'def_attr'};
		unless( $def_attr ) {
			Carp::confess( "$CLSNM->add_node_attributes(): invalid ATTRS argument; ".
				"it is not a hash ref, but rather is '$attrs'; ".
				"also, nodes of type '$node_type' have no default ".
				"attribute to associate the given value with" );
		}
		$attrs = { $def_attr => $attrs };
	}

	my $attr_defaults = $type_info->{'attr_defaults'};
	# This is placed here so that default strs can be processed into nodes below.
	if( $attr_defaults ) {
		foreach my $attr_name (keys %{$attr_defaults}) {
			unless( defined( $self->{$PROP_NODE_ATTRS}->{$attr_name} ) ) {
				unless( defined( $attrs->{$attr_name} ) ) {
					$attrs->{$attr_name} = $attr_defaults->{$attr_name};
					# Note: this may cause problems when a user wants to 
					# explicitely set a field to null that has a default value.
					# It should be looked into further.
				}
			}
		}
	}

	my %first_attrs = $type_info->{'first_attrs'} ? %{$type_info->{'first_attrs'}} : ();
	# The idea is that attr names in the above hash are sorted before those that aren't.
	# It makes sure dependant attrs are processed after what they depend on.
	my @attr_name_list = !%first_attrs ? (sort keys %{$attrs}) : 
		(sort { (($first_attrs{$b}||0) <=> ($first_attrs{$a}||0)) or ($b cmp $a) } keys %{$attrs});

	foreach my $attr_name (@attr_name_list) {
		my $attr_info = $type_info->{'attributes'}->{$attr_name};
		unless( $attr_info ) {
			Carp::confess( "$CLSNM->add_node_attributes(): invalid ATTRS argument element; ".
				"there is no attribute named '$attr_name' in '$node_type' nodes" );
		}
		my ($attr_type, $exp_ref_type, $search_path) = 
			ref($attr_info) eq 'ARRAY' ? @{$attr_info} : $attr_info;
		my $attr_value = $attrs->{$attr_name};
		if( $attr_type eq 'enum' ) {
			$attr_value = $self->_clean_up_entity_name( $attr_value );
			unless( $CONSTANT_CODE_TYPES{$exp_ref_type}->{$attr_value} ) {
				Carp::confess( "$CLSNM->add_node_attributes(): invalid ATTRS argument element; ".
					"the attribute named '$attr_name' in '$node_type' nodes ".
					"may not have a value of '$attr_value'" );
			}
		} elsif( $attr_type eq 'node' ) {
			if( UNIVERSAL::isa($attr_value,'SQL::ObjectModel') ) {
				my $f_node_type = $attr_value->{$PROP_NODE_TYPE};
				unless( $f_node_type eq $exp_ref_type ) {
					Carp::confess( "$CLSNM->add_node_attributes(): invalid ATTRS argument element; ".
						"the attribute named '$attr_name' in '$node_type' nodes may ".
						"only reference a node of type '$exp_ref_type', but the ".
						"given node is of type '$f_node_type'" );
				}
			} else {
				# Attribute should be a node reference but isn't, so link or make one.
				my $node_to_link = undef;
				if( $attr_value and !ref($attr_value) and $search_path ) {
					unless( ref($search_path) eq 'ARRAY' ) {
						$search_path = [ $search_path ];
					}
					my $curr_node = $self;
					foreach my $path_seg (@{$search_path}) {
						if( $path_seg eq $S ) {
							my $start_type = $curr_node->{$PROP_NODE_TYPE};
							while( $curr_node->{$PROP_PARENT_NODE} and $start_type eq
									$curr_node->{$PROP_PARENT_NODE}->{$PROP_NODE_TYPE} ) {
								$curr_node = $curr_node->{$PROP_PARENT_NODE};
							}
						} elsif( $path_seg eq $P ) {
							# Want to progress search to the parent of the current node.
							if( $curr_node->{$PROP_PARENT_NODE} ) {
								# There is a parent node, so move to it.
								$curr_node = $curr_node->{$PROP_PARENT_NODE};
							} else {
								# There is no parent node; search has failed.
								$curr_node = undef;
								last;
							}
						} else {
							# Want to progress search to an attribute of the current node.
							if( $curr_node->{$PROP_NODE_ATTRS}->{$path_seg} ) {
								# The current node has that attribute, so move to it.
								$curr_node = $curr_node->{$PROP_NODE_ATTRS}->{$path_seg};
							} else {
								# There is no attribute present; search has failed.
								$curr_node = undef;
								last;
							}
						}
					}
					if( $curr_node ) {
						# Since curr_node is still defined, the search succeeded, 
						# or the search path was an empty list (means search self).
						my $link_search_attr = $NODE_TYPES{$exp_ref_type}->{'link_search_attr'};
						foreach my $scn (@{$curr_node->{$PROP_CHILD_NODES}->{$exp_ref_type}}) {
							if( $scn->{$PROP_NODE_ATTRS}->{$link_search_attr} eq $attr_value ) {
								# We found a node in the correct path that we can link.
								$node_to_link = $scn;
								last;
							}
						}
					}
				}
				if( $node_to_link ) {
					$attr_value = $node_to_link;
				} else {
					$attr_value = SQL::ObjectModel->new( { 
						$ARG_NODE_TYPE => $exp_ref_type, $ARG_ATTRS => $attr_value } );
				}
			}
		} elsif( $attr_type eq 'bool' ) {
			$attr_value = $attr_value ? 1 : 0;
		} elsif( $attr_type eq 'int' ) {
			$attr_value = int($attr_value);
		} else {} # $attr_type eq 'str'; no change to value needed
		$self->{$PROP_NODE_ATTRS}->{$attr_name} = $attr_value;
	}

	# Enforcing required attributes right now seems dubious, as one may want to add 
	# them individually later.  Otherwise, the code to do it would go here, and 
	# it would look much like the defaults loop, but for $type_info->{'req_attr'}.
}

sub _clean_up_entity_name {
	my (undef, $entity_name) = @_;
	$entity_name = lc($entity_name);
	$entity_name =~ m/([a-z0-9_]+)/;
	return( $1 );
}

######################################################################

=head2 get_child_nodes([ NODE_TYPE ])

This method returns a list of this object's child nodes, in a new array ref. 
If the optional argument NODE_TYPE is defined, then only child nodes of that
node type are returned; otherwise, all child nodes are returned.  All nodes of
the same type are always grouped together, and within those groups they
maintain their explicitely defined order, but the groupings themselves are in
an effectively random order.

=cut

######################################################################

sub get_child_nodes {
	my ($self, $node_type) = @_;
	if( defined( $node_type ) ) {
		my $c_list = $self->{$PROP_CHILD_NODES}->{$node_type};
		return( [$c_list ? @{$c_list} : ()] );
	} else {
		my $children = $self->{$PROP_CHILD_NODES};
		return( [map { @{$children->{$_}} } sort keys %{$children}] );
	}
}

######################################################################

=head2 set_child_nodes( CHILDREN )

This method allows you to replace this object's child nodes with a list of new
child nodes, which are provided as elements in the CHILDREN array ref argument.  
If CHILDREN is empty, then the existing child nodes will simply be removed from 
this object.  Any removals is recursive, going to all descendant nodes.

=cut

######################################################################

sub set_child_nodes {
	my ($self, $children) = @_;

	if( $self->{$PROP_CHILD_NODES} ) {  # not called by new()
		$self->_unlink_all_child_nodes_recursive();

	} else {  # we were called by new()
		my $allowed_c_types = $NODE_TYPES{$self->{$PROP_NODE_TYPE}}->{'children'};
		$self->{$PROP_CHILD_NODES} = { map { ( $_ => [] ) } (
			$allowed_c_types ? (keys %{$allowed_c_types}) : () 
		) };
	}

	$self->add_child_nodes( $children );
}

sub _unlink_all_child_nodes_recursive {
	my ($self) = @_;
	foreach my $node_type (sort keys %{$self->{$PROP_CHILD_NODES}}) {
		my $children_by_type = $self->{$PROP_CHILD_NODES}->{$node_type};
		foreach my $child_to_remove (@{$children_by_type}) {
			$child_to_remove->{$PROP_PARENT_NODE} = undef;
			$child_to_remove->_unlink_all_child_nodes_recursive();  # avoid mem leaks
		}
		@{$children_by_type} = ();
	}
}

######################################################################

=head2 add_child_nodes( CHILDREN )

This method allows you to add new child nodes to this object, which are
provided as elements in the CHILDREN array ref argument.  The new child nodes
are appended to the list of existing nodes; all existing nodes are preserved.

=cut

######################################################################

sub add_child_nodes {
	my ($self, $children) = @_;
	defined( $children ) or return( 0 );

	my $node_type = $self->{$PROP_NODE_TYPE};
	my $type_info = $NODE_TYPES{$node_type};

	unless( ref($children) eq 'ARRAY' ) {
		$children = [ $children ];
	}
	foreach my $child (@{$children}) {
		if( ref($child) eq 'HASH' ) {
			# Create a new child and let it do all the linking to the parent.
			$child->{$ARG_PARENT} = $self;
			$child = SQL::ObjectModel->new( $child );
		} else {
			# Do all the linking here instead.
			unless( UNIVERSAL::isa($child,'SQL::ObjectModel') ) {
				Carp::confess( "$CLSNM->add_child_nodes(): invalid CHILD argument element; ".
					"it is not a $CLSNM object, but rather is '$child'" );
			}
			my $c_node_type = $child->{$PROP_NODE_TYPE};
			unless( $type_info->{'children'}->{$c_node_type} ) {
				Carp::confess( "$CLSNM->add_child_nodes(): invalid CHILD argument element; ".
					"a node of type '$node_type' may not have ".
					"a child node of type '$c_node_type'" );
			}
			push( @{$self->{$PROP_CHILD_NODES}->{$c_node_type}}, $child );
			$child->{$PROP_PARENT_NODE} = $self;
		}
	}
}

######################################################################

=head1 METHODS FOR DEBUGGING

=head2 get_all_properties([ NO_EXTRAS ])

This method returns a deep copy of all of the properties of this object as
non-blessed Perl data structures.  These data structures are also arranged in a
tree, but they do not have any circular references.  You may be able to take
the output of this method and recreate the original objects by passing it to
SQL::ObjectModel->new(), although this may not work reliably; you should use
clone() if you want something reliable.  The main purpose, currently, of
get_all_properties() is to make it easier to debug or test this class; it makes
it easier to see at a glance whether the other class methods are doing what you
expect.  The output of this method should also be easy to serialize or
unserialize to strings of Perl code or other things, should you want to compare
your results easily by string compare (see "get_all_properties_as_string()").
By default, this method puts extra information into the data structure being
produced, with hash keys starting in a double-underscore, such as the Perl
internal reference number for the source node objects, or a serial number for
each object being output, or the perl references for nodes that are being
linked to by each object in their attributes; since this information isn't used
by new(), and it is bound to change between script invocations, making it
unreliable for static testing, you can set the boolean NO_EXTRAS to true and
these extras won't be added to the output.

=cut

######################################################################

my $global_out_node_num;

sub get_all_properties {
	$global_out_node_num = 0;
	return( $_[0]->_get_all_properties( $_[1], {} ) );
}

sub _get_all_properties {
	my ($self, $ext, $gotten_already) = @_;
	my %dump = ();

	$ext or $dump{$ARG___OUT_NODE_NUM} = ++$global_out_node_num;

	$ext or $dump{$ARG___PNID} = int($self);
	$gotten_already->{int($self)} = 1;

	$dump{$ARG_NODE_TYPE} = $self->{$PROP_NODE_TYPE};

	my %attrs_out = ();
	my %attrs_out_pnid = ();
	foreach my $attr_name (sort keys %{$self->{$PROP_NODE_ATTRS}}) {
		my $attr_value = $self->{$PROP_NODE_ATTRS}->{$attr_name};
		if( ref($attr_value) eq ref($self) ) {
			if( $attr_value->{$PROP_PARENT_NODE} ) {
				# This object has a parent, so let the parent copy it.
				my $lsa = $NODE_TYPES{$attr_value->{$PROP_NODE_TYPE}}->{'link_search_attr'};
				$attrs_out{$attr_name} = $attr_value->{$PROP_NODE_ATTRS}->{$lsa};
			} elsif( $gotten_already->{int($attr_value)} ) {
				# This object has no parent, and multiple attrs point to it;
				# we already encountered another one and output this object, so do nothing now.
			} else {
				# This object has no parent, and either we have only 1 attr point to it,  
				# or this is the first time we encountered it; copy away.
				$attrs_out{$attr_name} = $attr_value->_get_all_properties( $ext, $gotten_already );
			}
			$attrs_out_pnid{$attr_name} = int($attr_value);
		} else {
			$attrs_out{$attr_name} = $attr_value;
		}
	}
	$dump{$ARG_ATTRS} = \%attrs_out;
	$ext or $dump{$ARG___ATTRS_PNID} = \%attrs_out_pnid;

	my @children_out = ();
	foreach my $node_type (sort keys %{$self->{$PROP_CHILD_NODES}}) {
		foreach my $self_child (@{$self->{$PROP_CHILD_NODES}->{$node_type}}) {
			push( @children_out, $self_child->_get_all_properties( $ext, $gotten_already ) );
		}
	}
	$dump{$ARG_CHILDREN} = \@children_out;

	return( \%dump );
}

######################################################################

=head2 get_all_properties_as_str([ NO_EXTRAS[, NO_INDENTS] ])

This method is a wrapper for get_all_properties([ NO_EXTRAS ]) that serializes
its output into a pretty-printed string of Perl code, suitable for humans to
read.  You should be able to eval this string and produce the original
structure.  By default, contents of lists are indented under the lists they are
in (easier to read); if the optional boolean argument NO_INDENTS is true, then
all output lines will be flush with the left, saving a fair amount of memory in
what the resulting string consumes.  (That said, even the indents are tabs,
which take up much less space than multiple spaces per indent level.)

=cut

######################################################################

sub get_all_properties_as_str {
	return( $_[0]->_serialize( $_[2], $_[0]->get_all_properties( $_[1] ) ) );
}

sub _serialize {
	my ($self, $ind, $input, $pad, $is_key, $is_val) = @_;
	$pad ||= '';
	my $padc = $ind ? "" : "$pad\t";
	my %key_order = ( $ARG___OUT_NODE_NUM => 6, $ARG___PNID => 5, $ARG_NODE_TYPE => 4,
		$ARG_ATTRS => 3, $ARG___ATTRS_PNID => 2, $ARG_CHILDREN => 1, );
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( ($is_val ? '' : $pad).'{ '.(%{$input}?"\n":''), ( map { 
				( $self->_serialize( $ind,$_,$padc,1 ), 
				$self->_serialize( $ind,$input->{$_},$padc,undef,1 ) ) 
			} sort { ($key_order{$b}||0) <=> ($key_order{$a}||0) } 
				keys %{$input} ), (%{$input}?$pad:'').'}, '."\n" ) 
		: ref($input) eq 'ARRAY' ? 
			( ($is_val ? '' : $pad).'[ '.(@{$input}?"\n":''), ( map { 
				( $self->_serialize( $ind,$_,$padc ) ) 
			} @{$input} ), (@{$input}?$pad:'').'], '."\n" ) 
		: defined($input) ?
			($is_val ? '' : $pad)."'$input'".($is_key ? ' => ' : ', '."\n")
		: ($is_val ? '' : $pad)."undef".($is_key ? ' => ' : ', '."\n")
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
SQL::ObjectModel node that you were working on and quite possibly several other
nodes related to it are now in an inconsistant state.  If you continue to use
those nodes, or others that are linked to them in any way, the program may
crash without the friendly exceptions, as data which this module expects to be
consistant (as it would be when there are no exceptions) would not be.  I
expect to deal with this problem at some time in the future, such as trying to 
defer the exception throw until I can clean up the state first.

Automatic node linking (to tree branches "beside" the current one) is not
currently implemented in certain situations.  The problem is due to search
paths (an internal constant property) only knowing a single path to search
each, when ideally they might try multiple paths.  Until this is resolved, you
can still link manually to unsearched nodes by providing references to the
nodes to link to in your ATTRS inputs (automatic linking is only attempted when
an attribute is supposed to be a node ref but given input is a scalar).

=head1 SEE ALSO

perl(1), SQL::ObjectModel::DataDictionary, SQL::ObjectModel::API_C, Rosetta,
Rosetta::Framework, DBI, SQL::Statement, SQL::Translator, SQL::YASP,
SQL::Generator, SQL::Schema, SQL::Abstract, SQL::Snippet, SQL::Catalog,
DB::Ent, DBIx::Abstract, DBIx::AnyDBD, DBIx::DBSchema, DBIx::Namespace,
DBIx::SearchBuilder, TripleStore.

=cut
