=head1 NAME

SQL::SyntaxModel - An abstract syntax tree for all types of SQL

=cut

######################################################################

package SQL::SyntaxModel;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

#use Locale::KeyedText;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	SOON BUT NOT YET: Locale::KeyedText (for error messages)

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

=cut

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::_::Shared; # has no properties, subclassed by main and Container and Node

######################################################################

# Names of properties for objects of the SQL::SyntaxModel::_::Node class are declared here:
	# The C version will have the following comprise fields in a Node struct;
	# all fields will be integers or memory references or enums; none will be strings.
my $NPROP_NODE_TYPE   = 'node_type'; # str (enum) - what type of Node this is, can not change once set
	# The Node type is the only property which absolutely can not change, and is set when object created.
	# (All other Node properties start out undefined or false, and are set separately from object creation.)
	# C version of this will be an enumerated value.
my $NPROP_NODE_ID     = 'node_id'; # uint - unique identifier attribute for this node within container+type
	# Node id must be set when/before Node is put in a container; may lack one when not in container.
	# C version of this will be an unsigned integer.
my $NPROP_AT_LITERALS = 'at_literals'; # hash (enum,lit) - attrs of Node which are non-enum, non-id literal values
	# C version of this will be an array (pointer) of Literal structs.
	# We already know what all the attributes can be for each node type, so the size of the array 
	# will be fixed and known in advance, allowing it to be all allocated with one malloc() call.
	# Each attribute struct would be at a specific array index; 
	# C macros/constants will give names to the indices, like with the hash keys for the above.
my $NPROP_AT_ENUMS    = 'at_enums'; # hash (enum,enum) - attrs of Node which are enumerated values
	# C version of this will be an array (pointer) of enumerated values.
my $NPROP_AT_NODES    = 'at_nodes'; # hash (enum,Node) - attrs of Node which point to other Nodes (or ids rep other Nodes)
	# C version of this will be either multiple arrays or a single array of structs, to handle pointer vs uint
	# Hash elements can only be actual references when Node is in a Container, and pointed to must be in same
	# When converting to XML, if P_NODE_ATNM is set, the AT_NODE it refers to won't become an XML attr (redundant)
my $NPROP_P_NODE_ATNM = 'p_node_atnm'; # str (enum) - name of AT_NODES elem having our primary parent Node, if any
	# When this property is valued, there is no implication that the corres AT_NODES is also valued
	# C version of this will be an enumerated value.
	# Since a Node of one type may have a parent Node of multiple possible types, 
	# this tells us not only which type but which instance it is.
	# This property will be undefined if either there is no parent or the parent is a pseudo-node.
my $NPROP_CONTAINER   = 'container'; # ref to Container this Node lives in
	# C version of this would be a pointer to a Container struct
my $NPROP_LINKS_RECIP = 'links_recip'; # boolean - false by def, true when our actual refs in AT_NODES are reciprocated
	# C version of this will be an integer used like a boolean.
my $NPROP_CHILD_NODES = 'child_nodes'; # array - list of refs to other Nodes having actual refs to this one
	# We use this to reciprocate actual refs from the AT_NODES property of other Nodes to us.
	# When converting to XML, we only render once, beneath the Node which we refer to in our P_NODE_ATNM.
	# C version will be a double-linked list with each element representing a Node struct.
	# It is important to ensure that if a Node links to us multiple times (via multiple AT_NODES) 
	# then we include the other Node in our child list just as many times; eg: 2 here means 2 back; 
	# however, when rendering to XML, we only render a Node once, and not as many times as linked; 
	# it is also possible that we may never be put in this situation from real-world usage.

# Names of properties for objects of the SQL::SyntaxModel::_::Container class are declared here:
my $CPROP_ALL_NODES = 'all_nodes'; # hash of hashes of Node refs; find any Node by node_type:node_id quickly
my $CPROP_PSEUDONODES = 'pseudonodes'; # hash of arrays of Node refs
	# This property is for remembering the insert order of Nodes having hardwired pseudonode parents
#my $CPROP_CURR_NODE = 'curr_node'; # ref to a Node; used when "streaming" to or from XML
# To do: have attribute to indicate an edit in progress 
	# or that there was a failure resulting in inconsistant data;
	# this may be set by a method which partly implements a data change 
	# which is not backed out of, before that function throws an exception;
	# this property may best just be inside the thrown Locale::KeyedText object;
	# OTOH, if users have coarse-grained locks on Containers for threads, we could have a property,
	# since a call to an editing method would check and clear that before the thread releases lock

# Names of properties for objects of the SQL::SyntaxModel class are declared here:
my $MPROP_CONTAINER = 'container'; # holds all the actual Container properties for this class
	# We use two classes internally where user sees one so that no internal refs point to the 
	# parentmost object, and hence DESTROY() will be called properly when all external refs go away.

# These are programmatically recognized enumerations of values that 
# particular Node attributes are allowed to have.  They are given names 
# here so that multiple Node types can make use of the same value lists.  
# Currently only the codes are shown, but attributes may be attached later.
my %ENUMERATED_TYPES = (
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

# Names of hash keys in %NODE_TYPES elements:
my $TPI_AT_LITERALS  = 'at_literals'; # Keys are attr names a Node can have which have literal values
	# Values are enums and say what literal data type the attribute has, like int or bool or str
my $TPI_AT_ENUMS     = 'at_enums'; # Keys are attr names a Node can have which are enumerated values
	# Values are enums and match a %ENUMERATED_TYPES key
my $TPI_AT_NODES     = 'at_nodes'; # Keys are attr names a Node can have which are Node Ref/Id values
	# Values are enums and match a %NODE_TYPES key
my $TPI_P_NODE_ATNMS = 'p_node_atnms'; # Keys match keys of AT_NODES (P_NODE_ATNM is a list subset)
	# Values are meaningless; they simply are the truth value of 1
my $TPI_P_PSEUDONODE = 'p_pseudonode'; # If set, Nodes of this type have a hard-coded pseudo-parent
my $TPI_MA_LITERALS  = 'ma_literals'; # Mandatory literals attributes; keys=keys, values = 1
my $TPI_MA_ENUMS     = 'ma_enums'; # Mandatory enums attributes; keys=keys, values = 1
my $TPI_MA_NODES     = 'ma_nodes'; # Mandatory nodes attributes; keys=keys, values = 1

# Names of special "pseudo-nodes" that are used in an XML version of this structure.
my $SQLSM_ROOT_NODE_TYPE = 'root';
my $SQLSM_L2_TYPE_LIST = 'type_list';
my $SQLSM_L2_DTBS_LIST = 'database_list';
my $SQLSM_L2_APPL_LIST = 'application_list';
my @L2_PSEUDONODE_LIST = ($SQLSM_L2_TYPE_LIST, $SQLSM_L2_DTBS_LIST, $SQLSM_L2_APPL_LIST);

# These are the allowed Node types, with their allowed attributes and their 
# allowed child Node types.  They are used for method input checking and 
# other related tasks.
my %NODE_TYPES = (
	'data_type' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'size_in_bytes' => 'uint',
			'size_in_chars' => 'uint',
			'size_in_digits' => 'uint',
			'store_fixed' => 'bool',
			'str_trim_white' => 'bool',
			'str_pad_char' => 'str',
			'str_trim_pad' => 'bool',
			'num_unsigned' => 'bool',
			'num_precision' => 'uint',
		},
		$TPI_AT_ENUMS => {
			'basic_type' => 'cct_basic_data_type',
			'str_encoding' => 'cct_str_enc',
			'str_latin_case' => 'cct_str_latin_case',
			'datetime_calendar' => 'cct_datetime_calendar',
		},
		$TPI_P_PSEUDONODE => $SQLSM_L2_TYPE_LIST,
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( basic_type )},
	},
	'database' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
		},
		$TPI_P_PSEUDONODE => $SQLSM_L2_DTBS_LIST,
	},
	'namespace' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
		},
		$TPI_AT_NODES => {
			'database' => 'database',
		},
		$TPI_P_NODE_ATNMS => [qw( database )],
		$TPI_MA_NODES => {map { ($_ => 1) } qw( database )},
	},
	'table' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
			'public_syn' => 'str',
			'storage_file' => 'str',
		},
		$TPI_AT_NODES => {
			'namespace' => 'namespace',
		},
		$TPI_P_NODE_ATNMS => [qw( namespace )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name order )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( namespace )},
	},
	'table_col' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
			'required_val' => 'bool',
			'default_val' => 'str',
			'auto_inc' => 'bool',
		},
		$TPI_AT_NODES => {
			'table' => 'table',
			'data_type' => 'data_type',
		},
		$TPI_P_NODE_ATNMS => [qw( table )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name order required_val )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( table data_type )},
	},
	'table_ind' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
		},
		$TPI_AT_ENUMS => {
			'ind_type' => 'cct_index_type',
		},
		$TPI_AT_NODES => {
			'table' => 'table',
			'f_table' => 'table',
		},
		$TPI_P_NODE_ATNMS => [qw( table )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name order )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( ind_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( table )},
	},
	'table_ind_col' => {
		$TPI_AT_LITERALS => {
			'order' => 'uint',
		},
		$TPI_AT_NODES => {
			'table_ind' => 'table_ind',
			'table_col' => 'table_col',
			'f_table_col' => 'table_col',
		},
		$TPI_P_NODE_ATNMS => [qw( table_ind )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( order )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( table_ind table_col )},
	},
	'trigger' => {
		$TPI_AT_LITERALS => {
			'run_before' => 'bool',
			'run_after' => 'bool',
			'on_insert' => 'bool',
			'on_update' => 'bool',
			'on_delete' => 'bool',
			'for_each_row' => 'bool',
		},
		$TPI_AT_NODES => {
			'table' => 'table',
			'block' => 'block',
		},
		$TPI_P_NODE_ATNMS => [qw( table )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( run_before run_after on_insert on_update on_delete for_each_row )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( table block )},
	},
	'view' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
			'public_syn' => 'str',
			'may_write' => 'bool',
		},
		$TPI_AT_ENUMS => {
			'view_type' => 'cct_view_type',
		},
		$TPI_AT_NODES => {
			'p_view' => 'view',
			'namespace' => 'namespace',
			'match_table' => 'table',
		},
		$TPI_P_NODE_ATNMS => [qw( namespace p_view )],
		'parent_selfnode_attr' => 'p_view',
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( may_write )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( view_type )},
	},
	'view_col' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
			'sort_priority' => 'uint',
		},
		$TPI_AT_NODES => {
			'view' => 'view',
			'data_type' => 'data_type',
		},
		$TPI_P_NODE_ATNMS => [qw( view )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name order )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( view data_type )},
	},
	'view_rowset' => {
		$TPI_AT_LITERALS => {
			'p_rowset_order' => 'uint',
		},
		$TPI_AT_ENUMS => {
			'c_merge_type' => 'cct_rs_merge_type',
		},
		$TPI_AT_NODES => {
			'view' => 'view',
			'p_rowset' => 'view_rowset',
		},
		$TPI_P_NODE_ATNMS => [qw( view p_rowset )],
		'parent_selfnode_attr' => 'p_rowset',
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( p_rowset_order )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( view )},
	},
	'view_src' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
		},
		$TPI_AT_NODES => {
			'rowset' => 'view_rowset',
			'match_table' => 'table',
			'match_view' => 'view',
		},
		$TPI_P_NODE_ATNMS => [qw( rowset )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name order )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( rowset )},
	},
	'view_src_col' => {
		$TPI_AT_NODES => {
			'src' => 'view_src',
			'match_table_col' => 'table_col',
			'match_view_col' => 'view_col',
		},
		$TPI_P_NODE_ATNMS => [qw( src )],
		$TPI_MA_NODES => {map { ($_ => 1) } qw( src )},
	},
	'view_join' => {
		$TPI_AT_ENUMS => {
			'join_type' => 'cct_rs_join_type',
		},
		$TPI_AT_NODES => {
			'rowset' => 'view_rowset',
			'lhs_src' => 'view_src',
			'rhs_src' => 'view_src',
		},
		$TPI_P_NODE_ATNMS => [qw( rowset )],
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( join_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( rowset lhs_src rhs_src )},
	},
	'view_join_col' => {
		$TPI_AT_NODES => {
			'join' => 'view_join',
			'lhs_src_col' => 'view_src_col',
			'rhs_src_col' => 'view_src_col',
		},
		$TPI_P_NODE_ATNMS => [qw( join )],
		$TPI_MA_NODES => {map { ($_ => 1) } qw( join lhs_src_col rhs_src_col )},
	},
	'view_hierarchy' => {
		$TPI_AT_LITERALS => {
			'start_lit_val' => 'str',
			'start_command_var' => 'str', #temp haxie; should say: ['node','command_var'],
		},
		$TPI_AT_NODES => {
			'rowset' => 'view_rowset',
			'start_src_col' => 'view_src_col',
			'start_block_var' => 'block_var',
			'conn_src_col' => 'view_src_col',
			'p_conn_src_col' => 'view_src_col',
		},
		$TPI_P_NODE_ATNMS => [qw( rowset )],
		$TPI_MA_NODES => {map { ($_ => 1) } qw( rowset start_src_col conn_src_col p_conn_src_col )},
	},
	'view_col_def' => {
		$TPI_AT_LITERALS => {
			'p_expr_order' => 'uint',
			'lit_val' => 'str',
			'command_var' => 'str', #temp haxie; should say: ['node','command_var'],
		},
		$TPI_AT_ENUMS => {
			'expr_type' => 'cct_basic_expr_type',
			'sfunc' => 'cct_standard_func',
		},
		$TPI_AT_NODES => {
			'view_col' => 'view_col',
			'rowset' => 'view_rowset',
			'p_expr' => 'view_col_def',
			'block_var' => 'block_var',
			'src_col' => 'view_src_col',
			'f_view' => 'view',
			'ufunc' => 'block',
		},
		$TPI_P_NODE_ATNMS => [qw( rowset p_expr )],
		'parent_selfnode_attr' => 'p_expr',
		'inherited_selfnode_attrs' => [qw( view_col rowset )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( p_expr_order )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( expr_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( view_col rowset )},
	},
	'view_part_def' => {
		$TPI_AT_LITERALS => {
			'p_expr_order' => 'uint',
			'lit_val' => 'str',
			'command_var' => 'str', #temp haxie; should say: ['node','command_var'],
		},
		$TPI_AT_ENUMS => {
			'view_part' => 'cct_view_part',
			'expr_type' => 'cct_basic_expr_type',
			'sfunc' => 'cct_standard_func',
		},
		$TPI_AT_NODES => {
			'rowset' => 'view_rowset',
			'p_expr' => 'view_part_def',
			'block_var' => 'block_var',
			'src_col' => 'view_src_col',
			'f_view' => 'view',
			'ufunc' => 'block',
		},
		$TPI_P_NODE_ATNMS => [qw( rowset p_expr )],
		'parent_selfnode_attr' => 'p_expr',
		'inherited_selfnode_attrs' => [qw( rowset view_part )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( p_expr_order )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( view_part expr_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( rowset )},
	},
	'sequence' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'public_syn' => 'str',
		},
		$TPI_AT_NODES => {
			'namespace' => 'namespace',
		},
		$TPI_P_NODE_ATNMS => [qw( namespace )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name )},
	},
	'block' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
			'public_syn' => 'str',
		},
		$TPI_AT_ENUMS => {
			'block_type' => 'cct_block_type',
		},
		$TPI_AT_NODES => {
			'p_block' => 'block',
			'namespace' => 'namespace',
		},
		$TPI_P_NODE_ATNMS => [qw( namespace p_block )],
		'parent_selfnode_attr' => 'p_block',
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( block_type )},
	},
	'block_var' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
			'order' => 'uint',
			'is_argument' => 'bool',
			'init_lit_val' => 'str',
		},
		$TPI_AT_ENUMS => {
			'var_type' => 'cct_basic_var_type',
		},
		$TPI_AT_NODES => {
			'block' => 'block',
			'data_type' => 'data_type',
			'c_view' => 'view',
		},
		$TPI_P_NODE_ATNMS => [qw( block )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name order is_argument )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( var_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( block )},
	},
	'block_stmt' => {
		$TPI_AT_LITERALS => {
			'order' => 'uint',
		},
		$TPI_AT_ENUMS => {
			'stmt_type' => 'cct_basic_stmt_type',
			'sproc' => 'cct_standard_proc',
		},
		$TPI_AT_NODES => {
			'block' => 'block',
			'dest_var' => 'block_var',
			'uproc' => 'block',
			'c_block' => 'block',
		},
		$TPI_P_NODE_ATNMS => [qw( block )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( order )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( stmt_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( block )},
	},
	'block_expr' => {
		$TPI_AT_LITERALS => {
			'p_expr_order' => 'uint',
			'lit_val' => 'str',
		},
		$TPI_AT_ENUMS => {
			'expr_type' => 'cct_basic_expr_type',
			'sfunc' => 'cct_standard_func',
		},
		$TPI_AT_NODES => {
			'stmt' => 'block_stmt',
			'p_expr' => 'block_expr',
			'src_var' => 'block_var',
			'ufunc' => 'block',
		},
		$TPI_P_NODE_ATNMS => [qw( stmt p_expr )],
		'parent_selfnode_attr' => 'p_expr',
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( p_expr_order )},
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( expr_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( stmt )},
	},
	'user' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
		},
		$TPI_AT_NODES => {
			'database' => 'database',
		},
		$TPI_P_NODE_ATNMS => [qw( database )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( database )},
	},
	'privilege' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
		},
		$TPI_AT_NODES => {
			'user' => 'user',
		},
		$TPI_P_NODE_ATNMS => [qw( user )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( user )},
	},
	'application' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
		},
		$TPI_P_PSEUDONODE => $SQLSM_L2_APPL_LIST,
	},
	'command' => {
		$TPI_AT_ENUMS => {
			'command_type' => 'cct_command_type',
		},
		$TPI_AT_NODES => {
			'application' => 'application',
			'p_command' => 'command',
		},
		$TPI_P_NODE_ATNMS => [qw( application p_command )],
		'parent_selfnode_attr' => 'p_command',
		$TPI_MA_ENUMS => {map { ($_ => 1) } qw( command_type )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( application )},
	},
	'command_var' => {
		$TPI_AT_LITERALS => {
			'name' => 'str',
		},
		$TPI_AT_NODES => {
			'command' => 'command',
		},
		$TPI_P_NODE_ATNMS => [qw( command )],
		$TPI_MA_LITERALS => {map { ($_ => 1) } qw( name )},
		$TPI_MA_NODES => {map { ($_ => 1) } qw( command )},
	},
);

# This is an extension to let you use one set of functions for all Node 
# attribute major types, rather than separate literal/enumerated/node.
# This feature should be considered deprecated until further notice.
my $NAMT_ID      = 'ID'; # node id attribute
my $NAMT_LITERAL = 'LITERAL'; # literal attribute
my $NAMT_ENUM    = 'ENUM'; # enumerated attribute
my $NAMT_NODE    = 'NODE'; # node attribute
my $ATTR_ID      = 'id'; # attribute name to use for the node id

# Named arguments corresponding to properties for objects of this class are declared here; 
# they are currently only used with the create_[/child_]node_tree[/s]() methods, plus the  
# get_all_properties[/*]() methods, and probably should be considered deprecated:
my $ARG_NODE_TYPE = 'NODE_TYPE'; # str - what type of Node we are
my $ARG_ATTRS     = 'ATTRS'; # hash - our attributes, including refs/ids of parents we will have
my $ARG_CHILDREN  = 'CHILDREN'; # list of refs to new Nodes we will become primary parent of

######################################################################
# These are 'protected' methods; only sub-classes should invoke them.

sub _get_static_const_container_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'SQL::SyntaxModel::_::Container' );
}

sub _get_static_const_node_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'SQL::SyntaxModel::_::Node' );
}

######################################################################

sub valid_enumerated_types {
	my ($self, $type) = @_;
	$type and return( exists( $ENUMERATED_TYPES{$type} ) );
	return( {map { ($_ => 1) } keys %ENUMERATED_TYPES} );
}

sub valid_enumerated_type_values {
	my ($self, $type, $value) = @_;
	($type and exists( $ENUMERATED_TYPES{$type} )) or return( undef );
	$value and return( exists( $ENUMERATED_TYPES{$type}->{$value} ) );
	return( {%{$ENUMERATED_TYPES{$type}}} );
}

sub valid_node_types {
	my ($self, $type) = @_;
	$type and return( exists( $NODE_TYPES{$type} ) );
	return( {map { ($_ => 1) } keys %NODE_TYPES} );
}

sub valid_node_type_literal_attributes {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_AT_LITERALS} ) or return( undef );
	$attr and return( $NODE_TYPES{$type}->{$TPI_AT_LITERALS}->{$attr} );
	return( {%{$NODE_TYPES{$type}->{$TPI_AT_LITERALS}}} );
}

sub valid_node_type_enumerated_attributes {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_AT_ENUMS} ) or return( undef );
	$attr and return( $NODE_TYPES{$type}->{$TPI_AT_ENUMS}->{$attr} );
	return( {%{$NODE_TYPES{$type}->{$TPI_AT_ENUMS}}} );
}

sub valid_node_type_node_attributes {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_AT_NODES} ) or return( undef );
	$attr and return( $NODE_TYPES{$type}->{$TPI_AT_NODES}->{$attr} );
	return( {%{$NODE_TYPES{$type}->{$TPI_AT_NODES}}} );
}

sub valid_node_type_parent_attribute_names {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_P_NODE_ATNMS} ) or return( undef );
	$attr and return( grep { $_ eq $attr } @{$NODE_TYPES{$type}->{$TPI_P_NODE_ATNMS}} );
	return( [@{$NODE_TYPES{$type}->{$TPI_P_NODE_ATNMS}}] );
}

sub node_types_with_pseudonode_parents {
	my ($self, $type) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	$type and return( $NODE_TYPES{$type}->{$TPI_P_PSEUDONODE} );
	return( {map { ($_ => $NODE_TYPES{$type}->{$TPI_P_PSEUDONODE}) } 
		grep { $NODE_TYPES{$type}->{$TPI_P_PSEUDONODE} } keys %NODE_TYPES} );
}

sub mandatory_node_type_literal_attribute_names {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_MA_LITERALS} ) or return( undef );
	$attr and return( $NODE_TYPES{$type}->{$TPI_MA_LITERALS}->{$attr} );
	return( {%{$NODE_TYPES{$type}->{$TPI_MA_LITERALS}}} );
}

sub mandatory_node_type_enumerated_attribute_names {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_MA_ENUMS} ) or return( undef );
	$attr and return( $NODE_TYPES{$type}->{$TPI_MA_ENUMS}->{$attr} );
	return( {%{$NODE_TYPES{$type}->{$TPI_MA_ENUMS}}} );
}

sub mandatory_node_type_node_attribute_names {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	exists( $NODE_TYPES{$type}->{$TPI_MA_NODES} ) or return( undef );
	$attr and return( $NODE_TYPES{$type}->{$TPI_MA_NODES}->{$attr} );
	return( {%{$NODE_TYPES{$type}->{$TPI_MA_NODES}}} );
}

sub major_type_of_node_type_attribute {
	my ($self, $type, $attr) = @_;
	($type and exists( $NODE_TYPES{$type} )) or return( undef );
	defined( $attr ) or return( undef );
	$attr eq $ATTR_ID and return( $NAMT_ID );
	if( $NODE_TYPES{$type}->{$TPI_AT_LITERALS} and 
			$NODE_TYPES{$type}->{$TPI_AT_LITERALS}->{$attr} ) {
		return( $NAMT_LITERAL );
	}
	if( $NODE_TYPES{$type}->{$TPI_AT_ENUMS} and 
			$NODE_TYPES{$type}->{$TPI_AT_ENUMS}->{$attr} ) {
		return( $NAMT_ENUM );
	}
	if( $NODE_TYPES{$type}->{$TPI_AT_NODES} and 
			$NODE_TYPES{$type}->{$TPI_AT_NODES}->{$attr} ) {
		return( $NAMT_NODE );
	}
	return( undef );
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

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
# This is a 'protected' method; only sub-classes should invoke it.

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
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	# Throws an exception consisting of an object.  A Container property is not 
	# used to store object so things work properly in multi-threaded environment; 
	# an exception is only supposed to affect the thread that calls it.
#	die Locale::KeyedText->new_message( $error_code, $args );
	die "$error_code: @{[$args?%{$args}:()]}\n";
}

######################################################################

sub create_empty_node {
	my ($self, $node_type) = @_;
	defined( $node_type ) or $self->_throw_error_message( 'SSM_S_CR_EMP_NODE_NO_ARGS' );

	my $type_info = $NODE_TYPES{$node_type};
	unless( $type_info ) {
		$self->_throw_error_message( 'SSM_S_CR_EMP_NODE_BAD_TYPE', { 'TYPE' => $node_type } );
		# create_empty_node(): invalid NODE_TYPE argument; there is no Node Type named '$TYPE'
	}

	my $node = bless( {}, $self->_get_static_const_node_class_name() );

	$node->{$NPROP_NODE_TYPE} = $node_type;
	$node->{$NPROP_NODE_ID} = undef;
	$node->{$NPROP_AT_LITERALS} = {};
	$node->{$NPROP_AT_ENUMS} = {};
	$node->{$NPROP_AT_NODES} = {};
	$node->{$NPROP_P_NODE_ATNM} = undef;
	$node->{$NPROP_CONTAINER} = undef;
	$node->{$NPROP_LINKS_RECIP} = 0;
	$node->{$NPROP_CHILD_NODES} = [];

	return( $node );
}

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::_::Node;
use base qw( SQL::SyntaxModel::_::Shared );

######################################################################

sub delete_node {
	my ($node) = @_;

	if( $node->{$NPROP_CONTAINER} ) {
		$node->_throw_error_message( 'SSM_N_DEL_NODE_IN_CONT' );
		# delete_node(): this Node can not be deleted because it is 
		# still in a Container; you must take it from there first
	}

	# Ultimately the pure-Perl version of this method is a no-op because once 
	# a Node is not in a Container, there are no references to it by any 
	# SQL::ObjectModel/::* object; it will vanish when external refs go away.
	# This function is a placeholder for the C version, which will require 
	# explicit memory deallocation.
}

######################################################################

sub get_node_type {
	return( $_[0]->{$NPROP_NODE_TYPE} );
}

######################################################################

sub get_node_id {
	return( $_[0]->{$NPROP_NODE_ID} );
}

sub clear_node_id {
	my ($node) = @_;
	if( $node->{$NPROP_CONTAINER} ) {
		$node->_throw_error_message( 'SSM_N_CLEAR_NODE_ID_IN_CONT', 
			{ 'ID' => $node->{$NPROP_NODE_ID}, 'TYPE' => $node->{$NPROP_NODE_TYPE} } );
		# clear_node_id(): you can not clear the Node Id (value '$ID') of this 
		# '$TYPE' Node because the Node is in a Container
	}
	$node->{$NPROP_NODE_ID} = undef;
}

sub set_node_id {
	my ($node, $new_id) = @_;
	defined( $new_id ) or $node->_throw_error_message( 'SSM_N_SET_NODE_ID_NO_ARGS' );

	if( $new_id =~ /\D/ or $new_id < 1 or int($new_id) ne $new_id ) {
		# The regexp above should suppress warnings about non-numerical arguments to '<'
		$node->_throw_error_message( 'SSM_N_SET_NODE_ID_BAD_ARG', { 'ARG' => $new_id } );
		# set_node_id(): invalid NEW_ID argument; a Node Id may only be a positive integer; 
		# you tried to set it to '$ARG'
	}

	if( !$node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_NODE_ID} = $new_id;
		return( 1 );
	}

	# We would never get here if $node didn't also have a NODE_ID
	my $old_id = $node->{$NPROP_NODE_ID};

	if( $new_id == $old_id ) {
		return( 1 ); # no-op; new id same as old
	}
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $rh_cnl_ft = $node->{$NPROP_CONTAINER}->{$CPROP_ALL_NODES}->{$node_type};

	if( $rh_cnl_ft->{$new_id} ) {
		$node->_throw_error_message( 'SSM_N_SET_NODE_ID_DUPL_ID', 
			{ 'ID' => $new_id, 'TYPE' => $node_type } );
		# set_node_id(): invalid NEW_ID argument; the Node Id value of '$ID' you tried to set 
		# is already in use by another '$TYPE' Node in the same Container; it must be unique
	}	# The following seq should leave state consistant or recoverable if the thread dies
	$rh_cnl_ft->{$new_id} = $node; # temp reserve new+old
	$node->{$NPROP_NODE_ID} = $new_id; # change self from old to new
	delete( $rh_cnl_ft->{$old_id} ); # now only new reserved
}

######################################################################

sub expected_literal_attribute_type {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SSM_N_EXP_LIT_AT_NO_ARGS' );
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $exp_lit_type = $NODE_TYPES{$node_type}->{$TPI_AT_LITERALS} && 
		$NODE_TYPES{$node_type}->{$TPI_AT_LITERALS}->{$attr_name};
	unless( $exp_lit_type ) {
		$node->_throw_error_message( 'SSM_N_EXP_LIT_AT_INVAL_NM', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
		# expected_literal_attribute_type(): invalid ATTR_NAME argument; 
		# there is no literal attribute named '$NAME' in '$HOSTTYPE' Nodes
	}
	return( $exp_lit_type );
}

sub get_literal_attribute {
	my ($node, $attr_name) = @_;
	$node->expected_literal_attribute_type( $attr_name ); # dies if bad arg
	return( $node->{$NPROP_AT_LITERALS}->{$attr_name} );
}

sub get_literal_attributes {
	return( {%{$_[0]->{$NPROP_AT_LITERALS}}} );
}

sub clear_literal_attribute {
	my ($node, $attr_name) = @_;
	$node->expected_literal_attribute_type( $attr_name ); # dies if bad arg
	delete( $node->{$NPROP_AT_LITERALS}->{$attr_name} );
}

sub clear_literal_attributes {
	$_[0]->{$NPROP_AT_LITERALS} = {};
}

sub set_literal_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	my $exp_lit_type = $node->expected_literal_attribute_type( $attr_name ); # dies if bad arg
	defined( $attr_value ) or $node->_throw_error_message( 'SSM_N_SET_LIT_AT_NO_ARG_VAL' );

	my $node_type = $node->{$NPROP_NODE_TYPE};

	if( $exp_lit_type eq 'bool' ) {
		if( $attr_value ne '0' and $attr_value ne '1' ) {
			$node->_throw_error_message( 'SSM_N_SET_LIT_AT_INVAL_V_BOOL', 
				{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type, 'VAL' => $attr_value } );
			# set_literal_attribute(): invalid ATTR_VALUE argument; 
			# the literal attribute named '$NAME' in '$HOSTTYPE' Nodes may only be a 
			# boolean value, as expressed by '0' or '1'; you tried to set it to '$VAL'
		}

	} elsif( $exp_lit_type eq 'uint' ) {
		if( $attr_value =~ /\D/ or $attr_value < 0 or int($attr_value) ne $attr_value ) {
			# The regexp above should suppress warnings about non-numerical arguments to '<'
			$node->_throw_error_message( 'SSM_N_SET_LIT_AT_INVAL_V_INT', 
				{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type, 'VAL' => $attr_value } );
			# set_literal_attribute(): invalid ATTR_VALUE argument; 
			# the literal attribute named '$NAME' in '$HOSTTYPE' Nodes may only be a 
			# non-negative integer; you tried to set it to '$VAL'
		}

	} else {} # $exp_lit_type eq 'str'; no change to value needed

	$node->{$NPROP_AT_LITERALS}->{$attr_name} = $attr_value;
}

sub set_literal_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SSM_N_SET_LIT_AT_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SSM_N_SET_LIT_AT_BAD_ARGS', { 'ARG' => $attrs } );
		# set_literal_attributes(): invalid ATTRS argument; 
		# it is not a hash ref, but rather is '$ARG'
	}
	foreach my $attr_name (keys %{$attrs}) {
		$node->set_literal_attribute( $attr_name, $attrs->{$attr_name} );
	}
}

sub test_mandatory_literal_attributes {
	my ($node) = @_;
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $mand_attrs = $NODE_TYPES{$node_type}->{$TPI_MA_LITERALS} or return( 1 ); # no-op if no mand
	foreach my $attr_name (keys %{$mand_attrs}) {
		unless( defined( $node->{$NPROP_AT_LITERALS}->{$attr_name} ) ) {
			$node->_throw_error_message( 'SSM_N_TEMA_LIT_AT_NO_VAL_SET', 
				{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
			# test_mandatory_literal_attributes(): this '$HOSTTYPE' Node has failed a test; 
			# the literal attribute named '$attr_name' must be given a value
		}
	}
}

######################################################################

sub expected_enumerated_attribute_type {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SSM_N_EXP_ENUM_AT_NO_ARGS' );
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $exp_enum_type = $NODE_TYPES{$node_type}->{$TPI_AT_ENUMS} && 
		$NODE_TYPES{$node_type}->{$TPI_AT_ENUMS}->{$attr_name};
	unless( $exp_enum_type ) {
		$node->_throw_error_message( 'SSM_N_EXP_ENUM_AT_INVAL_NM', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
		# expected_enumerated_attribute_type(): invalid ATTR_NAME argument; 
		# there is no enumerated attribute named '$NAME' in '$HOSTTYPE' Nodes
	}
	return( $exp_enum_type );
}

sub get_enumerated_attribute {
	my ($node, $attr_name) = @_;
	$node->expected_enumerated_attribute_type( $attr_name ); # dies if bad arg
	return( $node->{$NPROP_AT_ENUMS}->{$attr_name} );
}

sub get_enumerated_attributes {
	return( {%{$_[0]->{$NPROP_AT_ENUMS}}} );
}

sub clear_enumerated_attribute {
	my ($node, $attr_name) = @_;
	$node->expected_enumerated_attribute_type( $attr_name ); # dies if bad arg
	delete( $node->{$NPROP_AT_ENUMS}->{$attr_name} );
}

sub clear_enumerated_attributes {
	$_[0]->{$NPROP_AT_ENUMS} = {};
}

sub set_enumerated_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	my $exp_enum_type = $node->expected_enumerated_attribute_type( $attr_name ); # dies if bad arg
	defined( $attr_value ) or $node->_throw_error_message( 'SSM_N_SET_ENUM_AT_NO_ARG_VAL' );

	unless( $ENUMERATED_TYPES{$exp_enum_type}->{$attr_value} ) {
		$node->_throw_error_message( 'SSM_N_SET_ENUM_AT_INVAL_V', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node->{$NPROP_NODE_TYPE}, 
			'ENUMTYPE' => $exp_enum_type, 'VAL' => $attr_value } );
		# set_enumerated_attribute(): invalid ATTR_VALUE argument; 
		# the enumerated attribute named '$NAME' in '$HOSTTYPE' Nodes may only be a 
		# '$ENUMTYPE' value; you tried to set it to '$VAL'
	}

	$node->{$NPROP_AT_ENUMS}->{$attr_name} = $attr_value;
}

sub set_enumerated_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SSM_N_SET_ENUM_AT_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SSM_N_SET_ENUM_AT_BAD_ARGS', { 'ARG' => $attrs } );
		# set_enumerated_attributes(): invalid ATTRS argument; 
		# it is not a hash ref, but rather is '$ARG'
	}
	foreach my $attr_name (keys %{$attrs}) {
		$node->set_enumerated_attribute( $attr_name, $attrs->{$attr_name} );
	}
}

sub test_mandatory_enumerated_attributes {
	my ($node) = @_;
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $mand_attrs = $NODE_TYPES{$node_type}->{$TPI_MA_ENUMS} or return( 1 ); # no-op if no mand
	foreach my $attr_name (keys %{$mand_attrs}) {
		unless( defined( $node->{$NPROP_AT_ENUMS}->{$attr_name} ) ) {
			$node->_throw_error_message( 'SSM_N_TEMA_ENUM_AT_NO_VAL_SET', 
				{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
			# test_mandatory_enumerated_attributes(): this '$HOSTTYPE' Node has failed a test; 
			# the enumerated attribute named '$attr_name' must be given a value
		}
	}
}

######################################################################

sub expected_node_attribute_type {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SSM_N_EXP_NODE_AT_NO_ARGS' );
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $exp_node_type = $NODE_TYPES{$node_type}->{$TPI_AT_NODES} && 
		$NODE_TYPES{$node_type}->{$TPI_AT_NODES}->{$attr_name};
	unless( $exp_node_type ) {
		$node->_throw_error_message( 'SSM_N_EXP_NODE_AT_INVAL_NM', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
		# expected_node_attribute_type(): invalid ATTR_NAME argument; 
		# there is no Node attribute named '$NAME' in '$HOSTTYPE' Nodes
	}
	return( $exp_node_type );
}

sub get_node_attribute {
	my ($node, $attr_name) = @_;
	$node->expected_node_attribute_type( $attr_name ); # dies if bad arg
	return( $node->{$NPROP_AT_NODES}->{$attr_name} );
}

sub get_node_attributes {
	return( {%{$_[0]->{$NPROP_AT_NODES}}} );
}

sub clear_node_attribute {
	my ($node, $attr_name) = @_;
	$node->expected_node_attribute_type( $attr_name ); # dies if bad arg
	$node->_clear_node_attribute( $attr_name );
}

sub clear_node_attributes {
	my ($node) = @_;
	foreach my $attr_name (sort keys %{$node->{$NPROP_AT_NODES}}) {
		$node->_clear_node_attribute( $attr_name );
	}
}

sub _clear_node_attribute {
	my ($node, $attr_name) = @_;
	my $attr_value = $node->{$NPROP_AT_NODES}->{$attr_name} or return( 1 ); # no-op; attr not set
	if( ref($attr_value) eq ref($node) and $node->{$NPROP_LINKS_RECIP} ) {
		# The attribute value is a Node object, and that Node has linked back, so clear that link.
		my $ra_children_of_parent = $attr_value->{$NPROP_CHILD_NODES};
		foreach my $i (0..$#{$ra_children_of_parent}) {
			if( $ra_children_of_parent->[$i] eq $node ) {
				# remove first instance of $node from it's parent's child list
				splice( @{$ra_children_of_parent}, $i, 1 );
				last;
			}
		}
	}
	delete( $node->{$NPROP_AT_NODES}->{$attr_name} ); # removes link to parent, if any
}

sub set_node_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	my $exp_node_type = $node->expected_node_attribute_type( $attr_name ); # dies if bad arg
	defined( $attr_value ) or $node->_throw_error_message( 'SSM_N_SET_NODE_AT_NO_ARG_VAL' );

	if( ref($attr_value) eq ref($node) ) {
		# We were given a Node object for a new attribute value.

		unless( $attr_value->{$NPROP_NODE_TYPE} eq $exp_node_type ) {
			$node->_throw_error_message( 'SSM_N_SET_NODE_AT_WRONG_NODE_TYPE', 
				{ 'NAME' => $attr_name, 'HOSTTYPE' => $node->{$NPROP_NODE_TYPE}, 
				'EXPTYPE' => $exp_node_type, 'GIVEN' => $attr_value->{$NPROP_NODE_TYPE} } );
			# set_node_attribute(): invalid ATTR_VALUE argument; the attribute named 
			# '$NAME' in '$HOSTTYPE' Nodes may only reference a '$EXPTYPE' Node, but 
			# you tried to set it to a '$GIVEN' Node
		}

		if( $attr_value->{$NPROP_CONTAINER} and $node->{$NPROP_CONTAINER} ) {
			unless( $attr_value->{$NPROP_CONTAINER} eq $node->{$NPROP_CONTAINER} ) {
				$node->_throw_error_message( 'SSM_N_SET_NODE_AT_DIFF_CONT' );
				# set_node_attribute(): invalid ATTR_VALUE argument; that Node is not in 
				# the same Container as the current Node, so they can not be linked
			}
			# If we get here, both Nodes are in the same Container and can link
			} elsif( $attr_value->{$NPROP_CONTAINER} or $node->{$NPROP_CONTAINER} ) {
			$node->_throw_error_message( 'SSM_N_SET_NODE_AT_ONE_CONT' );
			# set_node_attribute(): invalid ATTR_VALUE argument; a Node that is in a 
			# Container can not be linked to one that is not

		} elsif( !$attr_value->{$NPROP_NODE_ID} ) {
			# both Nodes are not in Containers, and $attr_value has no Node Id
			$node->_throw_error_message( 'SSM_N_SET_NODE_AT_MISS_NID' );
			# set_node_attribute(): invalid ATTR_VALUE argument; the given Node 
			# lacks a Node Id, and one is required to link to it from this one
			} else {
			# both Nodes are not in Containers, and $attr_value has Node Id, so can link
			$attr_value = $attr_value->{$NPROP_NODE_ID};
		} 

	} else {
		# We may have been given a Node id for a new attribute value.
		if( $attr_value =~ /\D/ or $attr_value < 1 or int($attr_value) ne $attr_value ) {
			# The regexp above should suppress warnings about non-numerical arguments to '<'
			$node->_throw_error_message( 'SSM_N_SET_NODE_AT_BAD_ARG_VAL', { 'ARG' => $attr_value } );
			# set_node_attribute(): invalid ATTR_VALUE argument; '$ARG' is not a Node ref,  
			# and a Node Id may only be a positive integer
		}

		if( my $container = $node->{$NPROP_CONTAINER} ) {
			$attr_value = $container->{$CPROP_ALL_NODES}->{$exp_node_type}->{$attr_value};
			unless( $attr_value ) {
				$node->_throw_error_message( 'SSM_N_SET_NODE_AT_NONEX_NID', 
					{ 'ARG' => $attr_value, 'EXPTYPE' => $exp_node_type } );
				# set_node_attribute(): invalid ATTR_VALUE argument; '$ARG' is not a Node ref,  
				# and it does not match the Id of any 'EXPTYPE' Node in this Container.
			}
		}
	}

	if( ref($attr_value) eq ref($node) and !$attr_value->{$NPROP_LINKS_RECIP} ) {
		$node->_throw_error_message( 'SSM_N_SET_NODE_AT_RECIP_LINKS' );
		# set_node_attribute(): invalid ATTR_VALUE argument; the given Node is not yet 
		# in reciprocating status, so the current Node can not yet become a child of it
	}

	if( defined( $node->{$NPROP_AT_NODES}->{$attr_name} ) and
			$attr_value eq $node->{$NPROP_AT_NODES}->{$attr_name} ) {
		return( 1 ); # no-op; new attribute value same as old
	}

	$node->_clear_node_attribute( $attr_name ); # clears any existing link through this attribute
	$node->{$NPROP_AT_NODES}->{$attr_name} = $attr_value;
	if( ref($attr_value) eq ref($node) and $node->{$NPROP_LINKS_RECIP} ) {
		# The attribute value is a Node object, and that Node should link back now, so do it.
		push( @{$attr_value->{$NPROP_CHILD_NODES}}, $node );
	}
}

sub set_node_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SSM_N_SET_NODE_AT_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SSM_N_SET_NODE_AT_BAD_ARGS', { 'ARG' => $attrs } );
		# set_node_attributes(): invalid ATTRS argument; 
		# it is not a hash ref, but rather is '$ARG'
	}
	foreach my $attr_name (sort keys %{$attrs}) {
		$node->set_node_attribute( $attr_name, $attrs->{$attr_name} );
	}
}

sub test_mandatory_node_attributes {
	my ($node) = @_;
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $mand_attrs = $NODE_TYPES{$node_type}->{$TPI_MA_NODES} or return( 1 ); # no-op if no mand
	foreach my $attr_name (keys %{$mand_attrs}) {
		unless( defined( $node->{$NPROP_AT_NODES}->{$attr_name} ) ) {
			$node->_throw_error_message( 'SSM_N_TEMA_NODE_AT_NO_VAL_SET', 
				{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
			# test_mandatory_node_attributes(): this '$HOSTTYPE' Node has failed a test; 
			# the node attribute named '$attr_name' must be given a value
		}
	}
}

######################################################################

sub get_parent_node_attribute_name {
	return( $_[0]->{$NPROP_P_NODE_ATNM} );
}

sub get_parent_node {
	my ($node) = @_;
	if( $node->{$NPROP_P_NODE_ATNM} and $node->{$NPROP_CONTAINER} ) {
		# Note that the associated AT_NODES property may not be valued right now.
		# This code may be changed later to return a Node id when not in a container.
		return( $node->{$NPROP_AT_NODES}->{$node->{$NPROP_P_NODE_ATNM}} );
	}
}

sub clear_parent_node_attribute_name {
	$_[0]->{$NPROP_P_NODE_ATNM} = undef;
}

sub set_parent_node_attribute_name {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SSM_N_SET_P_NODE_ATNM_NO_ARGS' );
	my $node_type = $node->{$NPROP_NODE_TYPE};
	unless( $NODE_TYPES{$node_type}->{$TPI_P_NODE_ATNMS} and 
			grep { $_ eq $attr_name } @{$NODE_TYPES{$node_type}->{$TPI_P_NODE_ATNMS}} ) {
		$node->_throw_error_message( 'SSM_N_SET_P_NODE_ATNM_INVAL_NM', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
		# set_parent_node_attribute_name(): invalid ATTR_NAME argument; 
		# either there is no Node attribute named '$NAME' in '$HOSTTYPE' Nodes, 
		# or that attribute can not be used as the primary parent Node
	}
	$node->{$NPROP_P_NODE_ATNM} = $attr_name;
}

######################################################################

sub estimate_parent_node_attribute_name {
	# This function tries to find a way to make its argument Node a primary parent of 
	# the current Node; it returns the first appropriate node attribute name which 
	# takes a Node of the same node type of the argument.
	my ($node, $new_parent, $only_not_valued) = @_;
	defined( $new_parent ) or $node->_throw_error_message( 'SSM_N_EST_P_NODE_ATNM_NO_ARGS' );
	unless( ref($new_parent) eq ref($node) ) {
		$node->_throw_error_message( 'SSM_N_EST_P_NODE_ATNM_BAD_ARG', { 'ARG' => $new_parent } );
		# estimate_parent_node_attribute_name(): invalid NEW_PARENT argument; 
		# it is not a Node object, but rather is '$ARG'
	}
	my $parent_node_type = $new_parent->{$NPROP_NODE_TYPE};
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $p_node_atnms = $NODE_TYPES{$node_type}->{$TPI_P_NODE_ATNMS} or return( undef ); # can't have any parent
	my $exp_at_nodes = $NODE_TYPES{$node_type}->{$TPI_AT_NODES}; # assume exists, as prev does
	my $at_nodes = $node->{$NPROP_AT_NODES};
	foreach my $attr_name (@{$p_node_atnms}) {
		my $exp_at_node = $exp_at_nodes->{$attr_name};
		if( $parent_node_type eq $exp_at_node ) {
			# If we get here, we found a primary parent attribute which is of the right type.
			$only_not_valued and $at_nodes->{$attr_name} and next; # can't use when has value; keep looking
			return( $attr_name ); # no value set or may overwrite it
		}
	}
	return( undef ); # given Node wrong type or competitor for primary parent of current Node
}

######################################################################

sub expected_attribute_major_type {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SSM_N_EXP_AT_MT_NO_ARGS' );
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $namt = $node->major_type_of_node_type_attribute( $node_type, $attr_name );
	unless( $namt ) {
		$node->_throw_error_message( 'SSM_N_EXP_AT_MT_INVAL_NM', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
		# expected_attribute_major_type(): invalid ATTR_NAME argument; 
		# there is no attribute named '$NAME' in '$HOSTTYPE' Nodes
	}
	return( $namt );
}

sub get_attribute {
	my ($node, $attr_name) = @_;
	my $namt = $node->expected_attribute_major_type( $attr_name ); # dies if bad arg
	$namt eq $NAMT_ID and return( $node->get_node_id() );
	$namt eq $NAMT_LITERAL and return( $node->get_literal_attribute( $attr_name ) );
	$namt eq $NAMT_ENUM and return( $node->get_enumerated_attribute( $attr_name ) );
	$namt eq $NAMT_NODE and return( $node->get_node_attribute( $attr_name ) );
	# We should never get here.
}

sub get_attributes {
	my ($node) = @_;
	return( {
		$ATTR_ID => $node->get_node_id(),
		%{$node->get_literal_attributes()},
		%{$node->get_enumerated_attributes()},
		%{$node->get_node_attributes()},
	} );
}

sub clear_attribute {
	my ($node, $attr_name) = @_;
	my $namt = $node->expected_attribute_major_type( $attr_name ); # dies if bad arg
	$namt eq $NAMT_ID and return( $node->clear_node_id() );
	$namt eq $NAMT_LITERAL and return( $node->clear_literal_attribute( $attr_name ) );
	$namt eq $NAMT_ENUM and return( $node->clear_enumerated_attribute( $attr_name ) );
	$namt eq $NAMT_NODE and return( $node->clear_node_attribute( $attr_name ) );
	# We should never get here.
}

sub clear_attributes {
	my ($node) = @_;
	$node->clear_node_id();
	$node->clear_literal_attributes();
	$node->clear_enumerated_attributes();
	$node->clear_node_attributes();
}

sub set_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	my $namt = $node->expected_attribute_major_type( $attr_name ); # dies if bad arg
	$namt eq $NAMT_ID and return( $node->set_node_id( $attr_value ) );
	$namt eq $NAMT_LITERAL and return( $node->set_literal_attribute( $attr_name, $attr_value ) );
	$namt eq $NAMT_ENUM and return( $node->set_enumerated_attribute( $attr_name, $attr_value ) );
	$namt eq $NAMT_NODE and return( $node->set_node_attribute( $attr_name, $attr_value ) );
	# We should never get here.
}

sub set_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SSM_N_SET_AT_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SSM_N_SET_AT_BAD_ARGS', { 'ARG' => $attrs } );
		# set_attributes(): invalid ATTRS argument; 
		# it is not a hash ref, but rather is '$ARG'
	}
	foreach my $attr_name (sort keys %{$attrs}) {
		my $attr_value = $attrs->{$attr_name};
		my $namt = $node->expected_attribute_major_type( $attr_name ); # dies if bad arg
		if( $namt eq $NAMT_ID ) {
			$node->set_node_id( $attr_value );
			next;
		}
		if( $namt eq $NAMT_LITERAL ) {
			$node->set_literal_attribute( $attr_name, $attr_value );
			next;
		}
		if( $namt eq $NAMT_ENUM ) {
			$node->set_enumerated_attribute( $attr_name, $attr_value );
			next;
		}
		if( $namt eq $NAMT_NODE ) {
			$node->set_node_attribute( $attr_name, $attr_value );
			next;
		}
		# We should never get here.
	}
}

sub test_mandatory_attributes {
	my ($node) = @_;
	$node->test_mandatory_literal_attributes();
	$node->test_mandatory_enumerated_attributes();
	$node->test_mandatory_node_attributes();
}

######################################################################

sub get_container {
	return( $_[0]->{$NPROP_CONTAINER} );
}

sub put_in_container {
	my ($node, $new_container) = @_;
	defined( $new_container ) or $node->_throw_error_message( 'SSM_N_SET_NODE_ID_NO_ARGS' );

	unless( UNIVERSAL::isa( $new_container, 'SQL::SyntaxModel::_::Container' ) ) {
		$node->_throw_error_message( 'SSM_N_PI_CONT_BAD_ARG', { 'ARG' => $new_container } );
		# put_in_container(): invalid NEW_CONTAINER argument; 
		# it is not a Container object, but rather is '$ARG'
	}

	my $node_id = $node->{$NPROP_NODE_ID};
	unless( $node_id ) {
		$node->_throw_error_message( 'SSM_N_PI_CONT_NO_NODE_ID' );
		# put_in_container(): this Node can not be put in a Container yet 
		# as this Node has no NODE_ID defined
	}

	if( $node->{$NPROP_CONTAINER} ) {
		if( $new_container eq $node->{$NPROP_CONTAINER} ) {
			return( 1 ); # no-op; new container same as old
		}
		$node->_throw_error_message( 'SSM_N_PI_CONT_HAVE_ALREADY' );
		# put_in_container(): this Node already lives in a Container; you 
		# must take this Node from there before putting it in a different one
	}
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $tpi_at_nodes = $NODE_TYPES{$node_type}->{$TPI_AT_NODES};
	my $rh_at_nodes_nids = $node->{$NPROP_AT_NODES}; # all values should be node ids now
	my $rh_cnl_bt = $new_container->{$CPROP_ALL_NODES};

	my %at_nodes_refs = (); # values put in here will be actual references
	foreach my $at_nodes_atnm (keys %{$rh_at_nodes_nids}) {
		# We need to make sure that when an attribute value is cleared, its key is deleted
		# Note that if $tpi_at_nodes is undefined, expect that this foreach loop will not run
		my $at_nodes_nid = $rh_at_nodes_nids->{$at_nodes_atnm};
		my $at_node_type = $tpi_at_nodes->{$at_nodes_atnm};
		my $at_nodes_ref = $rh_cnl_bt->{$at_node_type}->{$at_nodes_nid};
		unless( $at_nodes_ref ) {
			$node->_throw_error_message( 'SSM_N_PI_CONT_NONEX_AT_NODE', 
				{ 'ATNM' => $at_nodes_atnm, 'TYPE' => $at_node_type, 'ID' => $at_nodes_nid } );
			# put_in_container(): this Node can not be put into the given Container 
			# because the Node attribute named '$ATNM' expects to link to a '$TYPE' Node 
			# with a Node Id of '$ID', but no such Node exists in the given Container
		}		$at_nodes_refs{$at_nodes_atnm} = $at_nodes_ref;
	}
	$node->{$NPROP_CONTAINER} = $new_container;
	$node->{$NPROP_AT_NODES} = \%at_nodes_refs;
	$rh_cnl_bt->{$node_type}->{$node_id} = $node;
	# We don't get referenced nodes to link back here; caller requests that separately

	if( my $p_pseudonode = $NODE_TYPES{$node_type}->{$TPI_P_PSEUDONODE} ) {
		push( @{$new_container->{$CPROP_PSEUDONODES}->{$p_pseudonode}}, $node );
	}
}

sub take_from_container {
	my ($node) = @_;
	my $container = $node->{$NPROP_CONTAINER} or return( 1 ); # no-op; node is already not in a container

	if( $node->{$NPROP_LINKS_RECIP} ) {
		$node->_throw_error_message( 'SSM_N_TF_CONT_RECIP_LINKS' );
		# take_from_container(): this Node can not be taken from its Container yet 
		# as other Nodes that this Node refers to in its attributes have reciprocal links to it
	}

	my $node_id = $node->{$NPROP_NODE_ID};
	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $rh_at_nodes_refs = $node->{$NPROP_AT_NODES};

	my %at_nodes_nids = (); # values put in here will be node id numbers
	foreach my $at_nodes_atnm (keys %{$rh_at_nodes_refs}) {
		# We need to make sure that when an attribute value is cleared, its key is deleted
		$at_nodes_nids{$at_nodes_atnm} = $rh_at_nodes_refs->{$at_nodes_atnm}->{$NPROP_NODE_ID};
	}

	if( my $p_pseudonode = $NODE_TYPES{$node_type}->{$TPI_P_PSEUDONODE} ) {
		my $siblings = $container->{$CPROP_PSEUDONODES}->{$p_pseudonode};
		@{$siblings} = grep { $_ ne $node } @{$siblings};
	}
	delete( $node->{$NPROP_CONTAINER}->{$CPROP_ALL_NODES}->{$node_type}->{$node_id} );
	$node->{$NPROP_AT_NODES} = \%at_nodes_nids;
	$node->{$NPROP_CONTAINER} = undef;
}

######################################################################

sub are_reciprocal_links {
	# A true value just means any links we may make will reciprocate;
	# we may not actually have any links yet.
	return( $_[0]->{$NPROP_LINKS_RECIP} );
}

sub add_reciprocal_links {
	my ($node) = @_;
	$node->{$NPROP_LINKS_RECIP} and return( 1 ); # no-op; links are already reciprocated

	my $container = $node->{$NPROP_CONTAINER};
	unless( $container ) {
		$node->_throw_error_message( 'SSM_N_ADD_RL_NO_NODE_ID' );
		# add_reciprocal_links(): this Node is not in a Container, 
		# so no other Nodes can link to it as a child
	}

	foreach my $attr_value (values %{$node->{$NPROP_AT_NODES}}) {
		push( @{$attr_value->{$NPROP_CHILD_NODES}}, $node );
	}
	$node->{$NPROP_LINKS_RECIP} = 1;
}

sub remove_reciprocal_links {
	my ($node) = @_;
	$node->{$NPROP_LINKS_RECIP} or return( 1 ); # no-op; links are already not reciprocated

	if( @{$node->{$NPROP_CHILD_NODES}} > 0 ) {
		$node->_throw_error_message( 'SSM_N_REM_RL_HAS_CHILD' );
		# remove_reciprocal_links(): this Node has child Nodes of its 
		# own, so it can not be removed from reciprocating status
	}

	foreach my $attr_value (@{$node->{$NPROP_AT_NODES}}) {
		my $ra_children_of_parent = $attr_value->{$NPROP_CHILD_NODES};
		foreach my $i (0..$#{$ra_children_of_parent}) {
			if( $ra_children_of_parent->[$i] eq $node ) {
				# remove first instance of $node from it's parent's child list
				splice( @{$ra_children_of_parent}, $i, 1 );
				last;
			}
		}
	}

	$node->{$NPROP_LINKS_RECIP} = 0;
}

######################################################################

sub collect_inherited_attributes {
	# this function is deprecated; inherited attributes that are 
	# copied to child nodes will cease to exist as a concept next time
	my ($node) = @_;

	my $node_type = $node->{$NPROP_NODE_TYPE};
	my $type_info = $NODE_TYPES{$node_type};

	my $psn_atnm = $type_info->{'parent_selfnode_attr'};
	my $inh_attrs = $type_info->{'inherited_selfnode_attrs'};
	if( $inh_attrs ) {
		my $parent = $node->{$NPROP_AT_NODES}->{$psn_atnm}; # assumes Node is in Container now
		if( $parent ) {
			# When the parent of a node is the same type as it, inherit/copy these attributes.
			# These always override any values the user set for the current Node.
			foreach my $attr_name (@{$inh_attrs}) {
				my $attr_value = $parent->get_attribute( $attr_name );
				$node->set_attribute( $attr_name, $attr_value );
			}
		}
	}
}

######################################################################

sub get_child_nodes {
	my ($node, $node_type) = @_;
	if( defined( $node_type ) ) {
		return( [grep { $_->{$NPROP_NODE_TYPE} eq $node_type } @{$node->{$NPROP_CHILD_NODES}}] );
	} else {
		return( [@{$node->{$NPROP_CHILD_NODES}}] );
	}
}

sub add_child_node {
	my ($node, $new_child) = @_;
	defined( $new_child ) or $node->_throw_error_message( 'SSM_N_ADD_CH_NODE_NO_ARGS' );
	if( ref($new_child) eq 'HASH' ) { # deprecated; for backwards compatability to 0.06
		return( $node->create_child_node_tree( $new_child ) );
	}
	unless( ref($new_child) eq ref($node) ) {
		$node->_throw_error_message( 'SSM_N_ADD_CH_NODE_BAD_ARG', { 'ARG' => $new_child } );
		# add_child_node(): invalid NEW_CHILD argument; 
		# it is not a Node object, but rather is '$ARG'
	}
	my $est_attr_name = $new_child->estimate_parent_node_attribute_name( $node );
	unless( $est_attr_name ) {
		$node->_throw_error_message( 'SSM_N_ADD_CH_NODE_NO_EST' );
		# add_child_node(): the current Node can not be the primary parent of the given Node
	}
	$new_child->set_node_attribute( $est_attr_name, $node ); # will die if not same Container
	$new_child->set_parent_node_attribute_name( $est_attr_name );
}

sub add_child_nodes {
	my ($node, $list) = @_;
	$list or return( undef );
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$node->add_child_node( $element );
	}
}

######################################################################

sub create_child_node_tree {
	# this function is deprecated, probably
	my ($node, $args) = @_;
	defined( $args ) or $node->_throw_error_message( 'SSM_N_CR_NODE_TREE_NO_ARGS' );

	unless( ref($args) eq 'HASH' ) {
		$node->_throw_error_message( 'SSM_N_CR_NODE_TREE_BAD_ARGS', { 'ARG' => $args } );
		# create_child_node_tree(): invalid argument; it is not a hash ref, but rather is '$ARG'
	}

	my $new_child = $node->create_empty_node( $args->{$ARG_NODE_TYPE} );
	$new_child->set_attributes( $args->{$ARG_ATTRS} ); # handles node id and all attribute types
	$new_child->put_in_container( $node->{$NPROP_CONTAINER} );
	$new_child->add_reciprocal_links();

	$node->add_child_node( $new_child ); # sets more attributes in new_child

	$new_child->collect_inherited_attributes();
	$new_child->test_mandatory_attributes();
	$new_child->create_child_node_trees( $args->{$ARG_CHILDREN} );

	return( $new_child );
}

sub create_child_node_trees {
	# this function is deprecated, probably
	my ($node, $list) = @_;
	$list or return( undef );
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		if( ref($element) eq ref($node) ) {
			$node->add_child_node( $element ); # will die if not same Container
		} else {
			$node->create_child_node_tree( $element );
		}
	}
}

######################################################################

sub get_all_properties {
	return( $_[0]->_get_all_properties() );
}

sub _get_all_properties {
	my ($node) = @_;
	my %dump = ();

	$dump{$ARG_NODE_TYPE} = $node->{$NPROP_NODE_TYPE};

	my $at_nodes_in = $node->{$NPROP_AT_NODES};
	$dump{$ARG_ATTRS} = {
		$ATTR_ID => $node->{$NPROP_NODE_ID},
		%{$node->{$NPROP_AT_LITERALS}},
		%{$node->{$NPROP_AT_ENUMS}},
		(map { ( $_ => $at_nodes_in->{$_}->{$NPROP_NODE_ID} ) } keys %{$at_nodes_in}),
	};

	my @children_out = ();
	my %children_were_output = ();
	foreach my $child (@{$node->{$NPROP_CHILD_NODES}}) {
		if( my $child_p_node_atnm = $child->{$NPROP_P_NODE_ATNM} ) {
			if( my $child_main_parent = $child->{$NPROP_AT_NODES}->{$child_p_node_atnm} ) {
				if( $child_main_parent eq $node ) {
					# Only output child if we are its primary parent, not simply any parent.
					unless( $children_were_output{$child} ) {
						# Only output child once; a child may link to same parent multiple times.
						push( @children_out, $child->_get_all_properties() );
						$children_were_output{$child} = 1;
					}
				}
			}
		}
	}
	$dump{$ARG_CHILDREN} = \@children_out;

	return( \%dump );
}

sub get_all_properties_as_perl_str {
	return( $_[0]->_serialize_as_perl( $_[1], $_[0]->_get_all_properties() ) );
}

sub get_all_properties_as_xml_str {
	return( $_[0]->_serialize_as_xml( $_[1], $_[0]->_get_all_properties() ) );
}

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::_::Container;
use base qw( SQL::SyntaxModel::_::Shared );

######################################################################

sub get_node {
	my ($container, $node_type, $node_id) = @_;
	defined( $node_type ) or $container->_throw_error_message( 'SSM_C_GET_NODE_NO_ARG_TYPE' );
	defined( $node_id ) or $container->_throw_error_message( 'SSM_C_GET_NODE_NO_ARG_ID' );
	unless( $NODE_TYPES{$node_type} ) {
		$container->_throw_error_message( 'SSM_C_GET_NODE_BAD_TYPE', { 'TYPE' => $node_type } );
		# get_node(): invalid NODE_TYPE argument; there is no Node Type named '$TYPE'
	}
	return( $container->{$CPROP_ALL_NODES}->{$node_type}->{$node_id} );
}

######################################################################

sub create_node_tree {
	# this function is deprecated, probably
	my ($container, $args) = @_;
	defined( $args ) or $container->_throw_error_message( 'SSM_C_CR_NODE_TREE_NO_ARGS' );

	unless( ref($args) eq 'HASH' ) {
		$container->_throw_error_message( 'SSM_C_CR_NODE_TREE_BAD_ARGS', { 'ARG' => $args } );
		# create_node_tree(): invalid argument; it is not a hash ref, but rather is '$ARG'
	}

	my $node = $container->create_empty_node( $args->{$ARG_NODE_TYPE} );
	$node->set_attributes( $args->{$ARG_ATTRS} ); # handles node id and all attribute types
	$node->put_in_container( $container );
	$node->add_reciprocal_links();
	$node->collect_inherited_attributes();
	$node->test_mandatory_attributes();
	$node->create_child_node_trees( $args->{$ARG_CHILDREN} );

	return( $node );
}

sub create_node_trees {
	# this function is deprecated, probably
	my ($container, $list) = @_;
	$list or return( undef );
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$container->create_node_tree( $element );
	}
}

######################################################################

sub get_all_properties {
	return( $_[0]->_get_all_properties() );
}

sub _get_all_properties {
	my ($container) = @_;
	my $pseudonodes = $container->{$CPROP_PSEUDONODES};
	return( {
		$ARG_NODE_TYPE => $SQLSM_ROOT_NODE_TYPE,
		$ARG_ATTRS => {},
		$ARG_CHILDREN => [map { {
			$ARG_NODE_TYPE => $_,
			$ARG_ATTRS => {},
			$ARG_CHILDREN => [map { $_->_get_all_properties() } @{$pseudonodes->{$_}}],
		} } @L2_PSEUDONODE_LIST],
	} );
}

sub get_all_properties_as_perl_str {
	return( $_[0]->_serialize_as_perl( $_[1], $_[0]->_get_all_properties() ) );
}

sub get_all_properties_as_xml_str {
	return( $_[0]->_serialize_as_xml( $_[1], $_[0]->_get_all_properties() ) );
}

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel;
use base qw( SQL::SyntaxModel::_::Shared );

######################################################################

sub new {
	my ($class) = @_;
	my $model = bless( {}, ref($class) || $class );
	$model->{$MPROP_CONTAINER} = bless( {}, $model->_get_static_const_container_class_name() );
	$model->_set_initial_container_props();
	return( $model );
}

sub _set_initial_container_props {
	my $container = $_[0]->{$MPROP_CONTAINER};
	$container->{$CPROP_ALL_NODES} = { map { ($_ => {}) } keys %NODE_TYPES };
	$container->{$CPROP_PSEUDONODES} = { map { ($_ => []) } @L2_PSEUDONODE_LIST };
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

sub initialize {
	my ($self) = @_;
	$self->_destroy_container_props();
	$self->_set_initial_container_props();
}

######################################################################
# Shims for methods declared in Container class.

sub get_node {
	return( $_[0]->{$MPROP_CONTAINER}->get_node( $_[1], $_[2] ) );
}

sub get_root_node { # deprecated; match name in 0.06; 
	# just use this for calls to get_all_properties/::*()
	return( $_[0] );
}

sub create_node_tree {
	return( $_[0]->{$MPROP_CONTAINER}->create_node_tree( $_[1] ) );
}
sub create_node { # deprecated alias; old name in 0.06
	return( $_[0]->{$MPROP_CONTAINER}->create_node_tree( $_[1] ) );
}

sub create_node_trees {
	$_[0]->{$MPROP_CONTAINER}->create_node_trees( $_[1] );
}
sub create_nodes { # deprecated alias; old name in 0.06
	$_[0]->{$MPROP_CONTAINER}->create_node_trees( $_[1] );
}

sub get_all_properties {
	$_[0]->{$MPROP_CONTAINER}->get_all_properties( $_[1] );
}

sub get_all_properties_as_perl_str {
	$_[0]->{$MPROP_CONTAINER}->get_all_properties_as_perl_str( $_[1] );
}

sub get_all_properties_as_xml_str {
	$_[0]->{$MPROP_CONTAINER}->get_all_properties_as_xml_str( $_[1] );
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<See the CONTRIVED EXAMPLE documentation section at the end.>

=head1 DESCRIPTION

The SQL::SyntaxModel Perl 5 object class is intended to be a powerful but easy
to use replacement for SQL strings (including support for placeholders), which
you can use to make queries against a database.  Each SQL::SyntaxModel object
can represent a non-ambiguous structured command for a database to execute, or
one can be a non-ambiguous structured description of a database schema object. 
This class supports all types of database operations, including both data
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
objects usually live.  A typical application will only need to create one
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

Finally, any Node of certain types will always have a specific pseudo-node as
its single parent, which it does not reference in an attribute, and which can
not be changed.  All 4 pseudo-nodes have no attributes, even 'id', and only one
of each exists; they are created by default with the Container they are part
of, forming the top 2 levels of the Node tree, and can not be removed.  They
are: 'root' (the single level-1 Node which is parent to the other pseudo-nodes
but no normal Nodes), 'type_list' (parent to 'data_type' Nodes),
'database_list' (parent to 'database' Nodes), and 'application_list' (parent to
'application' Nodes).  All other Node types have normal Nodes as parents.

Note that this module does not support the concept of 'document fragments',
which is a set of Nodes not linked to the main tree.  Every Node (save the
pseudo-node root) must have a primary parent Node at all times.  However, Node
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
distribution when ready, or any CONTRIVED EXAMPLE code here.

=head1 FAULT TOLERANCE AND MULTI-THREADING SUPPORT

I<Disclaimer: The following claims assume that only this module's published API
is used, and that you do not set object properties directly or call private
methods, which Perl does not prevent.  It also assumes that the module is bug
free, and that any errors or warnings which appear while the code is running
are thrown explicitely by this module as part of its normal functioning.>

SQL::SyntaxModel is designed to ensure that the objects it produces are always
internally consistant, and that the data they contain is always well-formed,
regardless of the circumstances in which it is used.  You should be able to 
fetch data from the objects at any time and that data will be self-consistant 
and well-formed.  

This will not change regardless of what kind of bad input data you provide to
object methods or module functions.  Providing bad input data will cause the
module to throw an exception; if you catch this and the program continues
running (such as to chide the user and have them try entering correct input),
then the objects will remain un-corrupted and able to accept new input or give
proper output.  In most cases, the object will be in the same state as it was 
before the public method was called with the bad input.

This module does not use package variables at all, besides constants like
$VERSION, and all symbols ($@%) declared at file level are strictly constant
value declarations.  No object should ever step on another.

This module will allow a Node to be created piecemeal, such as when it is
storing details gathered one at a time from the user, and during this time some
mandatory Node properties may not be set, or pending links from this node to
others may not be validated.  However, until a Node has its required properties
set and/or its Node links are validated, no references will be made to this
Node from other Nodes; from their point of view it doesn't exist, and hence the
other Nodes are all consistant.

SQL::SyntaxModel is explicitely not thread-aware (thread-safe); it contains no
code to synchronize access to its objects' properties, such as semaphores or
locks or mutexes.  To internalize such things in an effective manner would have
made the code a lot more complex than it is now, without any clear benefits.  
However, this module can (and should) be used in multi-threaded environments 
where the application/caller code takes care of synchronizing access to its 
objects, especially if the application uses coarse-grained read or write locks.

The author's expectation is that this module will be mainly used in
circumstances where the majority of actions are reads, and there are very few
writes, such as with a data dictionary; perhaps all the writes on an object may
be when it is first created.  An application thread would obtain a read
lock/semaphore on a Container object during the period for which it needs to
ensure read consistency; it would block write lock attempts but not other read
locks.  It would obtain a write lock during the (usually short) period it needs
to change something, which blocks all other lock attempts (for read or write).

An example of this is a web server environment where each page request is being
handled by a distinct thread, and all the threads share one SQL::SyntaxModel
object; normally the object is instantiated when the server starts, and the
worker threads then read from it for guidance in using a common database.
Occasionally a thread will want to change the object, such as to correspond to
a simultaneous change to the database schema, or to the web application's data
dictionary that maps the database to application screens.  Under this
situation, the application's definitive data dictionary (stored partly or
wholly in a SQL::ObjectModel) can occupy one place in RAM visible to all
threads, and each thread won't have to keep looking somewhere else such as in
the database or a file to keep up with the definitive copy.  (Of course, any
*changes* to the in-memory data dictionary should see a corresponding update to
a non-volatile copy, like in an on-disk database or file.)

I<Note that, while a nice thing to do may be to manage a course-grained lock in
SQL::SyntaxModel, with the caller invoking lock_to_read() or lock_to_write() or
unlock() methods on it, Perl's thread->lock() mechanism is purely context
based; the moment lock_to_...() returns, the object has unlocked again.  Of
course, if you know a clean way around this, I would be happy to hear it.>

=head1 NODE EVOLUTION STATES

A SQL::SyntaxModel Node object always exists in one of 3 official ordered
states (which can conceptually be divided further into more states).  For now
we can call them "Alone" (1), "At Home" (2), and "Well Known" (3).  (Hey, that
rhymes!)  The set of legal operations you can perform on a Node are different
depending on its state, and a Node can only transition between
adjacent-numbered states one at a time.

When a new Node is created, using create_empty_node(), it starts out "Alone";
it does *not* live in a Container, and it is illegal to have any actual (Perl)
references between it and any other Node.  Nodes in this state can be built
(have their Node Id and other attributes set or changed) piecemeal with the
least processing overhead, and can be moved or exist independently of anything
else that SQL::ObjectModel manages.  An "Alone" Node does not need to have its
Node Id set.  Any Node attributes which are conceptually references to other
Nodes are stored and read as Id numbers when the Node is "Alone"; also, no
confirmation has yet taken place that the referenced Nodes actually exist yet.
A Node may only be individually deleted when it is "Alone"; in this state it
will be garbage collected like any Perl variable when your own reference to it
goes away.

When you invoke the put_in_container() method on an "Alone" Node, giving it a
Container object as an argument, the Node will transition to the "At Home"
state; you can move from "At Home" to "Alone" using the complementary
take_from_container() method.  An "At Home" Node lives in a Container, and any
attributes which refer to other Nodes now must be actual references, where the
existence of the other Node in the same Container is confirmed.  If any
conceptual references are set in a Node while it is "Alone", these will be
converted into actual references by put_in_container(), which will fail if any
can't be found.  take_from_container() will replace references with Node Ids. A
Node can only link to a Node in the same Container as itself.  While a Node in
"At Home" status can link to other Nodes, those Nodes can not link back to an
"At Home" Node in their own child list; from their point of view, the "At Home"
Node doesn't exist.  In addition, an "At Home" Node can not have children of 
its own; it can not be referenced by any other Nodes.

When you invoke the add_reciprocal_links() method on an "At Home" Node, the
Node will transition to the "Well Known" state; any other Nodes that this one
references will now link back to it in their own child lists.  The
complementary remove_reciprocal_links() method will break those return links
and transition a "Well Known" Node to an "At Home" one.  A "Well Known" Node 
is also allowed to have children of its own.

Testing for the existence of mandatory Node attribute values is separate from 
the official Node state and can be invoked on a Node at any time.  None of the 
official Node states themselves will assert that any mandatory attributes are 
populated.  This testing is separate partly to make it easy for you to build 
Nodes piecemeal, though there are other practical reasons for it.

Note that all typical Node attributes can be read, set, replaced, or cleared at
any time regardless of the Node state; you can set them all either when the
Node is "Alone" or when it is "Well Known", as is your choice.  However, the
Node Id must always have a value when the Node is in a Container; if you want
to make a Node "Well Known" as early as possible, you simply have to set its
Node Id first.

(In versions of SQL::SyntaxModel prior to 0.07, Nodes were effectively in 
"Well Known" status plus mandatory attribute assertion all the time, making 
this class considerably less flexible to use then than it is now.)

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

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>.  

All SQL::SyntaxModel functions and methods are either "getters" (which read and
return or generate values but do not change the state of anything) or "setters"
(which change the state of something but do not return anything on success);
none do getting or setting conditionally based on their arguments.  While this
means there are more methods in total, I see this arrangement as being more
stable and reliable, plus each method is simpler and easier to understand or
use; argument lists and possible return values are also less variable and more
predictable.

All "setter" functions or methods which are supposed to change the state of
something will throw an exception on failure (usually from being given bad
arguments); on success, they officially have no return values.  A thrown
exception will always include details of what went wrong (and where and how) in
a machine-readable (and generally human readable) format, so that calling code
which catches them can recover gracefully.  The methods are all structured so
that they check all preconditions prior to changing any state information, and
so one can assume that upon throwing an exception, the Node and Container
objects are in a consistent or recoverable state at worst, and are completely
unchanged at best.

All "getter" functions or methods will officially return the value or construct
that was asked for; if said value doesn't (yet or ever) exist, then this means
the Perl "undefined" value.  When given bad arguments, generally this module's
"information" functions will return the undefined value, and all the other
functions/methods will throw an exception like the "setter" functions do.

Generally speaking, if SQL::SyntaxModel throws an exception, it means one of
two things: 1. Your own code is not invoking it correctly, meaning you have
something to fix; 2. You have decided to let it validate some of your input
data for you (which is quite appropriate).  

Note also that SQL::SyntaxModel is quite strict in its own argument checking,
both for internal simplicity and robustness, and so that code which *reads* 
data from it can be simpler.  If you want your own program to be more liberal
in what input it accepts, then you will have to bear the burden of cleaning up
or interpreting that input, or delegating such work elsewhere.  (Or perhaps 
someone may want to make a wrapper module to do this?)

=head1 CONSTRUCTOR FUNCTIONS AND METHODS

These functions/methods are for creating new Container or Node objects.

=head2 new()

	my $model = SQL::SyntaxModel->new();

This function creates a new SQL::SyntaxModel (or subclass) Model/Container
object and returns it.  This Container has contains a set of pseudo-nodes, and
nothing else.

=head2 create_empty_node( NODE_TYPE )

	my $node = $model->create_empty_node( 'table' );

This "getter" function/method will create and return a single Node object whose
Node Type is given in the NODE_TYPE (enum) argument, and all of whose other
properties are defaulted to an "empty" state.  A Node's type can only be set on
instantiation and can not be changed afterwards; only specific values are
allowed, which you can see in the previous POD section "BRIEF NODE TYPE LIST". 
This new Node does not yet live in a Container, and will have to be put in one
later before you can make full use of it.  However, you can read or set or
clear any or all of this new Node's attributes (including the Node Id) prior to
putting it in a Container, making it easy to build one piecemeal before it is
actually "used".  A Node can not have any actual Perl references between it and
other Nodes until it is in a Container, and as such you can delete it simply by
letting your own reference to it be garbage collected. This function/method is
stateless and deterministic; you can invoke it with the same results under any
circumstance and off of either this class itself or any other objects that this
class makes.

=head1 CONTAINER OBJECT METHODS

These methods are stateful and may only be invoked off of Container objects.

=head2 initialize()

	my $model->initialize();

This "setter" method resets the Container to the state it was in when it was
returned by new().  All of its member Nodes are destroyed, and new pseudo-nodes
are created.

=head2 get_node( NODE_TYPE, NODE_ID )

	my $database_node = $model->get_node( 'database', 1 );

This "getter" method returns a reference to one of this Container's member
Nodes, which has a Node Type of NODE_TYPE, and a Node Id of NODE_ID.  You may
not request a pseudo-node (it doesn't actually exist).

=head2 create_node_tree( { NODE_TYPE[, ATTRS][, CHILDREN] } )

	my $node = $model->create_node_tree( 
		{ 'NODE_TYPE' => 'database', 'ATTRS' => { 'id' => 1, } } ); 

This "setter" method creates a new Node object within the context of the
current Container and returns it.  It takes a hash ref containing up to 3 named
arguments: NODE_TYPE, ATTRS, CHILDREN.  The first argument, NODE_TYPE, is a
string (enum) which specifies the Node Type of the new Node.  The second
(optional) argument, ATTRS, is a hash ref whose elements will go in the various
"attributes" properties of the new Node (and the "node id" property if
applicable).  Any attributes which will refer to another Node can be passed in
as either a Node object reference or an integer which matches the 'id'
attribute of an already created Node.  The third (optional) argument, CHILDREN,
is an array ref whose elements will also be recursively made into new Nodes,
for which their primary parent is the Node you have just made here.  Elements
in CHILDREN are always processed after the other arguments. If the root Node
you are about to make should have a primary parent Node, then you would be
better to use said parent's create_child_node_tree[/s] method instead of this
one.  This method is actually a "wrapper" for a set of other, simpler
function/method calls that you could call directly instead if you wanted more
control over the process.

=head2 create_node_trees( LIST )

	$model->create_nodes( [{ ... }, { ... }] );
	$model->create_nodes( { ... } );

This "setter" method takes an array ref in its single LIST argument, and calls
create_node_tree() for each element found in it.

=head1 NODE OBJECT METHODS

These methods are stateful and may only be invoked off of Node objects.  For
some of these, it doesn't matter whether the Node is in a Container or not, nor
whether its links to other Nodes are reciprocated or not.  For others, one or
both of these conditions must be true or false for the method to be invoked, or
it will throw an exception (like for bad input).

=head2 delete_node()

This "setter" method will destroy the Node object that it is invoked from, if
it can. You are only allowed to delete Nodes that are not inside Containers,
and which don't have child Nodes; failing this, you must remove the children
and then take this Node from its Container first.  Technically, this method
doesn't actually do anything (pure-Perl version) other than validate that you
are allowed to delete; when said conditions are met, the Node will be garbage
collected as soon as you lose your reference to it.

=head2 get_node_type()

my $type = $node->get_node_type();

This "getter" method returns the Node Type scalar (enum) property of this Node.
 You can not change this property on an existing Node, but you can set it on a
new one.

=head2 get_node_id()

This "getter" method will return the integral Node Id property of this Node, 
if it has one.

=head2 clear_node_id()

This "setter" method will erase this Node's Id property if it can.  A Node's Id
may only be cleared if the Node is not in a Container.

=head2 set_node_id( NEW_ID )

This "setter" method will set or replace this Node's Id property if it can.  If 
this Node is in a Container, then the replacement will fail if some other Node 
with the same Node Type and Node Id already exists in the same Container.

=head2 expected_literal_attribute_type( ATTR_NAME )

This "getter" method will return an enumerated value that explains which
literal data type that values for this Node's literal attribute named in the
ATTR_NAME argument must be.

=head2 get_literal_attribute( ATTR_NAME )

This "getter" method will return the value for this Node's literal attribute named
in the ATTR_NAME argument.

=head2 get_literal_attributes()

This "getter" method will fetch all of this Node's literal attributes, 
returning them in a Hash ref.

=head2 clear_literal_attribute( ATTR_NAME )

This "setter" method will clear this Node's literal attribute named in
the ATTR_NAME argument.

=head2 clear_literal_attributes()

This "setter" method will clear all of this Node's literal attributes.

=head2 set_literal_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's literal attribute named in
the ATTR_NAME argument, giving it the new value specified in ATTR_VALUE.

=head2 set_literal_attributes( ATTRS )

This "setter" method will set or replace multiple Node literal attributes,
whose names and values are specified by keys and values of the ATTRS hash ref
argument; this method will invoke set_literal_attribute() for each key/value
pair.

=head2 test_mandatory_literal_attributes()

This "getter" method implements a type of deferrable data validation.  It will
look at all of this Node's literal attributes which must have a value set
before this Node is ready to be used, and throw an exception if any are not.

=head2 expected_enumerated_attribute_type( ATTR_NAME )

This "getter" method will return an enumerated value that explains which
enumerated data type that values for this Node's enumerated attribute named in the
ATTR_NAME argument must be.

=head2 get_enumerated_attribute( ATTR_NAME )

This "getter" method will return the value for this Node's enumerated attribute
named in the ATTR_NAME argument.

=head2 get_enumerated_attributes()

This "getter" method will fetch all of this Node's enumerated attributes,
returning them in a Hash ref.

=head2 clear_enumerated_attribute( ATTR_NAME )

This "setter" method will clear this Node's enumerated attribute named in the
ATTR_NAME argument.

=head2 clear_enumerated_attributes()

This "setter" method will clear all of this Node's enumerated attributes.

=head2 set_enumerated_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's enumerated attribute named in
the ATTR_NAME argument, giving it the new value specified in ATTR_VALUE.

=head2 set_enumerated_attributes( ATTRS )

This "setter" method will set or replace multiple Node enumerated attributes,
whose names and values are specified by keys and values of the ATTRS hash ref
argument; this method will invoke set_enumerated_attribute() for each key/value
pair.

=head2 test_mandatory_enumerated_attributes()

This "getter" method implements a type of deferrable data validation.  It will
look at all of this Node's enumerated attributes which must have a value set
before this Node is ready to be used, and throw an exception if any are not.

=head2 expected_node_attribute_type( ATTR_NAME )

This "getter" method will return an enumerated value that explains which Node
Type that values for this Node's node attribute named in the ATTR_NAME argument
must be.

=head2 get_node_attribute( ATTR_NAME )

This "getter" method will return the value for this Node's node attribute
named in the ATTR_NAME argument.  The value will be a Node ref if the current 
Node is in a Container, and an Id number if it isn't.

=head2 get_node_attributes()

This "getter" method will fetch all of this Node's node attributes,
returning them in a Hash ref.  The values will be Node refs if the current 
Node is in a Container, and Id numbers if it isn't.

=head2 clear_node_attribute( ATTR_NAME )

This "setter" method will clear this Node's node attribute named in the
ATTR_NAME argument.  If the other Node being referred to has a reciprocal 
link to the current one in its child list, that will also be cleared.

=head2 clear_node_attributes()

This "setter" method will clear all of this Node's node attributes; see 
the clear_node_attribute() documentation for the semantics.

=head2 set_node_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's node attribute named in
the ATTR_NAME argument, giving it the new value specified in ATTR_VALUE (if it
is different).  If the attribute was previously valued, this method will first
invoke clear_node_attribute() on it.  When setting a new value, if the current
Node is in a Container and expects Nodes it links to reciprocate, then it will
also add the current Node to the other Node's child list.

=head2 set_node_attributes( ATTRS )

This "setter" method will set or replace multiple Node node attributes,
whose names and values are specified by keys and values of the ATTRS hash ref
argument; this method will invoke set_node_attribute() for each key/value
pair.

=head2 test_mandatory_node_attributes()

This "getter" method implements a type of deferrable data validation.  It will
look at all of this Node's node attributes which must have a value set
before this Node is ready to be used, and throw an exception if any are not.

=head2 get_parent_node_attribute_name()

This "getter" method returns the name of this Node's node attribute which is
designated to reference this Node's primary parent Node, if there is one.

=head2 get_parent_node()

	my $parent = $node->get_parent_node();

This "getter" method returns the primary parent Node of the current Node, if
there is one.  The semantics are like "if the current Node is in a Container
and its 'parent node attribute name' is defined, then return the Node ref value
of the named node attribute, if it has one".

=head2 clear_parent_node_attribute_name()

This "setter" method will clear this Node's 'parent node attribute name' 
property, if it has one.  The actual node attribute being referred to 
is not affected.

=head2 set_parent_node_attribute_name( ATTR_NAME )

This "setter" method will set or replace this Node's 'parent node attribute
name' property, giving it the new value specified in ATTR_NAME.  No actual node
attribute is affected.  Note that only a subset (usually one) of a Node's node
attributes may be named as the holder of its primary parent.

=head2 estimate_parent_node_attribute_name( NEW_PARENT[, ONLY_NOT_VALUED] )

This "getter" method will try to find a way to make the Node given in its
NEW_PARENT argument into the primary parent of the current Node.  It returns
the name of the first appropriate Node attribute which takes a Node of the same
Node Type as NEW_PARENT; if one can not be found, the undefined value is
returned.  By default, the current value of the found attribute is ignored; but
if the optional argument ONLY_NOT_VALUED is true, then an otherwise acceptible
attribute name will not be returned if it already has a value.

=head2 expected_attribute_major_type( ATTR_NAME )

This "getter" method will return an enumerated value that explains which major
data type that values for this Node's attribute named in the ATTR_NAME argument
must be.  There are 4 possible return values: 'ID' (the Node Id), 'LITERAL' (a
literal attribute), 'ENUM' (an enumerated attribute), and 'NODE' (a node
attribute).

=head2 get_attribute( ATTR_NAME )

	my $curr_val = $node->get_attribute( 'name' );

This "getter" method will return the value for this Node's attribute named in
the ATTR_NAME argument.

=head2 get_attributes()

	my $rh_attrs = $node->get_attributes();

This "getter" method will fetch all of this Node's attributes, returning them
in a Hash ref.

=head2 clear_attribute( ATTR_NAME )

This "setter" method will clear this Node's attribute named in the ATTR_NAME
argument.

=head2 clear_attributes()

This "setter" method will clear all of this Node's attributes.

=head2 set_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's attribute named in the
ATTR_NAME argument, giving it the new value specified in ATTR_VALUE.

=head2 set_attributes( ATTRS )

	$node->set_attributes( $rh_attrs );

This "setter" method will set or replace multiple Node attributes, whose names
and values are specified by keys and values of the ATTRS hash ref argument;
this method will invoke set_attribute() for each key/value pair.

=head2 test_mandatory_attributes()

This "getter" method implements a type of deferrable data validation. It will
look at all of this Node's attributes which must have a value set before this
Node is ready to be used, and throw an exception if any are not.

=head2 get_container()

	my $model = $node->get_container();

This "getter" method returns the Container object which this Node lives in, if
any.

=head2 put_in_container( NEW_CONTAINER )

This "setter" method will put the current Node into the Container given as the
NEW_CONTAINER argument if it can, which moves the Node from "Alone" to "At
Home" status.

=head2 take_from_container()

This "setter" method will take the current Node from its Container if it can,
which moves the Node from "At Home" to "Alone" status.

=head2 are_reciprocal_links()

This "getter" method returns a true boolean value if the current Node is in
"Well Known" status, and false otherwise.

=head2 add_reciprocal_links()

This "setter" method will move the current Node from "At Home" to "Well Known"
status if possible.

=head2 remove_reciprocal_links()

This "setter" method will move the current Node from ""Well Known" to "At Home"
status if possible.

=head2 get_child_nodes([ NODE_TYPE ])

	my $ra_node_list = $node->get_child_nodes();
	my $ra_node_list = $node->get_child_nodes( 'table' );

This "getter" method returns a list of this object's child Nodes, in a new
array ref. If the optional argument NODE_TYPE is defined, then only child Nodes
of that Node Type are returned; otherwise, all child Nodes are returned.  All
Nodes are returned in the same order they were added.

=head2 add_child_node( NEW_CHILD )

	$node->add_child_node( $child );

This "setter" method allows you to add a new child Node to this object, which
is provided as the single NEW_CHILD Node ref argument.  The new child Node is
appended to the list of existing child Nodes, and the current Node becomes the
new or first primary parent Node of NEW_CHILD.

=head2 add_child_nodes( LIST )

	$model->add_child_nodes( [$child1,$child2] );
	$model->add_child_nodes( $child );

This "setter" method takes an array ref in its single LIST argument, and calls
add_child_node() for each element found in it.

=head2 create_child_node_tree( { NODE_TYPE[, ATTRS][, CHILDREN] } )

	my $new_child = $node->add_child_node( 
		{ 'NODE_TYPE' => 'namespace', 'ATTRS' => { 'id' => 1, } } ); 

This "setter" method will create a new Node, following the same semantics (and
taking the same arguments) as the Container->create_node_tree(), except that 
create_child_node_tree() will also set the primary parent of the new Node to 
be the current Node.  This method also returns the new child Node.

=head2 create_child_node_trees( LIST )

	$model->create_child_node_tree( [$child1,$child2] );
	$model->create_child_node_tree( $child );

This "setter" method takes an array ref in its single LIST argument, and calls
create_child_node_tree() for each element found in it.

=head1 CONTAINER OR NODE METHODS FOR DEBUGGING

The following 3 "getter" methods can be invoked either on Container or Node
objects, and will return a tree-arranged structure having the contents of a
Node and all its children (to the Nth generation).  The previous statement
assumes that all the 'children' have a true are_reciprocal_links property,
which means that a Node's parent is aware of it; if that property is false for
a Node, the assumption is that said Node is still being constructed, and
neither it nor its children will be included in the output.  If you invoke the
3 methods on a Node, then that Node will be the root of the returned structure.
If you invoke them on a Container, then a few pseudo-nodes will be output with
all the normal Nodes in the Container as their children.

=head2 get_all_properties()

	$rh_node_properties = $node->get_all_properties();
	$rh_node_properties = $container->get_all_properties();

This method returns a deep copy of all of the properties of this object as
non-blessed Perl data structures.  These data structures are also arranged in a
tree, but they do not have any circular references.  You might be able to take
the output of this method and recreate the original objects by passing it to
create_[/child_]node_tree[/s](), although this may not work reliably.  The main
purpose, currently, of get_all_properties() is to make it easier to debug or
test this class; it makes it easier to see at a glance whether the other class
methods are doing what you expect.  The output of this method should also be
easy to serialize or unserialize to strings of Perl code or xml or other
things, should you want to compare your results easily by string compare (see
"get_all_properties_as_perl_str()" and "get_all_properties_as_xml_str()").

=head2 get_all_properties_as_perl_str([ NO_INDENTS ])

	$perl_code_str = $container->get_all_properties_as_perl_str();
	$perl_code_str = $container->get_all_properties_as_perl_str( 1 );
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

=head2 get_all_properties_as_xml_str([ NO_INDENTS ])

	$xml_doc_str = $container->get_all_properties_as_xml_str();
	$xml_doc_str = $container->get_all_properties_as_xml_str( 1 );
	$xml_doc_str = $node->get_all_properties_as_xml_str();
	$xml_doc_str = $node->get_all_properties_as_xml_str( 1 );

This method is a wrapper for get_all_properties() that serializes its output
into a pretty-printed string of XML, suitable for humans to read. By default,
child nodes are indented under their parent nodes (easier to read); if the
optional boolean argument NO_INDENTS is true, then all output lines will be
flush with the left, saving a fair amount of memory in what the resulting
string consumes.  (That said, even the indents are tabs, which take up much
less space than multiple spaces per indent level.)

=head1 INFORMATION FUNCTIONS AND METHODS

These "getter" functions/methods are all intended for use by programs that want
to dynamically interface with SQL::ObjectModel, especially those programs that
will generate a user interface for manual editing of data stored in or accessed
through SQL::ObjectModel constructs.  It will allow such programs to continue
working without many changes while SQL::SyntaxModel itself continues to evolve.
In a manner of speaking, these functions/methods let a caller program query as
to what 'schema' or 'business logic' drive this class.  These functions/methods
are all deterministic and stateless; they can be used in any context and will
always give the same answers from the same arguments, and no object properties
are used.  You can invoke them from any kind of object that SQL::ObjectModel
implements, or straight off of the class name itself, like a 'static' method.  
All of these functions return the undefined value if they match nothing.

=head2 valid_enumerated_types([ ENUM_TYPE ])

This function by default returns a list of the valid enumerated types that
SQL::SyntaxModel recognizes; if the optional ENUM_TYPE argument is given, it
just returns true if that matches a valid type, and false otherwise.

=head2 valid_enumerated_type_values( ENUM_TYPE[, ENUM_VALUE] )

This function by default returns a list of the values that SQL::SyntaxModel
recognizes for the enumerated type given in the ENUM_TYPE argument; if the
optional ENUM_VALUE argument is given, it just returns true if that matches an
allowed value, and false otherwise.

=head2 valid_node_types([ NODE_TYPE ])

This function by default returns a list of the valid Node Types that
SQL::SyntaxModel recognizes; if the optional NODE_TYPE argument is given, it
just returns true if that matches a valid type, and false otherwise.

=head2 valid_node_type_literal_attributes( NODE_TYPE[, ATTR_NAME] )

This function by default returns a Hash ref where the keys are the names of the
literal attributes that SQL::SyntaxModel recognizes for the Node Type given in
the NODE_TYPE argument, and where the values are the literal data types that
values for those attributes must be; if the optional ATTR_NAME argument is
given, it just returns the literal data type for the named attribute.

=head2 valid_node_type_enumerated_attributes( NODE_TYPE[, ATTR_NAME] )

This function by default returns a Hash ref where the keys are the names of the
enumerated attributes that SQL::SyntaxModel recognizes for the Node Type given
in the NODE_TYPE argument, and where the values are the enumerated data types
that values for those attributes must be; if the optional ATTR_NAME argument is
given, it just returns the enumerated data type for the named attribute.

=head2 valid_node_type_node_attributes( NODE_TYPE[, ATTR_NAME] )

This function by default returns a Hash ref where the keys are the names of the
node attributes that SQL::SyntaxModel recognizes for the Node Type given in the
NODE_TYPE argument, and where the values are the Node Types that values for
those attributes must be; if the optional ATTR_NAME argument is given, it just
returns the Node Type for the named attribute.

=head2 valid_node_type_parent_attribute_names( NODE_TYPE[, ATTR_NAME] )

This function by default returns an Array ref which lists the names of the node
attributes that are allowed to reference the primary parent of a Node whose
type is specified in the NODE_TYPE argument; if the optional ATTR_NAME argument
is given, it just returns true the named attribute may reference the primary
parent of a NODE_TYPE Node.

=head2 node_types_with_pseudonode_parents([ NODE_TYPE ])

This function by default returns a Hash ref where the keys are the names of the
Node Types whose primary parents can only be pseudo-nodes, and where the values
name the pseudo-nodes they are the children of; if the optional NODE_TYPE
argument is given, it just returns the pseudo-node for that Node Type.

=head2 mandatory_node_type_literal_attribute_names( NODE_TYPE[, ATTR_NAME] )

This function by default returns a list of the mandatory literal attributes of
the Node Type specified in the NODE_TYPE argument; if the optional ATR_NAME
argument is given, it just returns true if that attribute is mandatory.

=head2 mandatory_node_type_enumerated_attribute_names( NODE_TYPE[, ATTR_NAME] )

This function by default returns a list of the mandatory enumerated attributes
of the Node Type specified in the NODE_TYPE argument; if the optional ATR_NAME
argument is given, it just returns true if that attribute is mandatory.

=head2 mandatory_node_type_node_attribute_names( NODE_TYPE[, ATTR_NAME] )

This function by default returns a list of the mandatory node attributes of the
Node Type specified in the NODE_TYPE argument; if the optional ATR_NAME
argument is given, it just returns true if that attribute is mandatory.

=head2 major_type_of_node_type_attribute( NODE_TYPE, ATTR_NAME )

This function returns the major type for the attribute of NODE_TYPE Nodes named
ATTR_NAME, which is one of 'ID', 'LITERAL', 'ENUM' or 'NODE'.

=head1 SHORT-LIFE DEPRECATED METHODS AND METHOD FEATURES

The following few "methods" were officially renamed or replaced between 
SQL::SyntaxModel versions 0.06 and 0.07; aliases or emulators of them are being 
kept temporarily so that I can use the exact same testing and example code in 
0.07 as I did in 0.06.  Expect these to go away, and the test/example code be 
updated to use the newer API, within the next 2 module releases.

=head2 Container->create_node( ... )

This is an alias for Container->create_node_tree( ... ); use that instead.

=head2 Container->create_nodes( LIST )

This is an alias for Container->create_node_trees( LIST ); use that instead.

=head2 Container->get_root_node()

In SQL::SyntaxModel 0.06, the 4 pseudo-nodes had actual Node objects
representing them; you would have used this method to get a reference to the
'root' Node.  One reason to do this is that the get_all_properties() functions
were only invokable from Node objects in 0.06, and you used 'root' to output
all Nodes at once, such as in the CONTRIVED EXAMPLE code.  In SQL::SyntaxModel
0.07, the pseudo-nodes no longer exist as Node objects, and can not be invoked
or retrieved anywhere.  Now that you can invoke get_all_properties() et al from
a Container, the pseudo-nodes only exist within the context of their output, as
a way of organizing it, and nowhere else.  Currently, Container->get_root_node() 
will actually return a reference to the same Container it was invoked from, so 
that the code "Container->get_root_node()->get_all_properties[/*]()" will 
produce the same output in 0.07 as in 0.06.

=head2 Node->collect_inherited_attributes()

The above method appeared first in 0.07 along with many others when the few
large and complicated methods of 0.06 were split into the many smaller and
simpler methods of 0.07.  The method will be removed in a near-future release
because SQL::SyntaxModel will no longer support the feature it implements.
Specifically, inherited attributes that are copied to child Nodes from their
parents will cease to exist as a concept.  Instead, such information will be
stored in only the parent Nodes (cutting down on duplication).

=head2 Node->add_child_node( NEW_CHILD )

The above method from 0.06 has been split into two methods for 0.07; the new
version of the above name expects to be given a Node object as its argument;
the other method is Node->create_child_node_tree( NEW_CHILD ), which takes a
Hash ref as its argument.  The old add_child_node took both kinds of input; the
new version has a deprecated feature in which it will temporarily call
create_child_node_tree if its input is not a Node object; later it will throw a
bad-input exception instead.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that I am
certain parts of it will be changed in the near future, some in incompatible
ways.  This module will indeed execute and do a variety of things, but it isn't
yet recommended for any kind of serious use.  The current state is analagous to
'developer releases' of operating systems; you can study it with the intent of
using it in the future, but you should hold off writing any volume of code
against it which you aren't prepared to rewrite later as the API changes. 
Also, the module hasn't been tested as much as I would like, but it has tested
the more commonly used areas.  All of the code in the CONTRIVED EXAMPLE section
has been executed, which tests most internal functions and data.  All of this 
said, I plan to move this module into alpha development status within the next 
few releases, once I start using it in a production environment myself.

Some basic types of SQL or functionality that this module is supposed to
implement are not written yet; these correspond mostly to functionality that is
also lacking a description in DataDictionary.pod.  The mainly affected areas
are: applications, commands, command variables.  In addition, trying to declare
a view inside another view or a block probably won't work, as the currently
implemented rule set says they can only be declared as children of namespaces.
Related to this, some or all of the views that are shown in the CONTRIVED
EXAMPLE (and test script) would actually be declared in the application space
rather than the database space, because these views would not be stored in the
database, but rather be used as select-statements.  In fact, the 'command_var'
expression type used in some views would only work in an application-called
select, as those correspond to caller bind variables.  That said, updating this
module and DataDictionary.pod to add the functionality is in my almost-first 
to-do priority.

The 'Container' object that you work with when you call a Node's
get_container() or put_in_container() methods is not the same type of object
that you get when calling SQL::SyntaxModel->new().  The first is an actual
Container, and the second is a special thin wrapper object called 'Model' which
makes sure the Container object inside is auto-garbage-collected properly.  The
situation is that every Node living in a Container has a reference to the
Container object, which itself has references to the Nodes.  Also, the Nodes
inside Containers can have circular Perl references to each other
(parent-to-child and child-to-parent).  The Model object has a Perl reference
to its Container, but the Container does not refer back.  This means that when
references to the Model go away, its DESTROY() method will break all the
circular Perl refs mentioned above so they are also garbage collected properly.

What this also means is, if you lose your reference to the Model object while 
still holding references to any Container objects, those objects will become 
invalid, as they get destroyed when the Model is garbage-collected.  So with 
the current version of this class you must keep a hold on what new() gives you.

Now, one way to eliminate this not-the-same-object problem is to require users
of SQL::SyntaxModel to explicitely call a Container's destructor method before
tossing the reference to it, such as how C does things.  But then explicit
destruction of in-memory data structures isn't so Perlish.  Note that once the
core is reimplemented in C and the Perl is just a wrapper, there will no longer
be any Perl circular references, so the object can be auto-destructed without
the current compatability issues.

This module currently does not prevent the user from creating circular virtual
references between Nodes, such as "A is the child of B and B is the child of
A"; however, only a few types of Nodes (such as 'view' and 'block' and
'*_expr') even make this possible.

=head1 SEE ALSO

perl(1), SQL::SyntaxModel::DataDictionary, SQL::SyntaxModel::XMLSchema,
SQL::SyntaxModel::API_C, SQL::SyntaxModel::SkipID, Rosetta, Rosetta::Framework,
DBI, SQL::Statement, SQL::Translator, SQL::YASP, SQL::Generator, SQL::Schema,
SQL::Abstract, SQL::Snippet, SQL::Catalog, DB::Ent, DBIx::Abstract,
DBIx::AnyDBD, DBIx::DBSchema, DBIx::Namespace, DBIx::SearchBuilder,
TripleStore.

=head1 CONTRIVED EXAMPLE

The following demonstrates input that can be provided to SQL::SyntaxModel,
along with a way to debug the result; it is a contrived example since the class
normally wouldn't get used this way.  This code is exactly the same (except for
framing) as that run by this module's current test script.

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

	print $model->get_root_node()->get_all_properties_as_xml_str();

=cut
