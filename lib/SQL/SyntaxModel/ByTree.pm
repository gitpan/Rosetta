=head1 NAME

SQL::SyntaxModel::ByTree - Build SQL::SyntaxModels from multi-dimensional Perl hashes and arrays

=cut

######################################################################

package SQL::SyntaxModel::ByTree;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.09';

use SQL::SyntaxModel 0.09;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	SQL::SyntaxModel 0.08 (parent class)

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

# This is an extension to let you use one set of functions for all Node 
# attribute major types, rather than separate literal/enumerated/node.
my $NAMT_ID      = 'ID'; # node id attribute
my $NAMT_LITERAL = 'LITERAL'; # literal attribute
my $NAMT_ENUM    = 'ENUM'; # enumerated attribute
my $NAMT_NODE    = 'NODE'; # node attribute
my $ATTR_ID      = 'id'; # attribute name to use for the node id

# These named arguments are used with the create_[/child_]node_tree[/s]() methods:
my $ARG_NODE_TYPE = 'NODE_TYPE'; # str - what type of Node we are
my $ARG_ATTRS     = 'ATTRS'; # hash - our attributes, including refs/ids of parents we will have
my $ARG_CHILDREN  = 'CHILDREN'; # list of refs to new Nodes we will become primary parent of

######################################################################

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

sub major_type_of_node_type_attribute {
	my ($self, $type, $attr) = @_;
	($type and $self->valid_node_types( $type )) or return( undef );
	defined( $attr ) or return( undef );
	$attr eq $ATTR_ID and return( $NAMT_ID );
	if( $self->valid_node_type_literal_attributes( $type, $attr ) ) {
		return( $NAMT_LITERAL );
	}
	if( $self->valid_node_type_enumerated_attributes( $type, $attr ) ) {
		return( $NAMT_ENUM );
	}
	if( $self->valid_node_type_node_attributes( $type, $attr ) ) {
		return( $NAMT_NODE );
	}
	return( undef );
}

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
SQL::SyntaxModel::ByTree::_::Node;
#use base qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel::_::Node );
use vars qw( @ISA );
@ISA = qw( SQL::SyntaxModel::ByTree::_::Shared SQL::SyntaxModel::_::Node );

######################################################################

sub expected_attribute_major_type {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SSMBTR_N_EXP_AT_MT_NO_ARGS' );
	my $node_type = $node->get_node_type();
	my $namt = $node->major_type_of_node_type_attribute( $node_type, $attr_name );
	unless( $namt ) {
		$node->_throw_error_message( 'SSMBTR_N_EXP_AT_MT_INVAL_NM', 
			{ 'NAME' => $attr_name, 'HOSTTYPE' => $node_type } );
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
	defined( $attrs ) or $node->_throw_error_message( 'SSMBTR_N_SET_ATS_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SSMBTR_N_SET_ATS_BAD_ARGS', { 'ARG' => $attrs } );
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

sub collect_inherited_attributes {
	# this function is deprecated; inherited attributes that are 
	# copied to child nodes will cease to exist as a concept next time
	my ($node) = @_;

	my $node_type = $node->get_node_type();
	my $psn_atnm = ($node_type eq 'view_col_def') ? 'p_expr' : 
		($node_type eq 'view_part_def') ? 'p_expr' : undef;
	my $inh_attrs = ($node_type eq 'view_col_def') ? [qw( view_col rowset )] : 
		($node_type eq 'view_part_def') ? [qw( rowset view_part )] : undef;

	if( $inh_attrs ) {
		my $parent = $node->get_node_attribute( $psn_atnm ); # assumes Node is in Container now
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

	$new_child->collect_inherited_attributes();
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
	$node->collect_inherited_attributes();
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

One significant added feature, this module's name-sake, is that you can create
a Node, set all of its attributes, put it in a Container, and likewise
recursively create all of its child Nodes, all with a single method call.  In
the context of this module, the set of Nodes consisting of one starting Node
and all of its "descendants" is called a "tree".  You can create a tree of
Nodes in mainly two contexts; one context will assign the starting Node of the
new tree as a child of an already existing Node; the other will not attach the
tree to an existing Node.

Another added feature is that you can, at the same time as building Nodes
piecemeal in the normal parent class fashion, access Node attributes without
having to know what type of attribute they are.  The parent class defines
separate accessor methods for 'literal' and 'enumerated' and 'node' attributes;
SQL::SyntaxModel::ByTree allows you to use one set of accessors instead, at the
cost of being slower.  In this context, the Node Id can also be set and read
using the same accessor methods, using the attribute name of 'id'.

This module also implements a depreated feature with the method 
collect_inherited_attributes(), but that will go away in a couple releases.

=head1 CONTAINER OBJECT METHODS

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

=head1 INFORMATION FUNCTIONS AND METHODS

=head2 major_type_of_node_type_attribute( NODE_TYPE, ATTR_NAME )

This "getter" function returns the major type for the attribute of NODE_TYPE
Nodes named ATTR_NAME, which is one of 'ID', 'LITERAL', 'ENUM' or 'NODE'.

=head1 SHORT-LIFE DEPRECATED METHODS

=head2 collect_inherited_attributes()

This Node method appeared first in 0.07 along with many others when the few
large and complicated methods of 0.06 were split into the many smaller and
simpler methods of 0.07.  The method will be removed in a near-future release
because SQL::SyntaxModel will no longer support the feature it implements.
Specifically, inherited attributes that are copied to child Nodes from their
parents will cease to exist as a concept.  Instead, such information will be
stored in only the parent Nodes (cutting down on duplication).

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

	$model->create_node_trees( [ map { { 'NODE_TYPE' => 'data_type', 'ATTRS' => $_ } } (
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

	my $database = $model->create_node_tree( { 'NODE_TYPE' => 'database', 'ATTRS' => { 'id' => 1, } } ); 

	my $namespace = $database->create_child_node_tree( { 'NODE_TYPE' => 'namespace', 'ATTRS' => { 'id' => 1, } } ); 

	my $tbl_person = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'table', 
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

	my $vw_person = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 4, 
			'name' => 'person', 'may_write' => 1, 'view_type' => 'caller', 'match_table' => 4 }, } );

	my $vw_person_with_parents = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 2, 
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

	my $tbl_user_auth = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'table', 
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

	my $tbl_user_profile = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'table', 
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

	my $vw_user = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 1, 
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

	my $tbl_user_pref = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'table', 
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

	my $vw_user_theme = $namespace->create_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 3, 
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

	print $model->get_all_properties_as_xml_str();

=cut
