=head1 NAME

SQL::SyntaxModel::ByTree - Build SQL::SyntaxModels from multi-dimensional Perl hashes and arrays

=cut

######################################################################

package SQL::SyntaxModel::ByTree;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.11';

use SQL::SyntaxModel 0.11;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	SQL::SyntaxModel 0.11 (parent class)

=head1 COPYRIGHT AND LICENSE

This file is an optional part of the SQL::SyntaxModel library (libSQLSM).

SQL::SyntaxModel is Copyright (c) 1999-2004, Darren R. Duncan.  All rights
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
SQL::SyntaxModel::ByTree::_::Shared; # has no properties, subclassed by main and Container and Node
use base qw( SQL::SyntaxModel::_::Shared );

######################################################################

# These are duplicate declarations of some properties in the SQL::SyntaxModel parent class.
my $MPROP_CONTAINER   = 'container';

# These named arguments are used with the create_[/child_]node_tree[/s]() methods:
my $ARG_NODE_TYPE = 'NODE_TYPE'; # str - what type of Node we are
my $ARG_ATTRS     = 'ATTRS'; # hash - our attributes, including refs/ids of parents we will have
my $ARG_CHILDREN  = 'CHILDREN'; # list of refs to new Nodes we will become primary parent of

######################################################################

sub _get_static_const_model_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'SQL::SyntaxModel::ByTree' );
}

sub _get_static_const_container_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'SQL::SyntaxModel::ByTree::_::Container' );
}

sub _get_static_const_node_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'SQL::SyntaxModel::ByTree::_::Node' );
}

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::ByTree::_::Node;
#use base qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel::_::Node );
use vars qw( @ISA );
@ISA = qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel::_::Node );

######################################################################

sub create_child_node_tree {
	my ($node, $args) = @_;
	defined( $args ) or $node->_throw_error_message( 'SSMBTR_N_CR_NODE_TREE_NO_ARGS' );

	unless( ref($args) eq 'HASH' ) {
		$node->_throw_error_message( 'SSMBTR_N_CR_NODE_TREE_BAD_ARGS', { 'ARG' => $args } );
	}

	my $new_child = $node->create_empty_node( $args->{$ARG_NODE_TYPE} );
	$new_child->set_attributes( $args->{$ARG_ATTRS} ); # handles node id and all attribute types
	$new_child->put_in_container( $node->get_container() );
	$new_child->add_reciprocal_links();

	$node->add_child_node( $new_child ); # sets more attributes in new_child

	$new_child->test_mandatory_attributes();
	$new_child->create_child_node_trees( $args->{$ARG_CHILDREN} );

	return( $new_child );
}

sub create_child_node_trees {
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
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::ByTree::_::Container;
#use base qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel::_::Container );
use vars qw( @ISA );
@ISA = qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel::_::Container );

######################################################################

sub create_node_tree {
	my ($container, $args) = @_;
	defined( $args ) or $container->_throw_error_message( 'SSMBTR_C_CR_NODE_TREE_NO_ARGS' );

	unless( ref($args) eq 'HASH' ) {
		$container->_throw_error_message( 'SSMBTR_C_CR_NODE_TREE_BAD_ARGS', { 'ARG' => $args } );
	}

	my $node = $container->create_empty_node( $args->{$ARG_NODE_TYPE} );
	$node->set_attributes( $args->{$ARG_ATTRS} ); # handles node id and all attribute types
	$node->put_in_container( $container );
	$node->add_reciprocal_links();
	$node->test_mandatory_attributes();
	$node->create_child_node_trees( $args->{$ARG_CHILDREN} );

	return( $node );
}

sub create_node_trees {
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
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::ByTree;
#use base qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel );
use vars qw( @ISA );
@ISA = qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel );

######################################################################

sub create_node_tree {
	return( $_[0]->{$MPROP_CONTAINER}->create_node_tree( $_[1] ) );
}

sub create_node_trees {
	$_[0]->{$MPROP_CONTAINER}->create_node_trees( $_[1] );
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<See the CONTRIVED EXAMPLE documentation section at the end.>

=head1 DESCRIPTION

The SQL::SyntaxModel::ByTree Perl 5 object class is a completely optional
extension to SQL::SyntaxModel, and is implemented as a sub-class of that
module.  This module adds a set of new public methods which you can use to make
some tasks involving SQL::SyntaxModel less labour-intensive, depending on how
you like to use the module.  

This module is fully parent-compatible.  It does not override any parent class
methods or otherwise change how it works; if you use only methods defined in
the parent class, this module will behave identically.  All of the added
methods are wrappers over existing parent class methods, and this module does
not define any new properties.

This module's added feature, which is its name-sake, is that you can create
a Node, set all of its attributes, put it in a Container, and likewise
recursively create all of its child Nodes, all with a single method call.  In
the context of this module, the set of Nodes consisting of one starting Node
and all of its "descendants" is called a "tree".  You can create a tree of
Nodes in mainly two contexts; one context will assign the starting Node of the
new tree as a child of an already existing Node; the other will not attach the
tree to an existing Node.

=head1 CONTAINER OBJECT METHODS

=head2 create_node_tree( { NODE_TYPE[, ATTRS][, CHILDREN] } )

	my $node = $model->create_node_tree( 
		{ 'NODE_TYPE' => 'catalog', 'ATTRS' => { 'id' => 1, } } ); 

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

=head2 create_child_node_tree( { NODE_TYPE[, ATTRS][, CHILDREN] } )

	my $new_child = $node->add_child_node( 
		{ 'NODE_TYPE' => 'schema', 'ATTRS' => { 'id' => 1, } } ); 

This "setter" method will create a new Node, following the same semantics (and
taking the same arguments) as the Container->create_node_tree(), except that 
create_child_node_tree() will also set the primary parent of the new Node to 
be the current Node.  This method also returns the new child Node.

=head2 create_child_node_trees( LIST )

	$model->create_child_node_tree( [$child1,$child2] );
	$model->create_child_node_tree( $child );

This "setter" method takes an array ref in its single LIST argument, and calls
create_child_node_tree() for each element found in it.

=head1 BUGS

First of all, see the BUGS main documentation section of the SQL::SyntaxModel,
as everything said there applies to this module also.  Exceptions are below.

The "use base ..." pragma doesn't seem to work properly (with Perl 5.6 at
least) when I want to inherit from multiple classes, with some required parent
class methods not being seen; I had to use the analagous "use vars @ISA; @ISA =
..." syntax instead.

=head1 SEE ALSO

SQL::SyntaxModel::ByTree::L::*, SQL::SyntaxModel, and other items in its SEE
ALSO documentation.

=head1 CONTRIVED EXAMPLE

The following demonstrates input that can be provided to
SQL::SyntaxModel::ByTree, along with a way to debug the result; it is a
contrived example since the class normally wouldn't get used this way.  This
code is exactly the same (except for framing) as that run by this module's
current test script.

	use strict;
	use warnings;

	use SQL::SyntaxModel::ByTree;

	my $model = SQL::SyntaxModel::ByTree->new();

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

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 4, 'routine_type' => 'ANONYMOUS', 'name' => 'person', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 4, 'view_context' => 'APPLIC', 'view_type' => 'MATCH', 
			'may_write' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 7, 'name' => 'person', 'match_table' => 4, }, },
		] }
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 2, 'routine_type' => 'ANONYMOUS', 'name' => 'person_with_parents', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 2, 'name' => 'srchw_fa', }, },
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 3, 'name' => 'srchw_mo', }, },
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 2, 'view_context' => 'APPLIC', 'view_type' => 'MULTIPLE', 
				'may_write' => 0, }, 'CHILDREN' => [ 
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
				{ 'id' => 16, 'name' => 'self_id'    , 'domain' =>  9, },
				{ 'id' => 17, 'name' => 'self_name'  , 'domain' => 24, },
				{ 'id' => 18, 'name' => 'father_id'  , 'domain' =>  9, },
				{ 'id' => 19, 'name' => 'father_name', 'domain' => 24, },
				{ 'id' => 20, 'name' => 'mother_id'  , 'domain' =>  9, },
				{ 'id' => 21, 'name' => 'mother_name', 'domain' => 24, },
			) ),
			{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 2, 'lhs_src' => 3, 
					'rhs_src' => 4, 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 2, 'lhs_src_col' => 25, 'rhs_src_col' => 19, } },
			] },
			{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 3, 'lhs_src' => 3, 
					'rhs_src' => 5, 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 3, 'lhs_src_col' => 26, 'rhs_src_col' => 21, } },
			] },
			( map { { 'NODE_TYPE' => 'view_expr', 'ATTRS' => $_ } } (
				{ 'view_part' => 'RESULT', 'id' => 36, 'view_col' => 16, 'expr_type' => 'COL', 'src_col' => 17, },
				{ 'view_part' => 'RESULT', 'id' => 37, 'view_col' => 17, 'expr_type' => 'COL', 'src_col' => 18, },
				{ 'view_part' => 'RESULT', 'id' => 38, 'view_col' => 18, 'expr_type' => 'COL', 'src_col' => 19, },
				{ 'view_part' => 'RESULT', 'id' => 39, 'view_col' => 19, 'expr_type' => 'COL', 'src_col' => 20, },
				{ 'view_part' => 'RESULT', 'id' => 40, 'view_col' => 20, 'expr_type' => 'COL', 'src_col' => 21, },
				{ 'view_part' => 'RESULT', 'id' => 41, 'view_col' => 21, 'expr_type' => 'COL', 'src_col' => 22, },
			) ),
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
					'id' => 4, 'expr_type' => 'SFUNC', 'sfunc' => 'AND', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 5, 'expr_type' => 'SFUNC', 'sfunc' => 'LIKE', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 6, 'expr_type' => 'COL', 'src_col' => 20, }, },
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 7, 'expr_type' => 'VAR', 'routine_arg' => 2, }, },
				] },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 8, 'expr_type' => 'SFUNC', 'sfunc' => 'LIKE', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 9, 'expr_type' => 'COL', 'src_col' => 22, }, },
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 10, 'expr_type' => 'VAR', 'routine_arg' => 3, }, },
				] },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 52, 'expr_type' => 'MCOL', 'match_col' => 17, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 53, 'expr_type' => 'MCOL', 'match_col' => 19, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 54, 'expr_type' => 'MCOL', 'match_col' => 21, }, },
		] },
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 1, 'routine_type' => 'ANONYMOUS', 'name' => 'user', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 1, 'name' => 'curr_uid', }, },
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 1, 'view_context' => 'APPLIC', 'view_type' => 'MULTIPLE', 
				'may_write' => 1, }, 'CHILDREN' => [ 
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
				{ 'id' =>  1, 'name' => 'user_id'      , 'domain' =>  9, },
				{ 'id' =>  2, 'name' => 'login_name'   , 'domain' => 23, },
				{ 'id' =>  3, 'name' => 'login_pass'   , 'domain' => 23, },
				{ 'id' =>  4, 'name' => 'private_name' , 'domain' => 24, },
				{ 'id' =>  5, 'name' => 'private_email', 'domain' => 24, },
				{ 'id' =>  6, 'name' => 'may_login'    , 'domain' => 19, },
				{ 'id' =>  7, 'name' => 'max_sessions' , 'domain' =>  7, },
				{ 'id' =>  8, 'name' => 'public_name'  , 'domain' => 25, },
				{ 'id' =>  9, 'name' => 'public_email' , 'domain' => 25, },
				{ 'id' => 10, 'name' => 'web_url'      , 'domain' => 25, },
				{ 'id' => 11, 'name' => 'contact_net'  , 'domain' => 25, },
				{ 'id' => 12, 'name' => 'contact_phy'  , 'domain' => 25, },
				{ 'id' => 13, 'name' => 'bio'          , 'domain' => 25, },
				{ 'id' => 14, 'name' => 'plan'         , 'domain' => 25, },
				{ 'id' => 15, 'name' => 'comments'     , 'domain' => 25, },
			) ),
			{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 1, 'lhs_src' => 1, 
					'rhs_src' => 2, 'join_type' => 'LEFT', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_join_col', 'ATTRS' => { 'id' => 1, 'lhs_src_col' => 1, 'rhs_src_col' => 8, } },
			] },
			( map { { 'NODE_TYPE' => 'view_expr', 'ATTRS' => $_ } } (
				{ 'view_part' => 'RESULT', 'id' => 21, 'view_col' =>  1, 'expr_type' => 'COL', 'src_col' =>  1, },
				{ 'view_part' => 'RESULT', 'id' => 22, 'view_col' =>  2, 'expr_type' => 'COL', 'src_col' =>  2, },
				{ 'view_part' => 'RESULT', 'id' => 23, 'view_col' =>  3, 'expr_type' => 'COL', 'src_col' =>  3, },
				{ 'view_part' => 'RESULT', 'id' => 24, 'view_col' =>  4, 'expr_type' => 'COL', 'src_col' =>  4, },
				{ 'view_part' => 'RESULT', 'id' => 25, 'view_col' =>  5, 'expr_type' => 'COL', 'src_col' =>  5, },
				{ 'view_part' => 'RESULT', 'id' => 26, 'view_col' =>  6, 'expr_type' => 'COL', 'src_col' =>  6, },
				{ 'view_part' => 'RESULT', 'id' => 27, 'view_col' =>  7, 'expr_type' => 'COL', 'src_col' =>  7, },
				{ 'view_part' => 'RESULT', 'id' => 28, 'view_col' =>  8, 'expr_type' => 'COL', 'src_col' =>  9, },
				{ 'view_part' => 'RESULT', 'id' => 29, 'view_col' =>  9, 'expr_type' => 'COL', 'src_col' => 10, },
				{ 'view_part' => 'RESULT', 'id' => 30, 'view_col' => 10, 'expr_type' => 'COL', 'src_col' => 11, },
				{ 'view_part' => 'RESULT', 'id' => 31, 'view_col' => 11, 'expr_type' => 'COL', 'src_col' => 12, },
				{ 'view_part' => 'RESULT', 'id' => 32, 'view_col' => 12, 'expr_type' => 'COL', 'src_col' => 13, },
				{ 'view_part' => 'RESULT', 'id' => 33, 'view_col' => 13, 'expr_type' => 'COL', 'src_col' => 14, },
				{ 'view_part' => 'RESULT', 'id' => 34, 'view_col' => 14, 'expr_type' => 'COL', 'src_col' => 15, },
				{ 'view_part' => 'RESULT', 'id' => 35, 'view_col' => 15, 'expr_type' => 'COL', 'src_col' => 16, },
			) ),
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
					'id' => 1, 'expr_type' => 'SFUNC', 'sfunc' => 'EQ', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'id' => 2, 'expr_type' => 'COL', 'src_col' => 1, }, },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'id' => 3, 'expr_type' => 'VAR', 'routine_arg' => 1, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 51, 'expr_type' => 'MCOL', 'match_col' => 2, }, },
		] },
	] } );

	$application->create_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 3, 'routine_type' => 'ANONYMOUS', 'name' => 'user_theme', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 3, 'view_context' => 'APPLIC', 'view_type' => 'SINGLE', 
				'may_write' => 0, }, 'CHILDREN' => [ 
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
		] },
	] } );

	print $model->get_all_properties_as_xml_str();

=cut
