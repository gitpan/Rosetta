=head1 NAME

Rosetta - Rigorous database portability

=cut

######################################################################

package Rosetta;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.35';

use Locale::KeyedText 0.07;
use SQL::SyntaxModel 0.41;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Locale::KeyedText 0.07 (for error messages)
	SQL::SyntaxModel 0.41

=head1 COPYRIGHT AND LICENSE

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>, or
visit "http://www.DarrenDuncan.net" for more information.

Rosetta is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License (GPL) version 2 as published by the
Free Software Foundation (http://www.fsf.org/).  You should have received a
copy of the GPL as part of the Rosetta distribution, in the file named
"LICENSE"; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA 02111-1307 USA.

Linking Rosetta statically or dynamically with other modules is making a
combined work based on Rosetta.  Thus, the terms and conditions of the GPL
cover the whole combination.  As a special exception, the copyright holders of
Rosetta give you permission to link Rosetta with independent modules,
regardless of the license terms of these independent modules, and to copy and
distribute the resulting combined work under terms of your choice, provided
that every copy of the combined work is accompanied by a complete copy of the
source code of Rosetta (the version of Rosetta used to produce the combined
work), being distributed under the terms of the GPL plus this exception.  An
independent module is a module which is not derived from or based on Rosetta,
and which is fully useable when not linked to Rosetta in any form.

Any versions of Rosetta that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits.
Rosetta is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of
suggesting improvements to the standard version.

=cut

######################################################################
######################################################################

# Names of properties for objects of the Rosetta::Interface class are declared here:
my $IPROP_INTF_TYPE = 'intf_type'; # str (enum) - what type of Interface this is, no chg once set
	# The Interface Type is the only property which absolutely can not change, and is set when object created.
my $IPROP_ERROR_MSG = 'error_msg'; # object (Locale::KeyedText::Message) - details of a 
	# failure, or at least any that might be useful to a generic application error handler; 
	# if there was no error condition, then this is undefined/null
	# This property is mandatory for Error Interfaces, and optional for other Interfaces
my $IPROP_PARENT_INTF = 'parent_intf'; # ref to parent Interface, which provides a context 
	# for the current one, unless the current Interface is a root
my $IPROP_ROOT_INTF = 'root_intf'; # ref to Application Interface that is the root of this 
	# Intf's Interface tree; ref to self if self is an Appl, null if PARENT_INTF otherwise null.
	# This is a convenience property only, redundant with a chain of PARENT_INTF, used for speed.
my $IPROP_CHILD_INTFS = 'child_intfs'; # array - list of refs to child Interfaces that the 
	# current one spawned and provides a context for; this may or may not be useful in practice, 
	# and it does set up a circular ref problem such that all Interfaces in a tree will not be 
	# destroyed until their root Interface is, unless this is done explicitly
my $IPROP_ENGINE = 'engine'; # ref to Engine implementing this Interface if any
	# This Engine object would store its own state internally, which includes such things 
	# as various DBI dbh/sth/rv handles where appropriate, and any generated SQL to be 
	# generated, as well as knowledge of how to translate named host variables to positional ones.
	# The Engine object would never store a reference to the Interface object that it 
	# implements, as said Interface object would pass a reference to itself as an argument 
	# to any Engine methods that it invokes.  Of course, if this Engine implements a 
	# middle-layer and invokes another Interface/Engine tree of its own, then it would store 
	# a reference to that Interface like an application would.
my $IPROP_SSM_NODE = 'ssm_node'; # ref to SQL::SyntaxModel Node providing context for this Intf
	# If we are an 'Application' Interface, this would be an 'application_instance' Node.
	# If we are a 'Preparation' Interface, this would be a 'command' or 'routine' Node.
	# If we are any other kind of interface, this is a second ref to same SSM the parent 'prep' has.
my $IPROP_ROUTINE = 'routine'; # ref to a Perl anonymous subroutine; this property must be 
	# set for Preparation interfaces and must not be set for other types.
	# An Engine's prepare() method will create this sub when it creates a Preparation Interface.
	# When calling execute(), the Interface will simply invoke the sub; no Engine execute() called.

# Names of properties for objects of the Rosetta::Engine class are declared here:
	 # No properties (yet) are declared by this parent class; leaving space free for child classes

# Names of properties for objects of the Rosetta::Dispatcher class are declared here:
my $DPROP_LIT_PAYLOAD = 'lit_payload'; # If Eng fronts a Literal Intf, put payload it represents here.

# Names of the allowed Interface types go here:
my $INTFTP_ERROR       = 'Error'; # What is returned if an error happens, in place of another Intf type
my $INTFTP_TOMBSTONE   = 'Tombstone'; # What is returned when execute() destroys an Interface
my $INTFTP_APPLICATION = 'Application'; # What you get when you create an Interface out of any context
	# This type is the root of an Interface tree; when you create one, you provide an 
	# "application_instance" SQL::SyntaxModel Node; that provides the necessary context for 
	# subsequent "command" or "routine" Nodes you pass to any child Intf's "prepare" method.
my $INTFTP_PREPARATION = 'Preparation'; # That which is returned by the 'prepare()' method
my $INTFTP_LITERAL     = 'Literal'; # Result of execution that isn't one of the following, like an IUD
	# This type can be returned as the grand-child for any of [Appl, Envi, Conn, Tran].
	# This type is returned by the execute() of any Command that doesn't return one of 
	# the following 4 context INTFs, except for those that return Cursor.
	# Any commands that stuff new Nodes in the current SSM Container, such as the 
	# *_LIST or *_INFO or *_CLONE Commands, will return a new Node ref or list as the payload.
	# Any commands that simply do a yes/no test, such as *_VERIFY, or DB_PING, 
	# simply have a boolean payload.
	# IUD commands usually return this, plus method calls; payload may be a hash ref of results.
my $INTFTP_ENVIRONMENT = 'Environment'; # Parent to all Connection INTFs impl by same Engine
my $INTFTP_CONNECTION  = 'Connection'; # Result of executing a 'DB_OPEN' command
my $INTFTP_TRANSACTION = 'Transaction'; # Result of asking to start a new Transaction
my $INTFTP_CURSOR      = 'Cursor'; # Result of executing a query that would return rows to the caller
my %ALL_INTFTP = ( map { ($_ => 1) } (
	$INTFTP_ERROR, $INTFTP_TOMBSTONE, 
	$INTFTP_APPLICATION, $INTFTP_PREPARATION, $INTFTP_LITERAL, 
	$INTFTP_ENVIRONMENT, $INTFTP_CONNECTION, $INTFTP_TRANSACTION, $INTFTP_CURSOR, 
) );

# Names of all possible features that a Rosetta Engine can claim to support, 
# and that Rosetta::Validator will individually test for.
# This list may resemble SQL::SyntaxModel's "command_type" enumerated list in part, 
# but it is a lot more broad than that.
my %POSSIBLE_FEATURES = map { ($_ => 1) } qw(
	DB_LIST DB_INFO 

	CONN_BASIC 
	CONN_MULTI_SAME CONN_MULTI_DIFF 
	CONN_PING 
	TRAN_BASIC 
	TRAN_ROLLBACK_ON_DEATH 
	TRAN_MULTI_SIB TRAN_MULTI_CHILD 

	USER_LIST USER_INFO
	SCHEMA_LIST SCHEMA_INFO

	DOMAIN_LIST DOMAIN_INFO DOMAIN_DEFN_VERIFY 
	DOMAIN_DEFN_BASIC

	TABLE_LIST TABLE_INFO TABLE_DEFN_VERIFY
	TABLE_DEFN_BASIC
	TABLE_UKEY_BASIC TABLE_UKEY_MULTI
	TABLE_FKEY_BASIC TABLE_FKEY_MULTI

	QUERY_BASIC
	QUERY_SCHEMA_VIEW
	QUERY_RETURN_SPEC_COLS QUERY_RETURN_COL_EXPRS
	QUERY_WHERE
	QUERY_COMPARE_PRED QUERY_BOOLEAN_EXPR
	QUERY_NUMERIC_EXPR QUERY_STRING_EXPR QUERY_LIKE_PRED
	QUERY_JOIN_BASIC QUERY_JOIN_OUTER_LEFT QUERY_JOIN_ALL
	QUERY_GROUP_BY_NONE QUERY_GROUP_BY_SOME
	QUERY_AGG_CONCAT QUERY_AGG_EXIST
	QUERY_OLAP
	QUERY_HAVING
	QUERY_WINDOW_ORDER QUERY_WINDOW_LIMIT
	QUERY_COMPOUND
	QUERY_SUBQUERY
);

# Names of SQL::SyntaxModel-recognized enumerated values such as Node types go here:
my $SSMNTP_APPINST = 'application_instance';
my $SSMNTP_LINKPRD = 'data_link_product';
my $SSMNTP_COMMAND = 'command';
my $SSMNTP_ROUTINE = 'routine';

# These are SQL::SyntaxModel-recognized Command Types 
# that the Rosetta core explicitly deals with:
my $SSM_CMDTP_DB_LIST = 'DB_LIST';
my $SSM_CMDTP_DB_INFO = 'DB_INFO';
my $SSM_CMDTP_DB_OPEN = 'DB_OPEN';

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	# Throws an exception consisting of an object.
	die Locale::KeyedText->new_message( $error_code, $args );
}

######################################################################
# This is a convenience wrapper method; its sole argument is a SSM Node.

sub new_application {
	return( Rosetta::Interface->new( $INTFTP_APPLICATION, undef, undef, undef, $_[1] ) );
}

######################################################################
######################################################################

package Rosetta::Interface;
use base qw( Rosetta );

######################################################################

sub new {
	# Make a new Interface with basically all props set now and not changed later.
	my ($class, $intf_type, $err_msg, $parent_intf, $engine, $ssm_node, $routine) = @_;
	my $interface = bless( {}, ref($class) || $class );

	$interface->_validate_properties_to_be( 
		$intf_type, $err_msg, $parent_intf, $engine, $ssm_node, $routine );

	unless( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_TOMBSTONE ) {
		# If type was Application or Preparation, $ssm_node would already be set.
		# Anything else except Error and Tombstone has a parent.
		$ssm_node ||= $parent_intf->{$IPROP_SSM_NODE}; # Copy from parent Preparation if applicable.
	}
	$interface->{$IPROP_INTF_TYPE} = $intf_type;
	$interface->{$IPROP_ERROR_MSG} = $err_msg;
	$interface->{$IPROP_PARENT_INTF} = $parent_intf;
	$interface->{$IPROP_ROOT_INTF} = $parent_intf ? $parent_intf->{$IPROP_ROOT_INTF} : 
		($intf_type eq $INTFTP_APPLICATION) ? $interface : undef;
	$interface->{$IPROP_CHILD_INTFS} = [];
	$interface->{$IPROP_ENGINE} = ($intf_type eq $INTFTP_APPLICATION) ? 
		Rosetta::Dispatcher->new() : $engine;
	$interface->{$IPROP_SSM_NODE} = $ssm_node;
	$interface->{$IPROP_ROUTINE} = $routine;
	$parent_intf and push( @{$parent_intf->{$IPROP_CHILD_INTFS}}, $interface );

	return( $interface );
}

sub _validate_properties_to_be {
	my ($interface, $intf_type, $err_msg, $parent_intf, $engine, $ssm_node, $routine) = @_;

	# Check $intf_type, which is mandatory.
	defined( $intf_type ) or $interface->_throw_error_message( 'ROS_I_NEW_INTF_NO_TYPE' );
	unless( $ALL_INTFTP{$intf_type} ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_TYPE', { 'TYPE' => $intf_type } );
	}

	# Check $err_msg, which is not mandatory except when type is Error.
	if( defined( $err_msg ) ) {
		unless( ref($err_msg) and UNIVERSAL::isa( $err_msg, 'Locale::KeyedText::Message' ) ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_ERR', { 'ERR' => $err_msg } );
		}
	} else {
		$intf_type eq $INTFTP_ERROR and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_NO_ERR', { 'TYPE' => $intf_type } );
	}

	# Check $parent_intf, which must not be set when type is Error/Application, must be set otherwise.
	$interface->_validate_parent_intf( $intf_type, $parent_intf );

	# Check $engine, which must not be set when type is Error/Application, must be set otherwise.
	if( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_TOMBSTONE or $intf_type eq $INTFTP_APPLICATION ) {
		defined( $engine ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_ENG', { 'TYPE' => $intf_type } );
	} else {
		defined( $engine ) or $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_NO_ENG', { 'TYPE' => $intf_type } );
		unless( ref($engine) and UNIVERSAL::isa( $engine, 'Rosetta::Engine' ) ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_ENG', { 'ENG' => $engine } );
		}
	}

	# Check $ssm_node, must be given for Application or Preparation, 
	# must not be given otherwise (incl Error).  $ssm_node is always set to its 
	# parent Preparation when arg must not be given, except when Error.
	$interface->_validate_ssm_node( 'ROS_I_NEW_INTF', $intf_type, $ssm_node, $parent_intf );

	# Check $routine, which must be set when type is Preparation, must not be set otherwise.
	if( $intf_type eq $INTFTP_PREPARATION ) {
		defined( $routine ) or $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_NO_RTN', { 'TYPE' => $intf_type } );
		unless( ref($routine) eq 'CODE' ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_RTN', { 'RTN' => $routine } );
		}
	} else {
		defined( $routine ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_RTN', { 'TYPE' => $intf_type } );
	}

	# All properties to be seem to check out fine.
}

sub _validate_parent_intf {
	my ($interface, $intf_type, $parent_intf) = @_;

	if( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_TOMBSTONE or $intf_type eq $INTFTP_APPLICATION ) {
		defined( $parent_intf ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_PARENT', { 'TYPE' => $intf_type } );
		# $parent_intf seems to check out fine.
		return( 1 );
	}

	# First check that the given $parent_intf is an Interface at all.
	defined( $parent_intf ) or $interface->_throw_error_message( 
		'ROS_I_NEW_INTF_NO_PARENT', { 'TYPE' => $intf_type } );
	unless( ref($parent_intf) and UNIVERSAL::isa( $parent_intf, 'Rosetta::Interface' ) ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_PARENT', { 'PAR' => $parent_intf } );
	}
	my $p_intf_type = $parent_intf->{$IPROP_INTF_TYPE};

	# Now check that we may be a child of the given $parent_intf.
	if( $intf_type eq $INTFTP_PREPARATION ) {
		unless( $p_intf_type eq $INTFTP_APPLICATION or $p_intf_type eq $INTFTP_ENVIRONMENT or 
				$p_intf_type eq $INTFTP_CONNECTION or $p_intf_type eq $INTFTP_TRANSACTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_P_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type } );
		}
		return( 1 ); # Skip the other tests
	}
	unless( $p_intf_type eq $INTFTP_PREPARATION ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_P_INCOMP', 
			{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type } );
	}

	# If we get here then at the very least we have an 'Application' and 'Preparation' above us.
	# Now check that we may be a grand-child of the parent of the given $parent_intf.
	my $pp_intf_type = $parent_intf->{$IPROP_PARENT_INTF}->{$IPROP_INTF_TYPE};
	if( $intf_type eq $INTFTP_LITERAL ) {
		unless( $pp_intf_type eq $INTFTP_APPLICATION or $pp_intf_type eq $INTFTP_ENVIRONMENT 
				or $pp_intf_type eq $INTFTP_CONNECTION or $pp_intf_type eq $INTFTP_TRANSACTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} elsif( $intf_type eq $INTFTP_ENVIRONMENT ) {
		unless( $pp_intf_type eq $INTFTP_APPLICATION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} elsif( $intf_type eq $INTFTP_CONNECTION ) {
		unless( $pp_intf_type eq $INTFTP_ENVIRONMENT ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} elsif( $intf_type eq $INTFTP_TRANSACTION ) {
		unless( $pp_intf_type eq $INTFTP_CONNECTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} else { # $intf_type eq $INTFTP_CURSOR
		unless( $pp_intf_type eq $INTFTP_TRANSACTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	}

	# $parent_intf seems to check out fine.
}

sub _validate_ssm_node {
	my ($interface, $error_key_pfx, $intf_type, $ssm_node, $parent_intf) = @_;

	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_PREPARATION ) {
		defined( $ssm_node ) and $interface->_throw_error_message( 
			$error_key_pfx.'_YES_NODE', { 'TYPE' => $intf_type } );
		# $ssm_node seems to check out fine.
		return( 1 );
	}

	# If we get here, we have an APPLICATION or a PREPARATION.

	defined( $ssm_node ) or $interface->_throw_error_message( 
		$error_key_pfx.'_NO_NODE', { 'TYPE' => $intf_type } );
	unless( ref($ssm_node) and UNIVERSAL::isa( $ssm_node, 'SQL::SyntaxModel::Node' ) ) {
		$interface->_throw_error_message( $error_key_pfx.'_BAD_NODE', { 'SSM' => $ssm_node } );
	}
	my $given_container = $ssm_node->get_container();
	unless( $given_container ) {
		$interface->_throw_error_message( $error_key_pfx.'_NODE_NOT_IN_CONT' );
	}
	unless( $ssm_node->are_reciprocal_links() ) {
		$interface->_throw_error_message( $error_key_pfx.'_NODE_NOT_RECIP_LINKS' );
	}
	$given_container->assert_deferrable_constraints(); # SSM throws own exceptions on problem.
	if( $parent_intf ) {
		my $expected_container = $parent_intf->{$IPROP_SSM_NODE}->get_container();
		# Above line assumes parent Intf's Node not taken from Container since put in parent.
		if( $given_container ne $expected_container ) {
			$interface->_throw_error_message( $error_key_pfx.'_NODE_NOT_SAME_CONT' );
		}
	}

	my $node_type = $ssm_node->get_node_type();

	if( $intf_type eq $INTFTP_APPLICATION ) {
		unless( $node_type eq $SSMNTP_APPINST ) {
			$interface->_throw_error_message( $error_key_pfx.'_NODE_TYPE_NOT_SUPP', 
				{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type } );
		}
		# $ssm_node seems to check out fine.
		return( 1 );
	}

	# If we get here, we have a PREPARATION.

	unless( $node_type eq $SSMNTP_LINKPRD or $node_type eq $SSMNTP_COMMAND or $node_type eq $SSMNTP_ROUTINE ) {
		$interface->_throw_error_message( $error_key_pfx.'_NODE_TYPE_NOT_SUPP', 
			{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type } );
	}

	# $ssm_node seems to check out fine.
}

######################################################################

sub destroy {
	# Since we probably have circular refs, we must explicitly be destroyed.
	my ($interface) = @_;

	# For simplicity, require that caller destroys our children first.
	if( @{$interface->{$IPROP_CHILD_INTFS}} > 0 ) {
		$interface->_throw_error_message( 'ROS_I_DESTROY_HAS_CHILD' );
	}

	# First destroy Engine implementing ourself, if we have one and it is willing.
	if( $interface->{$IPROP_ENGINE} ) {
		eval {
			$interface->{$IPROP_ENGINE}->destroy( $interface ); # may throw exception of its own
		};
		if( my $exception = $@ ) {
			my $intf_type = $interface->{$IPROP_INTF_TYPE};
			unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
				$interface->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
					{ 'METH' => 'destroy', 'CLASS' => ref($interface->{$IPROP_ENGINE}), 
					'ITYPE' => $intf_type, 'VALUE' => $exception } );
			}
		}
	}

	# Now break link from our parent Interface to ourself, if we have a parent.
	if( my $parent = $interface->{$IPROP_PARENT_INTF} ) {
		my $siblings = $parent->{$IPROP_CHILD_INTFS};
		@{$siblings} = grep { $_ ne $interface } @{$siblings}; # should only be one; break all
	}

	# Now break any links from ourself to other things, and destroy ourself.
	%{$interface} = ();

	# Finally, once any external refs to us are gone, we get garbage collected.
}

######################################################################

sub get_interface_type {
	return( $_[0]->{$IPROP_INTF_TYPE} );
}

######################################################################

sub get_error_message {
	# This method returns the Message object by reference.
	return( $_[0]->{$IPROP_ERROR_MSG} );
}

######################################################################

sub get_parent_interface {
	# This method returns the Interface object by reference.
	return( $_[0]->{$IPROP_PARENT_INTF} );
}

######################################################################

sub get_root_interface {
	# This method returns the Interface object by reference.
	return( $_[0]->{$IPROP_ROOT_INTF} );
}

######################################################################

sub get_child_interfaces {
	# This method returns each Interface object by reference.
	return( [@{$_[0]->{$IPROP_CHILD_INTFS}}] );
}

######################################################################

sub get_sibling_interfaces {
	# This method returns each Interface object by reference.
	my ($interface, $skip_self) = @_;
	my $parent_intf = $interface->{$IPROP_PARENT_INTF};
	if( $parent_intf ) {
		return( $skip_self ? 
			[grep { $_ ne $interface } @{$parent_intf->{$IPROP_CHILD_INTFS}}] : 
			[@{$parent_intf->{$IPROP_CHILD_INTFS}}] );
	} else {
		return( $skip_self ? [] : [$interface] );
	}
}

######################################################################
# We may not keep this method

sub get_engine {
	return( $_[0]->{$IPROP_ENGINE} );
}

######################################################################

sub get_ssm_node {
	# This method returns the Node object by reference.
	return( $_[0]->{$IPROP_SSM_NODE} );
}

######################################################################
# We may not keep this method

sub get_routine {
	return( $_[0]->{$IPROP_ROUTINE} );
}

######################################################################

sub features {
	my ($interface, $feature_name) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT or 
			$intf_type eq $INTFTP_CONNECTION or $intf_type eq $INTFTP_TRANSACTION ) {
		$interface->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'features', 'ITYPE' => $intf_type } );
	}
	# Test our argument and make sure it is a valid RNI feature name or is undefined.
	if( defined( $feature_name ) ) {
		unless( $POSSIBLE_FEATURES{$feature_name} ) {
			$interface->_throw_error_message( 'ROS_I_FEATURES_BAD_ARG', { 'ARG' => $feature_name } );
		}
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		if( $intf_type eq $INTFTP_TRANSACTION ) {
			return( $interface->{$IPROP_PARENT_INTF}->{$IPROP_PARENT_INTF}->features( $feature_name ) );
		} else {
			return( $interface->{$IPROP_ENGINE}->features( $interface, $feature_name ) );
		}
	};
	my $engine_name = ref($interface->{$IPROP_ENGINE}); # If undef, won't be used anyway.
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Rosetta::Interface' ) ) {
			# The called code threw a Rosetta::Interface object.
			die $exception->{$IPROP_ERROR_MSG};
		} elsif( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			# The called code threw a Locale::KeyedText::Message object.
			die $exception;
		} else {
			# The called code died in some other way (means coding error, not user error).
			$interface->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'features', 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	if( defined( $feature_name ) ) {
		if( defined( $result ) and $result ne '0' and $result ne '1' ) {
			$interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_SCALAR', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'FNAME' => $feature_name, 'VALUE' => $result } );
		}
	} else {
		unless( ref( $result ) eq 'HASH' ) {
			$interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_LIST', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'VALUE' => $result } );
		}
		foreach my $list_feature_name (keys %{$result}) {
			unless( $POSSIBLE_FEATURES{$list_feature_name} ) {
				$interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_ITEM_NAME', 
					{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'FNAME' => $list_feature_name } );
			}
			my $value = $result->{$list_feature_name};
			defined( $value ) or $interface->_throw_error_message( 
				'ROS_I_FEATURES_BAD_RESULT_ITEM_NO_VAL', { 'CLASS' => $engine_name, 'FNAME' => $list_feature_name } );
			if( $value ne '0' and $value ne '1' ) {
				$interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_ITEM_BAD_VAL', 
					{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'FNAME' => $list_feature_name, 'VALUE' => $value } );
			}
		}
	}
	return( $result );
}

######################################################################

sub prepare {
	my ($interface, $routine_defn) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT or 
			$intf_type eq $INTFTP_CONNECTION or $intf_type eq $INTFTP_TRANSACTION ) {
		$interface->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'prepare', 'ITYPE' => $intf_type } );
	}
	# From this point onward, an Interface object will be made, and any errors will go in it.
	my $preparation = eval {
		# An eval block is like a routine body.
		# This test of our SSM Node argument is a bootstrap of sorts; the Interface->new() 
		# method will do the same tests when it is called later; return same errors it would have; 
		# actually, return slightly differently worded errors, show different method name.
		$interface->_validate_ssm_node( 'ROS_I_PREPARE', $INTFTP_PREPARATION, $routine_defn, $interface );
		# Now we get to doing the real work we were called for.
		if( $intf_type eq $INTFTP_APPLICATION and $routine_defn->get_node_type() eq $SSMNTP_LINKPRD ) {
			return( $interface->_prepare_lpn( $routine_defn ) );
		} else {
			return( $interface->{$IPROP_ENGINE}->prepare( $interface, $routine_defn ) );
		}
	};
	my $engine_name = ref($interface->{$IPROP_ENGINE}); # If undef, won't be used anyway.
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Rosetta::Interface' ) ) {
			# The called code threw a Rosetta::Interface object.
			$preparation = $exception;
		} elsif( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			# The called code threw a Locale::KeyedText::Message object.
			$preparation = $interface->new( $INTFTP_ERROR, $exception );
		} else {
			# The called code died in some other way (means coding error, not user error).
			$preparation = $interface->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_METH_MISC_EXCEPTION', { 'METH' => 'prepare', 'CLASS' => $engine_name, 
				'ITYPE' => $intf_type, 'VALUE' => $exception } ) );
		}
	} else {
		unless( ref($preparation) and UNIVERSAL::isa( $preparation, 'Rosetta::Interface' ) ) {
			# The called code didn't die, but didn't return a Rosetta::Interface object either.
			$preparation = $interface->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_PREPARE_BAD_RESULT_NO_INTF', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'VALUE' => $preparation } ) );
		}
	}
	my $prep_intf_type = $preparation->{$IPROP_INTF_TYPE};
	unless( $prep_intf_type eq $INTFTP_ERROR ) {
		# Result is not an Error, so must belong to our Intf tree.
		unless( $preparation->{$IPROP_ROOT_INTF} eq $interface->{$IPROP_ROOT_INTF} ) {
			$preparation = $interface->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_PREPARE_BAD_RESULT_WRONG_ITREE', { 'CLASS' => $engine_name, 'ITYPE' => $intf_type } ) );
		} elsif( $prep_intf_type ne $INTFTP_PREPARATION ) {
			# Non-Error result of prepare() must be a Preparation, without exception.
			$preparation = $interface->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_PREPARE_BAD_RESULT_WRONG_ITYPE', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'RET_ITYPE' => $prep_intf_type } ) );
		}
	}
	if( $preparation->{$IPROP_ERROR_MSG} ) {
		die $preparation;
	}
	return( $preparation );
}

sub _prepare_lpn {
	my ($app_intf, $link_prod_node) = @_;
	my $engine_name = $link_prod_node->get_literal_attribute( 'product_code' );
	my $env_prep_intf = undef;
	foreach my $ch_env_prep_intf (@{$app_intf->{$IPROP_CHILD_INTFS}}) {
		if( $ch_env_prep_intf->{$IPROP_SSM_NODE} eq $link_prod_node ) {
			# An Environment Intf already exists for this link_product_node, so use it.
			# Note that multiple lpn may use the same Engine class; each has diff object.
			$env_prep_intf = $ch_env_prep_intf;
			last;
		}
	}
	unless( $env_prep_intf ) {
		# This Application Interface has no child Environment Preparation Interface of the 
		# requested kind; however, the package implementing that Engine may already be loaded.
		# A package may be loaded due to it being embedded in a non-exclusive file, or because another 
		# Application Intf loaded it.  Check that the package is an Engine subclass regardless.
		no strict 'refs';
		my $package_is_loaded = defined %{$engine_name.'::'};
		use strict 'refs';
		unless( $package_is_loaded ) {
			# a bare "require $engine_name;" yields "can't find module in @INC" error in Perl 5.6
			eval "require $engine_name;";
			if( $@ ) {
				$app_intf->_throw_error_message( 'ROS_I_PREPARE_ENGINE_NO_LOAD', 
					{ 'CLASS' => $engine_name, 'ERR' => $@ } );
			}
		}
		unless( UNIVERSAL::isa( $engine_name, 'Rosetta::Engine' ) ) {
			$app_intf->_throw_error_message( 'ROS_I_PREPARE_ENGINE_NO_ENGINE', { 'CLASS' => $engine_name } );
		}
		if( UNIVERSAL::isa( $engine_name, 'Rosetta::Dispatcher' ) ) {
			$app_intf->_throw_error_message( 'ROS_I_PREPARE_ENGINE_YES_DISPATCHER', { 'CLASS' => $engine_name } );
		}
		my $routine = sub {
			# This routine is a closure.
			my ($rtv_env_prep_eng, $rtv_env_prep_intf, $rtv_args) = @_;
			my $rtv_env_eng = $rtv_env_prep_eng->new();
			my $rtv_env_intf = $rtv_env_prep_intf->new( $INTFTP_ENVIRONMENT, undef, 
				$rtv_env_prep_intf, $rtv_env_eng );
			return( $rtv_env_intf );
		};
		my $env_prep_eng = $engine_name->new();
		$env_prep_intf = $app_intf->new( $INTFTP_PREPARATION, undef, 
			$app_intf, $env_prep_eng, $link_prod_node, $routine );
	}
	return( $env_prep_intf );
}

######################################################################

sub execute {
	my ($preparation, $routine_args) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $preparation->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_PREPARATION ) {
		$preparation->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'execute', 'ITYPE' => $intf_type } );
	}
	# From this point onward, an Interface object will be made, and any errors will go in it.
	my $result = eval {
		# An eval block is like a routine body.
		# Test our argument and make sure it is a valid Perl hash ref or is undefined.
		if( defined( $routine_args ) ) {
			unless( ref($routine_args) eq 'HASH' ) {
				$preparation->_throw_error_message( 'ROS_I_EXECUTE_BAD_ARG', { 'ARG' => $routine_args } );
			}
		} else {
			$routine_args = {};
		}
		# Now we get to doing the real work we were called for.
		if( $preparation->{$IPROP_PARENT_INTF}->{$IPROP_INTF_TYPE} eq $INTFTP_APPLICATION and 
				scalar(@{$preparation->{$IPROP_CHILD_INTFS}}) > 0 ) {
			# Each "Environment Preparation" is only allowed one child "Environment"; 
			# any attempts to create more become no-ops, returning the first instead.
			return( $preparation->{$IPROP_CHILD_INTFS}->[0] );
		} else {
			return( $preparation->{$IPROP_ROUTINE}->( 
				$preparation->{$IPROP_ENGINE}, $preparation, $routine_args ) );
		}
	};
	my $engine_name = ref($preparation->{$IPROP_ENGINE}); # If undef, won't be used anyway.
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Rosetta::Interface' ) ) {
			# The called code threw a Rosetta::Interface object.
			$result = $exception;
		} elsif( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			# The called code threw a Locale::KeyedText::Message object.
			$result = $preparation->new( $INTFTP_ERROR, $exception );
		} else {
			# The called code died in some other way (means coding error, not user error).
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_METH_MISC_EXCEPTION', { 'METH' => 'execute', 'CLASS' => $engine_name, 
				'ITYPE' => $intf_type, 'VALUE' => $exception } ) );
		}
	} else {
		unless( ref($result) and UNIVERSAL::isa( $result, 'Rosetta::Interface' ) ) {
			# The called code didn't die, but didn't return a Rosetta::Interface object either.
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_BAD_RESULT_NO_INTF', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'VALUE' => $result } ) );
		}
	}
	my $res_intf_type = $result->{$IPROP_INTF_TYPE};
	unless( $res_intf_type eq $INTFTP_ERROR or $res_intf_type eq $INTFTP_TOMBSTONE ) {
		# Result is not an Error or Tombstone, so must belong to our Intf tree.
		unless( $result->{$IPROP_ROOT_INTF} eq $preparation->{$IPROP_ROOT_INTF} ) {
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_BAD_RESULT_WRONG_ITREE', { 'CLASS' => $engine_name, 'ITYPE' => $intf_type } ) );
		} elsif( $res_intf_type eq $INTFTP_PREPARATION or $res_intf_type eq $INTFTP_APPLICATION ) {
			# Non-Error result of execute() must be one of [Lit, Env, Conn, Trans, Curs].
			# We do not validate here for having the exact right kind as criteria is complicated.
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_BAD_RESULT_WRONG_ITYPE', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'RET_ITYPE' => $res_intf_type } ) );
		}
	}
	if( $result->{$IPROP_ERROR_MSG} ) {
		die $result;
	}
	return( $result );
}

######################################################################

sub payload {
	my ($lit_intf) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $lit_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_LITERAL ) {
		$lit_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'payload', 'ITYPE' => $intf_type } );
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		return( $lit_intf->{$IPROP_ENGINE}->payload( $lit_intf ) );
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$lit_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'payload', 'CLASS' => ref($lit_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return( $result );
}

######################################################################

sub finalize {
	my ($curs_intf) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $curs_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$curs_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'finalize', 'ITYPE' => $intf_type } );
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		return( $curs_intf->{$IPROP_ENGINE}->finalize( $curs_intf ) ); # do the equivalent of CURSOR_CLOSE here
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$curs_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'finalize', 'CLASS' => ref($curs_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return( $result );
}

######################################################################

sub has_more_rows {
	my ($curs_intf) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $curs_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$curs_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'has_more_rows', 'ITYPE' => $intf_type } );
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		return( $curs_intf->{$IPROP_ENGINE}->has_more_rows( $curs_intf ) );
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$curs_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'has_more_rows', 'CLASS' => ref($curs_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return( $result );
}

######################################################################

sub fetch_row {
	my ($curs_intf) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $curs_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$curs_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'fetch_row', 'ITYPE' => $intf_type } );
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		return( $curs_intf->{$IPROP_ENGINE}->fetch_row( $curs_intf ) ); # do the equivalent of CURSOR_FETCH here
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$curs_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'fetch_row', 'CLASS' => ref($curs_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return( $result );
}

######################################################################

sub fetch_all_rows {
	my ($curs_intf) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $curs_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$curs_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'fetch_all_rows', 'ITYPE' => $intf_type } );
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		return( $curs_intf->{$IPROP_ENGINE}->fetch_all_rows( $curs_intf ) ); # stuff multiple fetch, then finalize
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$curs_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'fetch_all_rows', 'CLASS' => ref($curs_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return( $result );
}

######################################################################
######################################################################

package Rosetta::Engine;
use base qw( Rosetta );

######################################################################
# These methods must be overridden by sub-classes; they simply die otherwise.

sub new {
	my ($class) = @_;
	$class->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'new', 'CLASS' => ref($class) || $class } );
}

sub destroy {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'destroy', 'CLASS' => ref($engine) } );
}

sub features {
	my ($engine, $interface, $feature_name) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'features', 'CLASS' => ref($engine) } );
}

sub prepare {
	my ($engine, $interface, $routine_defn) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'prepare', 'CLASS' => ref($engine) } );
}

sub payload {
	my ($lit_eng, $lit_intf) = @_;
	$lit_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'payload', 'CLASS' => ref($lit_eng) } );
}

sub finalize {
	my ($curs_eng, $curs_intf) = @_;
	$curs_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'finalize', 'CLASS' => ref($curs_eng) } );
}

sub has_more_rows {
	my ($curs_eng, $curs_intf) = @_;
	$curs_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'has_more_rows', 'CLASS' => ref($curs_eng) } );
}

sub fetch_row {
	my ($curs_eng, $curs_intf) = @_;
	$curs_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'fetch_row', 'CLASS' => ref($curs_eng) } );
}

sub fetch_all_rows {
	my ($curs_eng, $curs_intf) = @_;
	$curs_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'fetch_all_rows', 'CLASS' => ref($curs_eng) } );
}

######################################################################
######################################################################

package Rosetta::Dispatcher;
use base qw( Rosetta::Engine );

######################################################################

sub new {
	my ($class) = @_;
	my $engine = bless( {}, ref($class) || $class );
	return( $engine );
}

######################################################################

sub destroy {
	my ($engine, $interface) = @_;
	%{$engine} = ();
}

######################################################################

sub features {
	# This method assumes that it is only called on Application Interfaces.
	my ($app_eng, $app_intf, $feature_name) = @_;

	# First gather the feature results from each available Engine.
	my @results = ();
	my $container = $app_intf->get_ssm_node()->get_container();
	foreach my $link_prod_node (@{$container->get_child_nodes( 'data_link_product' )}) {
		my $env_prep_intf = $app_intf->prepare( $link_prod_node );
		my $env_intf = $env_prep_intf->execute();
		my $result = $env_intf->features( $feature_name );
		push( @results, $result );
	}

	# Now combine the results by means of intersection|and.  For each possible 
	# feature, the combined output is 1 ('yes') only if all inputs are 1, and 0 ('no') 
	# only if all are 0; if any inputs differ or are undef ('maybe') then 
	# the output is undef ('maybe') or a missing list item.  If there are zero 
	# Engines, then the result is undef ('maybe') or an empty list.

	if( defined( $feature_name ) ) {
		my $result = shift( @results ); # returns undef if no Engines
		if( !defined( $result ) ) {
			return( $result );
		}
		while( @results > 0 ) {
			my $next_result = shift( @results );
			if( !defined( $next_result ) or $next_result ne $result ) {
				$result = undef; last;
			}
			# so far, both $result and $next_result have the same 1 or 0 value
		}
		return( $result );

	} else {
		my $result = shift( @results ) || {}; # returns {} if no Engines
		if( (keys %{$result}) == 0 ) {
			return( $result );
		}
		while( @results > 0 ) {
			my $next_result = shift( @results );
			if( (keys %{$next_result}) == 0 ) {
				$result = {}; last;
			}
			foreach my $list_feature_name (keys %{$result}) {
				my $result_value = $result->{$list_feature_name};
				my $next_result_value = $next_result->{$list_feature_name};
				if( !defined( $next_result_value ) or $next_result_value ne $result_value ) {
					delete( $result->{$list_feature_name} );
				}
				# so far, both $result_value and $next_result_value have the same 1 or 0 value
			}
			(keys %{$result}) == 0 and last;
		}
		return( $result );
	}
}

######################################################################

sub prepare {
	# This method assumes that it is only called on Application Interfaces.
	my ($app_eng, $app_intf, $routine_defn) = @_;
	my $node_type = $routine_defn->get_node_type();
	if( $node_type eq $SSMNTP_COMMAND ) {
		my $cmd_type = $routine_defn->get_enumerated_attribute( 'command_type' );
		if( $cmd_type eq $SSM_CMDTP_DB_LIST ) {
			return( $app_eng->prepare_cmd_db_list( $app_intf, $routine_defn ) );
		} elsif( $cmd_type eq $SSM_CMDTP_DB_OPEN ) {
			return( $app_eng->prepare_cmd_db_open( $app_intf, $routine_defn ) );
		} else {
			$app_intf->_throw_error_message( 'ROS_G_PREPARE_INTF_NSUP_THIS_CMD', 
				{ 'CLASS' => 'Rosetta::Dispatcher', 'ITYPE' => $INTFTP_APPLICATION, 'CTYPE' => $cmd_type } );
		}
	} else {
		$app_intf->_throw_error_message( 'ROS_G_PREPARE_INTF_NSUP_SSM_NODE', 
			{ 'CLASS' => 'Rosetta::Dispatcher', 'ITYPE' => $INTFTP_APPLICATION, 'NTYPE' => $node_type } );
	}
}

######################################################################

sub prepare_cmd_db_list {
	# This method assumes that it is only called on Application Interfaces.
	my ($app_eng, $app_intf, $command_bp_node) = @_;

	my @lit_prep_intfs = ();
	my $container = $command_bp_node->get_container();
	foreach my $link_prod_node (@{$container->get_child_nodes( 'data_link_product' )}) {
		my $env_prep_intf = $app_intf->prepare( $link_prod_node );
		my $env_intf = $env_prep_intf->execute();
		my $lit_prep_intf = $env_intf->prepare( $command_bp_node );
		push( @lit_prep_intfs, $lit_prep_intf );
	}

	my $routine = sub {
		# This routine is a closure.
		my ($rtv_lit_prep_eng, $rtv_lit_prep_intf, $rtv_args) = @_;

		my @cat_link_inst_nodes = ();

		foreach my $lit_prep_intf (@lit_prep_intfs) {
			my $lit_intf = $lit_prep_intf->execute();
			my $payload = $lit_intf->payload();
			push( @cat_link_inst_nodes, @{$payload} );
		}

		my $rtv_lit_eng = $rtv_lit_prep_eng->new();
		$rtv_lit_eng->{$DPROP_LIT_PAYLOAD} = \@cat_link_inst_nodes;

		my $rtv_lit_intf = $rtv_lit_prep_intf->new( $INTFTP_LITERAL, undef, 
			$rtv_lit_prep_intf, $rtv_lit_eng );
		return( $rtv_lit_intf );
	};

	my $lit_prep_eng = $app_eng->new();

	my $lit_prep_intf = $app_intf->new( $INTFTP_PREPARATION, undef, 
		$app_intf, $lit_prep_eng, $command_bp_node, $routine );
	return( $lit_prep_intf );
}

######################################################################

sub prepare_cmd_db_open {
	# This method assumes that it is only called on Application Interfaces.
	my ($app_eng, $app_intf, $command_bp_node) = @_;

	# First, figure out link product by cross-referencing app inst with command-spec link bp.
	my $cat_link_bp_node = $command_bp_node->get_child_nodes( 'command_arg' 
		)->[0]->get_node_ref_attribute( 'catalog_link' );
	my $app_inst_node = $app_intf->get_ssm_node();
	my $cat_link_inst_node = undef;
	foreach my $link (@{$app_inst_node->get_child_nodes( 'catalog_link_instance' )}) {
		if( $link->get_node_ref_attribute( 'unrealized' ) eq $cat_link_bp_node ) {
			$cat_link_inst_node = $link;
			last;
		}
	}
	my $link_prod_node = $cat_link_inst_node->get_node_ref_attribute( 'product' );

	# Now make sure that the Engine we need is loaded.
	my $env_prep_intf = $app_intf->prepare( $link_prod_node );
	my $env_intf = $env_prep_intf->execute();
	# Now repeat the command we ourselves were given against a specific Environment Interface.
	my $conn_prep_intf = $env_intf->prepare( $command_bp_node );
	return( $conn_prep_intf );
}

######################################################################

sub payload {
	my ($lit_eng, $lit_intf) = @_;
	return( $lit_eng->{$DPROP_LIT_PAYLOAD} );
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<Note: Look at the SQL::SyntaxModel (SSM) documentation for examples of how to
construct the various SQL commands / Node groups used in this SYNOPSIS. 
Furthermore, you should look at the SYNOPSIS for Rosetta::Engine::Generic,
which fleshes out a number of details just relegated to "figure it out" below.>

	use Rosetta; # Module also 'uses' SQL::SyntaxModel and Locale::KeyedText.

	my $schema_model = SQL::SyntaxModel->new_container(); # global for a simpler illustration, not reality

	main();

	$schema_model->destroy(); # so we don't leak memory

	sub main {
		# ... Next create and stuff Nodes in $schema_model that represent the application 
		# blueprint and instance thereof that we are.  Then put a 'application_instance' 
		# Node for said instance in $application_instance.

		my $application = Rosetta->new_application( $application_instance );

		do_connection( $application );

		$application->destroy(); # so we don't leak memory
	}

	sub do_connection {
		my ($application) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent the database we want 
		# to use (including what data storage product it is) and how we want to link/connect 
		# to it (including what Rosetta "Engine" plug-in and DSN to use).  Then put a 'command' 
		# Node which instructs to open a connection with said database in $open_db_command.

		my $prepared_open_cmd = eval { 
			return( $application->prepare( $open_db_command ) );
		};
		if( $@ ) {
			print "internal error: a command is invalid: ".error_to_string( $@ );
			return( 0 );
		}

		my $db_conn = undef;
		while( 1 ) {
			# ... Next, assuming they are gotten dynamically such as from the user, gather the db 
			# authentication credentials, username and password, and put them in $user and $pass.

			$db_conn = eval { 
				return( $prepared_open_cmd->execute( { 'login_user' => $user, 'login_pass' => $pass } ) );
			}
			unless( $@ ) {
				last; # Connection was successful.
			}

			# If we get here, something went wrong when trying to open the database; eg: the requested 
			# Engine plug-in doesn't exist, or the DSN doesn't exist, or the user/pass are incorrect.  

			my $error_message = $@->get_error_message();

			# ... Next examine $error_message (a machine-readable Locale::KeyedText::Message 
			# object) to see if the problem is our fault or the user's fault.

			if( ... user is at fault ... ) {
				print "sorry, you entered the wrong user/pass, please try again";
				next;
			}

			print "sorry, problem opening db, we gotta quit: ".error_to_string( $@ );
			return( 0 );
		}

		# Now do the work we connected to the db for.  To simplify this example, it is 
		# fully non-interactive, such as with a test script.
		OUTER: {
			do_install( $db_conn ) or last OUTER;
			INNER: {
				do_populate( $db_conn ) or last INNER;
				do_select( $db_conn );
			}
			do_remove( $db_conn );
		}

		# ... Next make a SSM 'command' to close the db and put it in $close_db_command.

		eval {
			$db_conn->prepare( $close_db_command )->execute();
		}; # ignore the result this time

		return( 1 );
	}

	sub error_to_string {
		my ($interface) = @_;
		my $message = $interface->get_error_message();
		my $translator = Locale::KeyedText->new_translator( 
			['Rosetta::L::', 'SQL::SyntaxModel::L::'], ['en'] );
		my $user_text = $translator->translate_message( $message );
		unless( $user_text ) {
			return( "internal error: can't find user text for a message: ".
				$message->as_string()." ".$translator->as_string() );
		}
		return( $user_text );
	}

	sub do_install {
		my ($db_conn) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent a table 
		# we want to create in our database; let's pretend it is named 'stoff' and 
		# has 3 columns named 'foo', 'bar', 'baz'.  Then put a 'command' Node which 
		# instructs to create said table in $create_stoff_command.

		my $result = eval { 
			return( $db_conn->prepare( $create_stoff_command )->execute() );
		};
		if( $@ ) {
			print "sorry, problem making stoff table: ".error_to_string( $@ );
			return( 0 );
		}

		# If we get here, the table was made successfully.
		return( 1 );
	}

	sub do_remove {
		my ($db_conn) = @_;

		# ... Next make a SSM 'command' to drop the table and put it in $drop_stoff_command.

		my $result = eval { 
			return( $db_conn->prepare( $drop_stoff_command )->execute() );
		};
		if( $@ ) {
			print "sorry, problem removing table: ".error_to_string( $@ );
			return( 0 );
		}

		# If we get here, the table was removed successfully.
		return( 1 );
	}

	sub do_populate {
		my ($db_conn) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# inserts a row into the 'stoff' table; it takes 3 arguments named 'a_foo', 
		# 'a_bar', 'a_baz'.  Then put this 'routine' Node in $insert_stoff_cmd.

		my $prepared_insert_cmd = $db_conn->prepare( $insert_stoff_cmd );

		my @data = (
			{ 'a_foo' => 'windy', 'a_bar' => 'carrots' , 'a_baz' => 'dirt'  , },
			{ 'a_foo' => 'rainy', 'a_bar' => 'peas'    , 'a_baz' => 'mud'   , },
			{ 'a_foo' => 'snowy', 'a_bar' => 'tomatoes', 'a_baz' => 'cement', },
			{ 'a_foo' => 'sunny', 'a_bar' => 'broccoli', 'a_baz' => 'moss'  , },
			{ 'a_foo' => 'haily', 'a_bar' => 'onions'  , 'a_baz' => 'stones', },
		)

		foreach my $data_item (@data) {
			my $result = eval { 
				return( $prepared_insert_cmd->execute( $data_item ) );
			};
			if( $@ ) {
				print "sorry, problem stuffing stoff: ".error_to_string( $@ );
				return( 0 );
			}
		}

		# If we get here, the table was populated successfully.
		return( 1 );
	}

	sub do_select {
		my ($db_conn) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# selects a row from the 'stoff' table, where the column 'foo' matches the sole 
		# routine arg 'a_foo'.  Then put this 'routine' Node in $get_one_stoff_cmd.

		my $get_one_cmd = eval { 
			return( $db_conn->prepare( $get_one_stoff_cmd ) );
		}
		if( $@ ) {
			print "internal error: a command is invalid: ".error_to_string( $@ );
			return( 0 );
		}
		my $row = eval { 
			return( $get_one_cmd->execute( { 'a_foo' => 'snowy' } ) );
		}
		if( $@ ) ) {
			print "sorry, problem getting snowy: ".error_to_string( $@ );
			return( 0 );
		}
		my $data = $row->row_data(); # $data is a hash-ref of tbl col name/val pairs.

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# selects all rows from 'stoff'.  Then put this 'routine' Node in $get_all_stoff_cmd.

		my $get_all_cmd = eval { 
			return( $db_conn->prepare( $get_all_stoff_cmd ) );
		}
		if( $@ ) ) {
			print "internal error: a command is invalid: ".error_to_string( $@ );
			return( 0 );
		}
		my $cursor = eval { 
			return( $get_all_cmd->execute() );
		}
		if( $@ ) ) {
			print "sorry, problem getting all stoff: ".error_to_string( $@ );
			return( 0 );
		}
		my @data = ();
		while( $cursor->has_more_rows() ) {
			push( @data, $cursor->fetch_row() );
		}
		$cursor->finalize();
		# Each @data element is a hash-ref of tbl col name/val pairs.

		# If we get here, the table was fetched from successfully.
		return( 1 );
	}

=head1 DESCRIPTION

The Rosetta Perl 5 module implements the core of the Rosetta database
portability framework.  Rosetta defines a complete and rigorous API, having a
"Command" design pattern, for applications to query and manipulate databases
with; it handles all common functionality that is representable by SQL or that
database products implement, both data manipulation and schema manipulation. 
This Rosetta core does not implement that interface (or most of it), however;
you use it with your choice of separate "Engine" plug-ins that each understand
how to talk to particular data storage products or data link products, and
implement the Rosetta Native Interface (or "RNI") on top of those products.

The level of abstraction that Rosetta provides is similar to a virtual machine,
such that applications written to do their database communications through it
should "just work", without changes, when moved between databases.  This should
happen with applications of nearly any complexity level, including those that
use all (most) manner of advanced database features.  It is as if every
database product out there has full ANSI/ISO SQL-2003 (or 1999 or 1992)
compliance, so you write in standard SQL that just works anywhere.  Supported
advanced features include generation and invocation of database stored
routines, select queries (or views or cursors) of any complexity, [ins,upd,del]
against views, multiple column keys, nesting, multiple schemas, separation of
global from site-specific details, host parameters, unicode, binary data,
triggers, transactions, locking, constraints, data domains, localization,
proxies, and database to database links.  At the same time, Rosetta is designed
to be fast and efficient.  Rosetta is designed to work equally well with both
embedded and client-server databases.

The separately released SQL::SyntaxModel Perl 5 module is used by Rosetta
as a core part of its API.  Applications pass SQL::SyntaxModel objects in place
of SQL strings when they want to invoke a database, both for DML and DDL
activity, and a Rosetta Engine translates those objects into the native SQL (or
non-SQL) dialect of the database.  Similarly, when a database returns a schema
dump of some sort, it is passed to the application as SQL::SyntaxModel objects
in place of either SQL strings or "information schema" rows.  You should look
at SQL::SyntaxModel::Language as a general reference on how to construct
queries or schemas, and also to know what features are or are not supported.

Rosetta is especially suited for data-driven applications, since the composite
scalar values in their data dictionaries can often be copied directly to RNI
structures, saving applications the tedious work of generating SQL themselves.

Depending on what kind of application you are writing, you may be better off to
not use Rosetta directly as a database interface.  The RNI is quite verbose,
and using it directly (especially SQL::SyntaxModel) can be akin to writing
assembly language like IMC for Parrot, at least as far as how much work each
instruction does.  Rosetta is designed this way on purpose so that it can serve
as a foundation for other database interface modules, such as object
persistence solutions, or query generators, or application tool kits, or
emulators, or "simple database interfaces".  Many such modules exist on CPAN
and all suffer from the same "background problem", which is getting them to
work with more than one or three databases; for example, many only work with
MySQL, or just that and PostgreSQL, and a handful do maybe five products. Also,
there is a frequent lack of support for desirable features like multiple column
keys.  I hope that such modules can see value in using Rosetta as they now use
DBI directly; by doing so, they can focus on their added value and not worry
about the database portability aspect of the equation, which for many was only
a secondary concern to begin with.  Correspondingly, application writers that
wish to use Rosetta would be best off having their own set of "summarizing"
wrapper functions to keep your code down to size, or use another CPAN module
such as one of the above that does the wrapping for you.

The Rosetta framework is conceptually similar to the mature and popular Perl
DBI framework created by Tim Bunce, and loosely resembles that structurally as
well; in fact, many initial Rosetta Engines are each implemented as a
value-added wrapper for a DBI DBD module.  But they have significant
differences as well, so Rosetta should not be considered a mere wrapper of DBI
(moreover, on the implementation side, the Rosetta core does not require DBI at
all, and any of its Engines can do their work without it also if they so
choose).  I see DBI by itself as a generic communications pipe between a
database and an application, that shuttles mostly opaque boxes back and forth;
it is a courier that does its transport job very well, while it knows little
about what it is carrying.  More specifically, it knows a fair amount about
what it shuttles *from* the database, but considerably less about what is
shuttled *to* the database (opaque SQL strings, save host parameters).  It is up
to the application to know and speak the same language as the database, meaning
the SQL dialect that is in the boxes, so that the database understands what it
is given.  I see Rosetta by itself as a communications pipe that *does*
understand the contents of the boxes, and it can translate or reorganize the
contents of the boxes while moving them, such that an application can always
speak in the same language regardless of what database it is talking to.  Now,
you could say that this sounds like Rosetta is a query generator on top of DBI,
and in many respects you are correct; that is its largest function.  However,
it can also translate results coming *from* a database, such as massaging
returned data into a single format for the application, while different
databases may not return in the same format.  One decision that I made with
Rosetta, unlike other query generation type modules, is that it will never
expose any underlying DBI object to the application.  I<Note that I may have
mis-interpreted DBI's capabilities, so this paragraph stands to be changed as I
get better educated.>

Please see the Rosetta::Framework documentation file for more information on
the Rosetta framework at large.  It shows this current module in the context of
actual or possible other components.

=head1 CLASSES IN THIS MODULE

This module is implemented by several object-oriented Perl 5 packages, each of
which is referred to as a class.  They are: B<Rosetta> (the module's
name-sake), B<Rosetta::Interface> (aka B<Interface>), B<Rosetta::Engine> (aka
B<Engine>), and B<Rosetta::Dispatcher> (aka B<Dispatcher>).

I<While all 4 of the above classes are implemented in one module for
convenience, you should consider all 4 names as being "in use"; do not create
any modules or packages yourself that have the same names.>

The Interface class does most of the work and is what you mainly use.  The
name-sake class mainly exists to guide CPAN in indexing the whole module, but
it also provides a set of stateless utility methods and constants that the
other two classes inherit, and it provides a wrapper function over the
Interface class for your convenience; you never instantiate an object of
Rosetta itself.

The Engine class is only invoked indirectly, via the Interface class; moreover,
you need to choose an external class which subclasses Engine (and implements
all of its methods) to use via the Interface class.

The Dispatcher class is used internally by Interface to implement an
ease-of-use feature of Rosetta where multiple Rosetta Engines can be used as
one.  An example of this is that you can invoke a DB_LIST command without
specifying an Engine to run it against; Dispatcher will run that command
against each individual Engine behind the scenes and combine their results; you
then see a single list of databases that Rosetta can access without regard for
which Engine mediates access.  As a second example, you can invoke a DB_OPEN
command off of the root Application Interface rather than having to do it
against the correct Environment Interface; Dispatcher will detect which
Environment is required (based on info in your SQL::SyntaxModel) and
load/dispatch to the appropriate Engine that mediates the database connection.

=head1 STRUCTURE

The Rosetta core module is structured like a simple virtual machine, which can
be conceptually thought of as implementing an embedded SQL database;
alternately, it is a command interpreter.  This module is implemented with 2
main classes that work together, which are "Interface" and "Engine".  To use
Rosetta, you first create a root Interface object (or several; one is normal)
using Rosetta->new_application(), which provides a context in which you can
prepare and execute commands against a database or three.  One of your first
commands is likely to open a connection to a database, during which you
associate a separately available Engine plug-in of your choice with said
connection.  This Engine plug-in does all the meat of implementing the Rosetta
API that the Interface defines; the Engine class defined inside the Rosetta
core module is a simple common super-class for all Engine plug-in modules.

Note that each distinct Rosetta Engine class is represented by a distinct
SQL::SyntaxModel "data_link_product" Node that you create; you put the name of
the Rosetta Engine Class, such as "Rosetta::Engine::foo", in that Node's
"product_code" attribute.  The SQL::SyntaxModel documentation refers to that
attribute as being just for recognition by an external "mediation layer"; when
you use Rosetta, then Rosetta *is* said "mediation layer".

During the normal course of using Rosetta, you will end up talking to a whole
bunch of Interface objects, which are all related to each other in a tree-like
fashion.  Each time you prepare() or execute() a command against one, another
is typically spawned which represents the results of your command, be it an
error condition or a database connection handle or a transaction context handle
or a select cursor handle or a miscellaneous returned data container.  Each
Interface object has a "type" property which says what kind of thing it
represents and how it behaves.  All Interface types have a
"get_error_message()" method but only a cursor type, for example, has a
"fetch_row()" method.  For simplicity, all Interface objects are explicitly
defined to have all possible Interface methods (no "autoload" et al is used);
however, an inappropriately called method will throw an exception saying so, so
it is as if Perl had a normal run-time error due to calling a non-existent
method.

Each Interface object may also have its own Engine object associated with it
behind the scenes, with all the Engine objects in a mirroring tree structure;
but that may not always be true.  One example is right when you start out, or
if you try to open a database connection using a non-existent Engine module.
Specifically, it is Error Interfaces and Tombstone Interfaces and Application
Interfaces that never have their own associated Engine; every other type of
Interface must have one.

This diagram shows all of the Interface types and how they are allowed to 
relate to each other parent-child wise in an Interface tree:

	1	Error
	2	Tombstone
	3	Application
	4	  Preparation
	5	    Literal
	6	    Environment
	7	      Preparation
	8	        Literal
	9	        Connection
	10	          Preparation
	11	            Literal
	12	            Transaction
	13	              Preparation
	14	                Literal
	15	                Cursor

The "Application" (3) at the top is created using "Rosetta->new()", and you
normally have just one of those in your program.  A "Preparation" (4,7,10,13)
is created when you invoke "prepare()" off of an Interface object of one of
these types: "Application" (3), "Environment" (6), "Connection" (9),
"Transaction" (12).  Every type of Interface except "Application" and
"Preparation" is created by invoking "execute()" of an appropriate
"Preparation" method.  The "prepare()" and "execute()" methods always create a
new Interface having the result of the call, and this is usually a child of the
one you invoked it from.

An "Error" (1) Interface can be returned potentially by any method and it is
self-contained; it has no parent Interfaces or children.  Note that any other
kind of Interface can also store an error condition in addition to keeping its
normal properties.

A "Tombstone" (2) Interface is returned by execute() when that method's
successful action involves destroying the parent of the Interface on which it
was invoked (which is the context for the destruction command-routine); the new
Interface has no parent or child Interfaces.

For convenience, what often happens is that the Rosetta Engine will create
multiple Interface generations for you as appropriate when you say "prepare()".
For example, if you give a "open this database" command to an "Application" (3)
Interface, you would be given back a great-grand-child "Preparation" (7)
Interface.  Or, if you give a "select these rows" command to a "Connection" (9)
Interface, you will be given back a great-grand-child "Preparation" (13)
Interface (which would re-use the last "Transaction" if one exists).  Be aware
of this if you ever request that an Interface you hold give you its parent.

=head1 FEATURE SUPPORT VALIDATION

The Rosetta Native Interface (RNI) declares accessors for a large number of
actual or possible database features, any of which your application can invoke,
and all of which each Rosetta Engine would ideally implement or interface to.

In reality, however, all Engines or underlying databases probably don't support
some features, and if your application tries to invoke any of the same features
that an Engine you are using doesn't support, then you will have problems
ranging from immediate crashes/exceptions to subtle data corruption over time.

As an official quality assurance (QA) measure, Rosetta provides a means for
each Engine to programmatically declare which RNI features it does and does not
support, so that code using that Engine will know so in advance of trying to
use said features.  Feature support declarations are typically coarse grained
and lump closely similar things together, for simplicity; they will be just as
fine grained as necessary and no finer (this can be changed over time).  See 
the features() method, which is how you read the declarations.

The features() method is usually invoked off of either an Environment Interface
or a Connection Interface.  The Environment method invocation is used to
declare features that the Environment's Engine supports under all circumstances
of its use.  The Connection method invocation is used to declare features that
the Engine conditionally supports on a per-connection basis, because the same
Engine may be able to link to multiple database products that have different
capabilities; the results only apply to the Connection Interface it was invoked
off of.  Note that the declarations by the second are a full super-set of those
by the first; if the Engine knowingly deals with exactly one database product,
then the two declaration sets would be identical.

One benefit of this QA feature is that, after you have written your application
and it is working with one Engine/database, and you want to move it to a
different Engine/database, you can determine at a glance which alternatives
also support the features you are using.  Note that, generally speaking, you 
would have to be using very proprietary features to begin with in order for the 
majority of Rosetta Engines/databases to not support the application outright.

Another benefit of this QA feature is that there can be made a common
comprehensive test suite to run against all Engines in order to tell that they
are implementing the Rosetta interface properly or not; said test suite will be
smart enough to only test each Engine's RNI compliance for those features
that the Engine claims to support, and not fail it for non-working features
that it explicitly says it doesn't support.  This common test suite will save
each Engine maker from having to write their own module tests.  It would be
used similarly to how Sun has an official validation suite for Java Virtual
Machines to make sure they implement the official Java specification.  Please 
see the Rosetta::Validator module(s), which implements this test suite.

See the Rosetta::Features documentation file for a complete list of what RNI
features a Rosetta Engine can possibly implement, and that Rosetta::Validator
can test for.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

All class functions and methods will throw exceptions on error conditions; they
will only return normally if there are no error conditions.  The thrown
exceptions will be Locale::KeyedText::Message objects when the error is bad
user/caller input, and they will be Rosetta::Interface objects with set Error
Message properties when the error is a failed prepare() or execute().  You
should never get a raw Perl exception that is generated within Rosetta or one
of its Engines.

=head1 CONSTRUCTOR WRAPPER FUNCTIONS

These functions are stateless and can be invoked off of either the module name,
or any package name in this module, or any object created by this module; they
are thin wrappers over other methods and exist strictly for convenience.

=head2 new_application( SSM_NODE )

	my $app = SQL::SyntaxModel->new_application( $my_app_inst );
	my $app2 = SQL::SyntaxModel::Interface->new_application( $my_app_inst );
	my $app3 = $app->new_application( $my_app_inst );

This function wraps Rosetta::Interface->new( 'Application', undef, undef,
undef, SSM_NODE ).  It can only create 'Application' Interfaces, and its sole
SSM_NODE argument must be an 'application_instance' SQL::SyntaxModel::Node.

=head1 INTERFACE CONSTRUCTOR FUNCTIONS AND METHODS

This function/method is stateless and can be invoked off of either the Interface
class name or an existing Interface object, with the same result.

=head2 new( INTF_TYPE[, ERR_MSG][, PARENT_INTF][, ENGINE][, SSM_NODE][, ROUTINE] )

	my $app = Rosetta::Interface->new( 'Application', undef, undef, undef, $my_app_inst );
	my $conn_prep = $app->new( 'Preparation', undef, $app, undef, $conn_command, $conn_routine );

This "getter" function/method will create and return a single
Rosetta::Interface (or subclass) object whose Interface Type is given in the
INTF_TYPE (enum) argument; all of the other properties will be set from the
remaining arguments depending on what the Interface Type is.  All of an
Interface's properties must be set on instantiation and can not be changed
afterwards, except when said Interface is destroyed (the Throw Errors property
is the lone exception).  The class works this way since each Interface object
is typically the result of invoking a method off another Interface object; the
new object contains the "result" of calling the method.  The ERR_MSG argument
holds a Locale::KeyedText::Message object; you set this when the new Interface
represents an error condition.  The PARENT_INTF argument holds another
Interface object which is to be the parent of the new one; typically it is the
Interface whose method was invoked to indirectly create the current one; every
Interface must have a parent unless it is an 'Application', which must not have
one.  The ENGINE argument is an Engine object that will implement the new
Interface.  The SSM_NODE argument is a SQL::SyntaxModel::Node argument that
provides a context or instruction for how the new Interface is created; eg, it
contains the "command" which the new Interface mediates the result of.  The 
ROUTINE argument is a Perl anonymous subroutine reference (or closure); this is 
created by an Engine in its prepare() method, and executed by execute().  This 
function will throw exceptions if any arguments are inappropriate in context.  
Typically this function is only invoked directly by the Engine object behind 
its parent-to-be Interface when said Interface is called with prepare/execute.  
The Throw Errors property defaults from the parent Interface, or to false.

=head1 INTERFACE OBJECT METHODS

These methods are stateful and may only be invoked off of Interface objects.

=head2 destroy()

	$interface->destroy();

This "setter" method will destroy the Interface object that it is invoked from,
and it will also destroy the Engine associated with the Interface, if any. 
This method will fail if the current Interface object has child Interfaces; you
have to destroy each of them first.

=head2 get_interface_type()

	my $type = $interface->get_interface_type();

This "getter" method returns the Interface Type scalar (enum) property of this
Interface.

=head2 get_error_message()

	my $message = $interface->get_error_message();

This "getter" method returns by reference the Error Message
Locale::KeyedText::Message object property of this Interface, if it has one.

=head2 get_parent_interface()

	my $parent = $interface->get_parent_interface();

This "getter" method returns by reference the parent Interface of this
Interface, if it has one.

=head2 get_root_interface()

	my $appl_intf = $interface->get_root_interface();

This "getter" method returns by reference the root 'Application' Interface of
the tree that this Interface is in, if possible.  If the current Interface is
an 'Application', then this method returns a reference to itself.  If the
current Interface is either an 'Error' or 'Tombstone', then this method returns
undef.  This is strictly a convenience method, similar to calling
get_parent_interface() recursively, and it exists to help make code faster.

=head2 get_child_interfaces()

	my $children = $interface->get_child_interfaces();

This "getter" method returns a new array ref having references to all of this
Interface's child Interfaces, or an empty array ref if there are no children.

=head2 get_sibling_interfaces([ SKIP_SELF ])

	my $siblings_with_self = $interface->get_sibling_interfaces();
	my $siblings_not_self = $interface->get_sibling_interfaces( 1 );

This "getter" method returns a new array ref having references to all of this
Interface's sibling Interfaces.  This list includes by default the Interface
upon which the method was called; however, if the optional boolean argument
SKIP_SELF is true, then the list will exclude the called-on Interface.  If this
Interface has no parent Interface, then the returned list will either consist
of just itself, or be an empty list, depending on SKIP_SELF.

=head2 get_engine()

	my $engine = $interface->get_engine();

This "getter" method returns by reference the Engine that implements this
Interface, if it has one.  I<This method may be removed later.>

=head2 get_ssm_node()

	my $node = $interface->get_ssm_node();

This "getter" method returns by reference the SQL::SyntaxModel::Node object
property of this Interface, if it has one.

=head2 get_routine()

	my $routine = $preparation->get_routine();

This "getter" method returns by reference the Perl anonymous routine property
of this Interface, if it has one.  I<This method may be removed later.>

=head2 features([ FEATURE_NAME ])

This "getter" method may only be invoked off of Interfaces having one of these
types: "Application", "Environment", "Connection", "Transaction"; it will throw
an exception if you invoke it on anything else.  When called with no arguments,
it will return a Perl hash ref whose keys are the names of key feature groups
that the corresponding Engine is declaring its support status for; values are
always either '1' for 'yes' and '0' for 'no'. If a key is absent, then the
Engine is saying that it doesn't know yet whether it will support the feature
or not.  If the optional argument FEATURE_NAME is defined, then this method
will treat that like a key in the previous mentioned hash and return just the
associated value of 1, 0, or undefined (don't know).  When a particular
Environment says 'yes' or 'no' for particular features, then grandchild
Connections are guaranteed to say likewise; when an Environment says "don't
know" for a feature, then the Connections can each change this to 'yes' or 'no'
as it applies to them; however, if a Connection still says "don't know" then
this can be read as 'no'.  Note that invoking Application.features() will cause
all available Engines to load, each of their Environments consulted, and the
results combined to give the final result; for each possible feature, the
combined output is 'yes' iff all input Engines are 'yes', 'no' iff all 'no',
and undefined/missing if any inputs differ or are undefined/missing; if there
are no available Engines, the result is empty-list/undefined.  Note that
Transaction.features() is simply an alias for its grandparent
Connection.features(); it is provided for convenience only.

=head2 prepare( ROUTINE_DEFN )

This "getter"/"setter" method takes a SQL::SyntaxModel::Node object usually
representing either a "command" or a "routine" in its ROUTINE_DEFN argument,
then "compiles" it into a new "Preparation" Interface (returned) which is ready
to execute the specified action.  This method may only be invoked off of
Interfaces having one of these types: "Application", "Environment",
"Connection", "Transaction"; it will throw an exception if you invoke it on
anything else.  Most of the time, this method just passes the buck to the
Engine module that actually does its work, after doing some basic input
checking, or it will instantiate an Engine object.  Any calls to Engine objects
are wrapped in an eval block so that miscellaneous exceptions generated there
don't kill the program.  Note that invoking Application.prepare() where the
ROUTINE_DEFN is a "data_link_product" Node will create a "Preparation"
Interface that would simply load an Engine, but doesn't make a Connection or
otherwise ask the Engine to do anything.  Invoking Application.prepare() with a
"command" or "routine" SSM Node will pass the buck to Rosetta::Dispatcher,
which either passes to a single normal Engine (loading it first if necessary)
or invokes a multitude of Engines (loading if needed) and combines their
results, depending on the command type.

=head2 execute([ ROUTINE_ARGS ])

This "getter"/"setter" method can only be invoked off of a "Preparation"
Interface and will actually perform the action that the Interface is created
for.  The optional hash ref argument ROUTINE_ARGS provides run-time arguments
for the previously "compiled" routine/command, if it takes any.  Unlike
prepare(), which usually calls an Engine module's prepare() to do the actual
work, execute() will not call an Engine directly at all.  Rather, execute()
simply executes the Perl anonymous subroutine property of the "Preparation"
Interface.  Said routine is created by an Engine's prepare() method and is
usually a closure, containing within it all the context necessary for work as
if the Engine was doing it.  Said routine returns new non-prep Interfaces.

=head2 payload()

This "getter" method can only be invoked off of a "Literal" Interface.  It will
return the actual payload that the "Literal" Interface represents.  This can
either be an ordinary string or number or boolean, or a SSM Node ref, or an
array ref or hash ref containing other literal values.

=head2 finalize()

This "setter" method can only be invoked off of a "Cursor" Interface.  It will
close the Cursor, indicating that you want no more data from it.  I<This method
may be removed in favor of destroy() accomplishing the task.  Or maybe not, as
we probably want a return value to indicate success.  Or maybe destroy can.>

=head2 has_more_rows()

This "getter" method can only be invoked off of a "Cursor" Interface.  It will
return a boolean value where true means you can read more rows from the Cursor, 
and false means that all the rows have been read.

=head2 fetch_row()

This "getter"/"setter" method can only be invoked off of a "Cursor" Interface. 
It will fetch one more row from the Cursor, if it can, and return that as a
hash ref where the hash keys are the column names and the values are the data;
the Cursor will be advanced so repeated calls to fetch_row() will return
subsequent rows.

=head2 fetch_all_rows()

This "getter"/"setter" method can only be invoked off of a "Cursor" Interface.
It will fetch all of the remaining rows from the Cursor, returning them in an
array ref where each element is a row held in a hash-ref.  This method will
also finalize() the Cursor, so you don't have to call that separately.

=head1 ENGINE OBJECT FUNCTIONS AND METHODS

Rosetta::Engine defines shims for all of the required Engine methods, each of
which will throw an exception if the sub-classing Engine module doesn't
override them.  These methods all have the same names and functions as
Interface methods, which just turn around and call them.  Every Engine method
takes as its first argument a reference to the Interface object that it is
implementing (the Interface shim provides it); otherwise, each method's
argument list is the same as its same-named Interface method.  These are the
methods: destroy(), features(), prepare(), payload(), finalize(),
has_more_rows(), fetch_row(), fetch_all_rows().  Every Engine must also
implement a new() method which will be called in the form
[class-name-or-object-ref]->new() and must instantiate the Engine object;
typically this is called by the parent Engine, which also makes the Interface
for the new Engine.

=head1 DISPATCHER OBJECT FUNCTIONS AND METHODS

Rosetta::Dispatcher should never be either invoked or sub-classed by you, so
its method list will remain undocumented and private.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

perl(1), Rosetta::L::en, Rosetta::Features, Rosetta::Framework,
SQL::SyntaxModel, Locale::KeyedText, Rosetta::Engine::Generic, DBI, DBD::*,
Alzabo, SPOPS, Class::DBI, Tangram, DBIx::SearchBuilder, SQL::Schema,
DBIx::Abstract, DBIx::AnyDBD, DBIx::Browse, DBIx::SQLEngine, MKDoc::SQL, and
various other modules.

=cut
