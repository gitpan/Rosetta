#!perl

use 5.008001; use utf8; use strict; use warnings;

package Rosetta;
our $VERSION = '0.41';

use Locale::KeyedText '1.02';
use SQL::Routine '0.56';

######################################################################

=encoding utf8

=head1 NAME

Rosetta - Rigorous database portability

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: 

	Locale::KeyedText 1.02 (for error messages)
	SQL::Routine 0.56

=head1 COPYRIGHT AND LICENSE

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 1999-2005, Darren R. Duncan.  All rights reserved.
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
my $IPROP_SRT_NODE = 'srt_node'; # ref to SQL::Routine Node providing context for this Intf
	# If we are an 'Application' Interface, this would be an 'application_instance' Node.
	# If we are a 'Preparation' Interface, this would be a 'routine' Node.
	# If we are any other kind of interface, this is a second ref to same SRT the parent 'prep' has.
my $IPROP_ROUTINE = 'routine'; # ref to a Perl anonymous subroutine; this property must be 
	# set for Preparation interfaces and must not be set for other types.
	# An Engine's prepare() method will create this sub when it creates a Preparation Interface.
	# When calling execute(), the Interface will simply invoke the sub; no Engine execute() called.
my $IPROP_TRACE_FH = 'trace_fh'; # ref to writeable Perl file handle
	# This property is set after Intf creation and can be cleared or set at any time.
	# When set, details of what Rosetta is doing will be written to the file handle; 
	# to turn off the tracing, just clear the property.  This property can only be set on an 
	# Application Intf; but it can be accessed through methods on any child Intf also.

# Names of properties for objects of the Rosetta::Engine class are declared here:
	 # No properties (yet) are declared by this parent class; leaving space free for child classes

# Names of properties for objects of the Rosetta::Dispatcher class are declared here:
my $DPROP_LIT_PAYLOAD = 'lit_payload'; # If Eng fronts a Literal Intf, put payload it represents here.

# Names of the allowed Interface types go here:
our $INTFTP_ERROR       = 'Error'; # What is returned if an error happens, in place of another Intf type
our $INTFTP_SUCCESS     = 'Success'; # What is returned if a 'procedure' succeeds / does not throw an Error
our $INTFTP_APPLICATION = 'Application'; # What you get when you create an Interface out of any context
	# This type is the root of an Interface tree; when you create one, you provide an 
	# "application_instance" SQL::Routine Node; that provides the necessary context for 
	# subsequent "routine" Nodes you pass to any child Intf's "prepare" method.
our $INTFTP_PREPARATION = 'Preparation'; # That which is returned by the 'prepare()' method
our $INTFTP_LITERAL     = 'Literal'; # Result of execution that isn't one of the following, like an IUD
	# This type can be returned as the grand-child for any of [Appl, Envi, Conn, Curs].
	# This type is returned by the execute() of any Command that doesn't return one of 
	# [Err,Succ,Env,Conn,Curs].
	# Any routines that stuff new Nodes in the current SRT Container, such as the 
	# *_LIST or *_INFO or *_CLONE built-in routines, will return a new Node ref or list as the payload.
	# Any routines that simply do a yes/no test, such as *_VERIFY, or CATALOG_PING, 
	# simply have a boolean payload.
	# IUD commands usually return this, plus method calls; payload may be a hash ref of results.
our $INTFTP_ENVIRONMENT = 'Environment'; # Parent to all Connection INTFs impl by same Engine
our $INTFTP_CONNECTION  = 'Connection'; # Represents a context var having SRT container_type of 'CONN'.
our $INTFTP_CURSOR      = 'Cursor'; # Represents a context var having SRT container_type of 'CURSOR'.
my %ALL_INTFTP = ( map { ($_ => 1) } (
	$INTFTP_ERROR, $INTFTP_SUCCESS, 
	$INTFTP_APPLICATION, $INTFTP_PREPARATION, $INTFTP_LITERAL, 
	$INTFTP_ENVIRONMENT, $INTFTP_CONNECTION, $INTFTP_CURSOR, 
) );

# Names of all possible features that a Rosetta Engine can claim to support, 
# and that Rosetta::Validator will individually test for.
# This list may resemble SQL::Routine's "standard_routine" enumerated list in part, 
# but it is a lot more broad than that.
my %POSSIBLE_FEATURES = map { ($_ => 1) } qw(
	CATALOG_LIST CATALOG_INFO 

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

# Names of SRT Node types and attributes that may be given in SETUP_OPTIONS for build_connection():
my %BC_SETUP_NODE_TYPES = ();
foreach my $_node_type (qw( 
			data_storage_product data_link_product catalog_instance catalog_link_instance
		)) {
	my $attrs = $BC_SETUP_NODE_TYPES{$_node_type} = {}; # node type accepts only specific key names
	foreach my $attr_name (keys %{SQL::Routine->valid_node_type_literal_attributes( $_node_type )}) {
		$attr_name eq 'si_name' and next;
		$attrs->{$attr_name} = 1;
	}
	# None of these types have enumerated attrs, but if they did, we would add them too.
	# We don't get nref attrs in any case.
}
$BC_SETUP_NODE_TYPES{'catalog_instance_opt'} = 1; # node type accepts any key name
$BC_SETUP_NODE_TYPES{'catalog_link_instance_opt'} = 1; # node type accepts any key name

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	# Throws an exception consisting of an object.  A Rosetta property is not 
	# used to store object so things work properly in multi-threaded environment; 
	# an exception is only supposed to affect the thread that calls it.
	ref($args) eq 'HASH' or $args = {};
	$args->{'CLASS'} ||= ref($self); # Mainly used when invoked by Engines.
	die Locale::KeyedText->new_message( $error_code, $args );
}

######################################################################
# These are 'protected' methods; only sub-classes should invoke them.

sub _build_node_auto_name {
	my ($self, $container, $node_type, $attrs) = @_;
	my $node_id = $container->get_next_free_node_id();
	my $si_name = 'Rosetta Default '.
		join( ' ', map { ucfirst( $_ ) } split( '_', $node_type ) ).' '.$node_id;
	return $container->build_node( $node_type, 
		{ 'si_name' => $si_name, %{$attrs || {}} } );
}

sub _build_child_node_auto_name {
	my ($self, $pp_node, $node_type, $attrs) = @_;
	my $container = $pp_node->get_container();
	my $node_id = $container->get_next_free_node_id();
	my $si_name = 'Rosetta Default '.
		join( ' ', map { ucfirst( $_ ) } split( '_', $node_type ) ).' '.$node_id;
	return $pp_node->build_child_node( $node_type, 
		{ 'si_name' => $si_name, %{$attrs || {}} } );
}

######################################################################
# This is a convenience wrapper method; its sole argument is a SRT Node.

sub new_application {
	return Rosetta::Interface->new( $INTFTP_APPLICATION, undef, undef, undef, $_[1] );
}

######################################################################

sub build_application {
	my ($self) = @_;
	my $container = SQL::Routine->new_container();
	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );
	my $app_bp_node = $self->_build_node_auto_name( $container, 'application' );
	my $app_inst_node = $self->_build_node_auto_name( $container, 'application_instance', 
		{ 'blueprint' => $app_bp_node } );
	$container->auto_set_node_ids( $orig_asni_vl );
	my $app_intf = Rosetta->new_application( $app_inst_node );
	return $app_intf;
}

sub build_application_with_node_trees {
	my ($self, @args) = @_;
	my $container = SQL::Routine->build_container( @args );
	my $app_inst_node = @{$container->get_child_nodes( 'application_instance' )}[0];
	my $app_intf = Rosetta->new_application( $app_inst_node );
	return $app_intf;
}

sub build_environment {
	my ($self, @args) = @_;
	my $app_intf = $self->build_application();
	my $env_intf = $app_intf->build_child_environment( @args );
	return $env_intf;
}

sub build_connection {
	my ($self, @args) = @_;
	my $app_intf = $self->build_application();
	my $conn_intf = $app_intf->build_child_connection( @args );
	return $conn_intf;
}

######################################################################

sub validate_connection_setup_options {
	my ($self, $setup_options) = @_;
	defined( $setup_options ) or $self->_throw_error_message( 'ROS_I_V_CONN_SETUP_OPTS_NO_ARG' );
	unless( ref($setup_options) eq 'HASH' ) {
		$self->_throw_error_message( 'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG', { 'ARG' => $setup_options } );
	}
	while( my ($node_type, $rh_attrs) = each %{$setup_options} ) {
		unless( $BC_SETUP_NODE_TYPES{$node_type} ) {
			$self->_throw_error_message( 'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG_NTYPE', 
			{ 'GIVEN' => $node_type, 'ALLOWED' => "@{[keys %BC_SETUP_NODE_TYPES]}" } );
		}
		defined( $rh_attrs ) or $self->_throw_error_message( 
			'ROS_I_V_CONN_SETUP_OPTS_NO_ARG_ELEM', { 'NTYPE' => $node_type } );
		unless( ref($rh_attrs) eq 'HASH' ) {
			$self->_throw_error_message( 'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG_ELEM', 
				{ 'NTYPE' => $node_type, 'ARG' => $rh_attrs } );
		}
		ref($BC_SETUP_NODE_TYPES{$node_type}) eq 'HASH' or next; # all opt names accepted
		while( my ($option_name, $option_value) = each %{$rh_attrs} ) {
			unless( $BC_SETUP_NODE_TYPES{$node_type}->{$option_name} ) {
				$self->_throw_error_message( 'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG_OPTNM', 
					{ 'NTYPE' => $node_type, 'GIVEN' => $option_name, 
					'ALLOWED' => "@{[keys %{$BC_SETUP_NODE_TYPES{$node_type}}]}" } );
			}
		}
	}
	unless( $setup_options->{'data_link_product'} and 
			$setup_options->{'data_link_product'}->{'product_code'} ) {
		$self->_throw_error_message( 'ROS_I_V_CONN_SETUP_OPTS_NO_ENG_NM' );
	}
}

######################################################################
######################################################################

package Rosetta::Interface;
use base qw( Rosetta );

######################################################################

sub new {
	# Make a new Interface with basically all props set now and not changed later.
	my ($class, $intf_type, $err_msg, $parent_intf, $engine, $srt_node, $routine) = @_;
	my $interface = bless( {}, ref($class) || $class );

	$interface->_validate_properties_to_be( 
		$intf_type, $err_msg, $parent_intf, $engine, $srt_node, $routine );

	unless( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_SUCCESS ) {
		# If type was Application or Preparation, $srt_node would already be set.
		# Anything else except Error and Success has a parent.
		$srt_node ||= $parent_intf->{$IPROP_SRT_NODE}; # Copy from parent Preparation if applicable.
	}
	$interface->{$IPROP_INTF_TYPE} = $intf_type;
	$interface->{$IPROP_ERROR_MSG} = $err_msg;
	$interface->{$IPROP_PARENT_INTF} = $parent_intf;
	$interface->{$IPROP_ROOT_INTF} = $parent_intf ? $parent_intf->{$IPROP_ROOT_INTF} : 
		($intf_type eq $INTFTP_APPLICATION) ? $interface : undef;
	$interface->{$IPROP_CHILD_INTFS} = [];
	$interface->{$IPROP_ENGINE} = ($intf_type eq $INTFTP_APPLICATION) ? 
		Rosetta::Dispatcher->new() : $engine;
	$interface->{$IPROP_SRT_NODE} = $srt_node;
	$interface->{$IPROP_ROUTINE} = $routine;
	$interface->{$IPROP_TRACE_FH} = undef;
	$parent_intf and push( @{$parent_intf->{$IPROP_CHILD_INTFS}}, $interface );

	return $interface;
}

sub _validate_properties_to_be {
	my ($interface, $intf_type, $err_msg, $parent_intf, $engine, $srt_node, $routine) = @_;

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
	if( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_SUCCESS or $intf_type eq $INTFTP_APPLICATION ) {
		defined( $engine ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_ENG', { 'TYPE' => $intf_type } );
	} else {
		defined( $engine ) or $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_NO_ENG', { 'TYPE' => $intf_type } );
		unless( ref($engine) and UNIVERSAL::isa( $engine, 'Rosetta::Engine' ) ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_ENG', { 'ENG' => $engine } );
		}
	}

	# Check $srt_node, must be given for Application or Preparation, 
	# must not be given otherwise (incl Error).  $srt_node is always set to its 
	# parent Preparation when arg must not be given, except when Error.
	$interface->_validate_srt_node( 'ROS_I_NEW_INTF', $intf_type, $srt_node, $parent_intf );

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

	if( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_SUCCESS or $intf_type eq $INTFTP_APPLICATION ) {
		defined( $parent_intf ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_PARENT', { 'TYPE' => $intf_type } );
		# $parent_intf seems to check out fine.
		return;
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
				$p_intf_type eq $INTFTP_CONNECTION or $p_intf_type eq $INTFTP_CURSOR ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_P_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type } );
		}
		return; # Skip the other tests
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
				or $pp_intf_type eq $INTFTP_CONNECTION or $pp_intf_type eq $INTFTP_CURSOR ) {
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
	} else { # $intf_type eq $INTFTP_CURSOR
		unless( $pp_intf_type eq $INTFTP_CONNECTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	}

	# $parent_intf seems to check out fine.
}

sub _validate_srt_node {
	my ($interface, $error_key_pfx, $intf_type, $srt_node, $parent_intf) = @_;

	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_PREPARATION ) {
		defined( $srt_node ) and $interface->_throw_error_message( 
			$error_key_pfx.'_YES_NODE', { 'TYPE' => $intf_type } );
		# $srt_node seems to check out fine.
		return;
	}

	# If we get here, we have an APPLICATION or a PREPARATION.

	defined( $srt_node ) or $interface->_throw_error_message( 
		$error_key_pfx.'_NO_NODE', { 'TYPE' => $intf_type } );
	unless( ref($srt_node) and UNIVERSAL::isa( $srt_node, 'SQL::Routine::Node' ) ) {
		$interface->_throw_error_message( $error_key_pfx.'_BAD_NODE', { 'SRT' => $srt_node } );
	}
	my $given_container = $srt_node->get_container();
	unless( $given_container ) {
		$interface->_throw_error_message( $error_key_pfx.'_NODE_NOT_IN_CONT' );
	}
	$given_container->assert_deferrable_constraints(); # SRT throws own exceptions on problem.
	if( $parent_intf ) {
		my $expected_container = $parent_intf->{$IPROP_SRT_NODE}->get_container();
		# Above line assumes parent Intf's Node not taken from Container since put in parent.
		if( $given_container ne $expected_container ) {
			$interface->_throw_error_message( $error_key_pfx.'_NODE_NOT_SAME_CONT' );
		}
	}

	# If we get here, we have a valid SRT Node, that may be any kind of Node.

	my $node_type = $srt_node->get_node_type();

	if( $intf_type eq $INTFTP_APPLICATION ) {
		unless( $node_type eq 'application_instance' ) {
			$interface->_throw_error_message( $error_key_pfx.'_NODE_TYPE_NOT_SUPP', 
				{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type } );
		}
		# $srt_node seems to check out fine.
		return;
	}

	# If we get here, we have a PREPARATION.

	if( $node_type eq 'data_link_product' ) {
		my $p_intf_type = $parent_intf->{$IPROP_INTF_TYPE};
		unless( $p_intf_type eq $INTFTP_APPLICATION ) {
			$interface->_throw_error_message( $error_key_pfx.'_NODE_TYPE_NOT_SUPP_UNDER_P', 
				{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type, 'PITYPE' => $p_intf_type } );
		}
	} else {
		unless( $node_type eq 'routine' ) {
			$interface->_throw_error_message( $error_key_pfx.'_NODE_TYPE_NOT_SUPP', 
				{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type } );
		}
	}

	# $srt_node seems to check out fine.
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
		@{$siblings} = grep { $_ ne $interface } @{$siblings}; # should only be one link; break all
	}

	# Now break any links from ourself to other things, and destroy ourself.
	%{$interface} = ();

	# Finally, once any external refs to us are gone, we get garbage collected.
}

######################################################################

sub get_interface_type {
	return $_[0]->{$IPROP_INTF_TYPE};
}

######################################################################

sub get_error_message {
	# This method returns the Message object by reference.
	return $_[0]->{$IPROP_ERROR_MSG};
}

######################################################################

sub get_parent_interface {
	# This method returns the Interface object by reference.
	return $_[0]->{$IPROP_PARENT_INTF};
}

######################################################################

sub get_root_interface {
	# This method returns the Interface object by reference.
	return $_[0]->{$IPROP_ROOT_INTF};
}

######################################################################

sub get_child_interfaces {
	# This method returns each Interface object by reference.
	return [@{$_[0]->{$IPROP_CHILD_INTFS}}];
}

######################################################################

sub get_sibling_interfaces {
	# This method returns each Interface object by reference.
	my ($interface, $skip_self) = @_;
	my $parent_intf = $interface->{$IPROP_PARENT_INTF};
	if( $parent_intf ) {
		return $skip_self ? 
			[grep { $_ ne $interface } @{$parent_intf->{$IPROP_CHILD_INTFS}}] : 
			[@{$parent_intf->{$IPROP_CHILD_INTFS}}];
	} else {
		return $skip_self ? [] : [$interface];
	}
}

######################################################################
# We may not keep this method

sub get_engine {
	return $_[0]->{$IPROP_ENGINE};
}

######################################################################

sub get_srt_node {
	# This method returns the Node object by reference.
	return $_[0]->{$IPROP_SRT_NODE};
}

sub get_srt_container {
	if( my $app_intf = $_[0]->{$IPROP_ROOT_INTF} ) {
		return $app_intf->{$IPROP_SRT_NODE}->get_container();
	}
	return;
}

######################################################################
# We may not keep this method

sub get_routine {
	return $_[0]->{$IPROP_ROUTINE};
}

######################################################################

sub get_trace_fh {
	my ($interface) = @_;
	my $app_intf = $interface->{$IPROP_ROOT_INTF};
	return $app_intf ? $app_intf->{$IPROP_TRACE_FH} : undef;
}

sub clear_trace_fh {
	my ($interface) = @_;
	if( my $app_intf = $interface->{$IPROP_ROOT_INTF} ) {
		$app_intf->{$IPROP_TRACE_FH} = undef;
	}
}

sub set_trace_fh {
	my ($interface, $new_fh) = @_;
	if( my $app_intf = $interface->{$IPROP_ROOT_INTF} ) {
		$app_intf->{$IPROP_TRACE_FH} = $new_fh;
	}
}

######################################################################

sub features {
	my ($interface, $feature_name) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT or 
			$intf_type eq $INTFTP_CONNECTION ) {
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
		return $interface->{$IPROP_ENGINE}->features( $interface, $feature_name );
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
	return $result;
}

######################################################################

sub prepare {
	my ($interface, $routine_defn) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT or 
			$intf_type eq $INTFTP_CONNECTION or $intf_type eq $INTFTP_CURSOR ) {
		$interface->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'prepare', 'ITYPE' => $intf_type } );
	}
	# From this point onward, an Interface object will be made, and any errors will go in it.
	my $preparation = eval {
		# An eval block is like a routine body.
		# This test of our SRT Node argument is a bootstrap of sorts; the Interface->new() 
		# method will do the same tests when it is called later; return same errors it would have; 
		# actually, return slightly differently worded errors, show different method name.
		$interface->_validate_srt_node( 'ROS_I_PREPARE', $INTFTP_PREPARATION, $routine_defn, $interface );
		# Now we get to doing the real work we were called for.
		if( $routine_defn->get_node_type() eq 'data_link_product' ) {
			# We only get here if $interface is a APPLICATION.
			return $interface->_prepare_lpn( $routine_defn );
		} else { # the Node type is a $SRTNTP_ROUTINE
			# We can get here for any $interface not blocked at the door: APPL, ENVI, CONN, CURS.
			return $interface->{$IPROP_ENGINE}->prepare( $interface, $routine_defn );
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
	return $preparation;
}

sub _prepare_lpn {
	my ($app_intf, $link_prod_node) = @_;
	my $engine_name = $link_prod_node->get_literal_attribute( 'product_code' );
	my $env_prep_intf = undef;
	foreach my $ch_env_prep_intf (@{$app_intf->{$IPROP_CHILD_INTFS}}) {
		if( $ch_env_prep_intf->{$IPROP_SRT_NODE} eq $link_prod_node ) {
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
			return $rtv_env_intf;
		};
		my $env_prep_eng = $engine_name->new();
		$env_prep_intf = $app_intf->new( $INTFTP_PREPARATION, undef, 
			$app_intf, $env_prep_eng, $link_prod_node, $routine );
	}
	return $env_prep_intf;
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
			return $preparation->{$IPROP_CHILD_INTFS}->[0];
		} else {
			return $preparation->{$IPROP_ROUTINE}->( 
				$preparation->{$IPROP_ENGINE}, $preparation, $routine_args );
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
	unless( $res_intf_type eq $INTFTP_ERROR or $res_intf_type eq $INTFTP_SUCCESS ) {
		# Result is not an Error or Success, so must belong to our Intf tree.
		unless( $result->{$IPROP_ROOT_INTF} eq $preparation->{$IPROP_ROOT_INTF} ) {
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_BAD_RESULT_WRONG_ITREE', { 'CLASS' => $engine_name, 'ITYPE' => $intf_type } ) );
		} elsif( $res_intf_type eq $INTFTP_PREPARATION or $res_intf_type eq $INTFTP_APPLICATION ) {
			# Non-Error/Success result of execute() must be one of [Lit, Env, Conn, Trans, Curs].
			# We do not validate here for having the exact right kind as criteria is complicated.
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_BAD_RESULT_WRONG_ITYPE', 
				{ 'CLASS' => $engine_name, 'ITYPE' => $intf_type, 'RET_ITYPE' => $res_intf_type } ) );
		}
	}
	if( $result->{$IPROP_ERROR_MSG} ) {
		die $result;
	}
	return $result;
}

######################################################################

sub do {
	my ($interface, $routine_defn, $routine_args) = @_;
	my $preparation = $interface->prepare( $routine_defn ); # prepare-time exceptions not caught
	my $result = eval {
		return $preparation->execute( $routine_args );
	};
	my $exception = $@;
	if( $exception or $result->{$IPROP_INTF_TYPE} eq $INTFTP_SUCCESS ) {
		# The $result is not connected to the $preparation, or there is no $result.
		$preparation->destroy(); # The $preparation has no child, the caller has no handle to it.
	}
	$exception and die $exception; # Re-throw any execute-time exception object or Perl error.
	return $result;
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
		return $lit_intf->{$IPROP_ENGINE}->payload( $lit_intf );
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$lit_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'payload', 'CLASS' => ref($lit_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return $result;
}

######################################################################

sub routine_source_code {
	my ($env_intf, $routine_node) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $env_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_ENVIRONMENT ) {
		$env_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'routine_source_code', 'ITYPE' => $intf_type } );
	}
	# Now we get to doing the real work we were called for.
	my $result = eval {
		# An eval block is like a routine body.
		return $env_intf->{$IPROP_ENGINE}->routine_source_code( $env_intf, $routine_node );
	};
	if( my $exception = $@ ) {
		unless( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			$env_intf->_throw_error_message( 'ROS_I_METH_MISC_EXCEPTION', 
				{ 'METH' => 'routine_source_code', 'CLASS' => ref($env_intf->{$IPROP_ENGINE}), 
				'ITYPE' => $intf_type, 'VALUE' => $exception } );
		}
	}
	return $result;
}

######################################################################

sub build_child_environment {
	my ($app_intf, $engine_name) = @_;
	my $intf_type = $app_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION ) {
		$app_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'build_child_environment', 'ITYPE' => $intf_type } );
	}
	defined( $engine_name ) or $app_intf->_throw_error_message( 'ROS_I_BUILD_CH_ENV_NO_ARG' );
	my $container = $app_intf->get_srt_container();
	my $env_intf = undef;
	foreach my $ch_env_prep_intf (@{$app_intf->{$IPROP_CHILD_INTFS}}) {
		if( $ch_env_prep_intf->{$IPROP_SRT_NODE}->get_literal_attribute( 'product_code' ) eq $engine_name ) {
			$env_intf = $ch_env_prep_intf->execute(); # may or may not have executed before; ret same Env if did
			last;
		}
	}
	unless( $env_intf ) {
		my $dlp_node = $container->build_node( 'data_link_product', 
			{ 'id' => $container->get_next_free_node_id(), 
			'si_name' => $engine_name, 'product_code' => $engine_name } );
		$env_intf = $app_intf->do( $dlp_node ); # dies if bad Engine
	}
	return $env_intf;
}

######################################################################

sub build_child_connection {
	my ($interface, $setup_options, $rt_si_name, $rt_id) = @_;
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT ) {
		$interface->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'build_child_connection', 'ITYPE' => $intf_type } );
	}

	$interface->validate_connection_setup_options( $setup_options ); # dies on input errors

	my $env_intf = undef;
	if( $intf_type eq $INTFTP_ENVIRONMENT ) {
		$env_intf = $interface;
	} else { # $intf_type eq $INTFTP_APPLICATION
		my %dlp_setup = %{$setup_options->{'data_link_product'} || {}};
		$env_intf = $interface->build_child_environment( $dlp_setup{'product_code'} );
	}
	my $dlp_node = $env_intf->get_srt_node();

	my $container = $interface->get_srt_container();
	my $app_inst_node = $interface->get_root_interface()->get_srt_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $cat_bp_node = $interface->_build_node_auto_name( $container, 'catalog' );

	my $cat_link_bp_node = $interface->_build_child_node_auto_name( $app_bp_node, 'catalog_link', 
		{ 'target' => $cat_bp_node } );

	my $routine_node = $interface->_build_child_node_auto_name( $app_bp_node, 'routine', 
		{ 'routine_type' => 'FUNCTION', 'return_cont_type' => 'CONN' } );
	defined( $rt_si_name ) and $routine_node->set_literal_attribute( 'si_name', $rt_si_name );
	defined( $rt_id ) and $routine_node->set_node_id( $rt_id );
	{
		my $rtv_conn_cx_node = $routine_node->build_child_node( 'routine_var', 
			{ 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => $cat_link_bp_node } );
		$routine_node->build_child_node_tree( 'routine_stmt', 
			{ 'call_sroutine' => 'RETURN' }, 
			[
				[ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 
					'cont_type' => 'CONN', 'valf_p_routine_item' => $rtv_conn_cx_node } ],
			],
		);
	}

	my $dsp_node = $interface->_build_node_auto_name( $container, 'data_storage_product', 
		$setup_options->{'data_storage_product'} );

	my $cat_inst_node = $interface->_build_node_auto_name( $container, 'catalog_instance', 
		{ 'product' => $dsp_node, 'blueprint' => $cat_bp_node, %{$setup_options->{'catalog_instance'} || {}} } );
	while( my ($opt_key, $opt_value) = each %{$setup_options->{'catalog_instance_opt'} || {}} ) {
		$cat_inst_node->build_child_node( 'catalog_instance_opt', 
			{ 'si_key' => $opt_key, 'value' => $opt_value } );
	}

	my $cat_link_inst_node = $app_inst_node->build_child_node( 'catalog_link_instance', 
		{ 'product' => $dlp_node, 'blueprint' => $cat_link_bp_node, 'target' => $cat_inst_node, 
		%{$setup_options->{'catalog_link_instance'} || {}} } );
	while( my ($opt_key, $opt_value) = each %{$setup_options->{'catalog_link_instance_opt'} || {}} ) {
		$cat_link_inst_node->build_child_node( 'catalog_link_instance_opt', 
			{ 'si_key' => $opt_key, 'value' => $opt_value } );
	}

	$container->auto_set_node_ids( $orig_asni_vl );

	my $conn_intf = $env_intf->do( $routine_node );
	return $conn_intf;
}

######################################################################

sub destroy_interface_tree {
	my ($interface) = @_;
	my $container = $interface->get_srt_container();
	my $app_intf = $interface->get_root_interface();
	$app_intf->_destroy_interface_tree();
	return $container;
}

sub _destroy_interface_tree {
	my ($interface) = @_;
	foreach my $child (@{$interface->get_child_interfaces()}) {
		$child->_destroy_interface_tree();
	}
	$interface->destroy();
}

sub destroy_interface_tree_and_srt_container {
	my ($interface) = @_;
	my $container = $interface->destroy_interface_tree();
	$container->destroy();
}

######################################################################

sub sroutine_catalog_list {
	my ($interface, $rt_si_name, $rt_id) = @_;
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT ) {
		$interface->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'sroutine_catalog_list', 'ITYPE' => $intf_type } );
	}

	my $container = $interface->get_srt_container();
	my $app_inst_node = $interface->get_root_interface()->get_srt_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $routine_node = $interface->_build_child_node_auto_name( $app_bp_node, 'routine', 
		{ 'routine_type' => 'FUNCTION', 'return_cont_type' => 'SRT_NODE_LIST' } );
	defined( $rt_si_name ) and $routine_node->set_literal_attribute( 'si_name', $rt_si_name );
	defined( $rt_id ) and $routine_node->set_node_id( $rt_id );
	{
		$routine_node->build_child_node_tree( 'routine_stmt', 
			{ 'call_sroutine' => 'RETURN' }, 
			[
				[ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 
					'cont_type' => 'SRT_NODE_LIST', 'valf_call_sroutine' => 'CATALOG_LIST' } ],
			],
		);
	}

	$container->auto_set_node_ids( $orig_asni_vl );

	my $prep_intf = $interface->prepare( $routine_node );
	return $prep_intf;
}

######################################################################

sub sroutine_catalog_open {
	my ($conn_intf, $rt_si_name, $rt_id) = @_;
	my $intf_type = $conn_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CONNECTION ) {
		$conn_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'sroutine_catalog_open', 'ITYPE' => $intf_type } );
	}

	my $container = $conn_intf->get_srt_container();
	my $app_inst_node = $conn_intf->get_root_interface()->get_srt_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $conn_routine_node = $conn_intf->get_srt_node();
	my $cat_link_bp_node = (
		grep { $_->get_enumerated_attribute( 'cont_type' ) eq 'CONN' } 
		@{$conn_routine_node->get_child_nodes( 'routine_var' )}
		)[0]->get_node_ref_attribute( 'conn_link' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $sdt_auth_node = $conn_intf->_build_node_auto_name( $container, 'scalar_data_type', 
		{ 'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8' } );

	my $routine_node = $conn_intf->_build_child_node_auto_name( $app_bp_node, 'routine', 
		{ 'routine_type' => 'PROCEDURE' } );
	defined( $rt_si_name ) and $routine_node->set_literal_attribute( 'si_name', $rt_si_name );
	defined( $rt_id ) and $routine_node->set_node_id( $rt_id );
	{
		my $rtc_conn_cx_node = $routine_node->build_child_node( 'routine_context', 
			{ 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => $cat_link_bp_node } );
		my $rta_user_node = $routine_node->build_child_node( 'routine_arg', 
			{ 'si_name' => 'login_name', 'cont_type' => 'SCALAR', 'scalar_data_type' => $sdt_auth_node } );
		my $rta_pass_node = $routine_node->build_child_node( 'routine_arg', 
			{ 'si_name' => 'login_pass', 'cont_type' => 'SCALAR', 'scalar_data_type' => $sdt_auth_node } );
		$routine_node->build_child_node_tree( 'routine_stmt', 
			{ 'call_sroutine' => 'CATALOG_OPEN' }, 
			[
				[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 
					'cont_type' => 'CONN', 'valf_p_routine_item' => $rtc_conn_cx_node } ],
				[ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_NAME', 
					'cont_type' => 'SCALAR', 'valf_p_routine_item' => $rta_user_node } ],
				[ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_PASS', 
					'cont_type' => 'SCALAR', 'valf_p_routine_item' => $rta_pass_node } ],
			],
		);
	}

	$container->auto_set_node_ids( $orig_asni_vl );

	my $prep_intf = $conn_intf->prepare( $routine_node );
	return $prep_intf;
}

######################################################################

sub sroutine_catalog_close {
	my ($conn_intf, $rt_si_name, $rt_id) = @_;
	my $intf_type = $conn_intf->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CONNECTION ) {
		$conn_intf->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'sroutine_catalog_close', 'ITYPE' => $intf_type } );
	}

	my $container = $conn_intf->get_srt_container();
	my $app_inst_node = $conn_intf->get_root_interface()->get_srt_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $conn_routine_node = $conn_intf->get_srt_node();
	my $cat_link_bp_node = (
		grep { $_->get_enumerated_attribute( 'cont_type' ) eq 'CONN' } 
		@{$conn_routine_node->get_child_nodes( 'routine_var' )}
		)[0]->get_node_ref_attribute( 'conn_link' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $routine_node = $conn_intf->_build_child_node_auto_name( $app_bp_node, 'routine', 
		{ 'routine_type' => 'PROCEDURE' } );
	defined( $rt_si_name ) and $routine_node->set_literal_attribute( 'si_name', $rt_si_name );
	defined( $rt_id ) and $routine_node->set_node_id( $rt_id );
	{
		my $rtc_conn_cx_node = $routine_node->build_child_node( 'routine_context', 
			{ 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => $cat_link_bp_node } );
		$routine_node->build_child_node_tree( 'routine_stmt', 
			{ 'call_sroutine' => 'CATALOG_CLOSE' }, 
			[
				[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 
					'cont_type' => 'CONN', 'valf_p_routine_item' => $rtc_conn_cx_node } ],
			],
		);
	}

	$container->auto_set_node_ids( $orig_asni_vl );

	my $prep_intf = $conn_intf->prepare( $routine_node );
	return $prep_intf;
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

sub routine_source_code {
	my ($env_eng, $env_intf, $routine_node) = @_;
	$env_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'routine_source_code', 'CLASS' => ref($env_eng) } );
}

######################################################################
######################################################################

package Rosetta::Dispatcher;
use base qw( Rosetta::Engine );

######################################################################

sub new {
	my ($class) = @_;
	my $engine = bless( {}, ref($class) || $class );
	return $engine;
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
	my $container = $app_intf->get_srt_container();
	foreach my $link_prod_node (@{$container->get_child_nodes( 'data_link_product' )}) {
		my $env_intf = $app_intf->do( $link_prod_node );
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
			return $result;
		}
		while( @results > 0 ) {
			my $next_result = shift( @results );
			if( !defined( $next_result ) or $next_result ne $result ) {
				$result = undef; last;
			}
			# so far, both $result and $next_result have the same 1 or 0 value
		}
		return $result;

	} else {
		my $result = shift( @results ) || {}; # returns {} if no Engines
		if( (keys %{$result}) == 0 ) {
			return $result;
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
		return $result;
	}
}

######################################################################

sub prepare {
	# This method assumes that it is only called on Application Interfaces.
	my ($app_eng, $app_intf, $routine_node) = @_;
	my $prep_intf = undef;
	SEARCH: {
		foreach my $routine_context_node (@{$routine_node->get_child_nodes( 'routine_context' )}) {
			if( my $cat_link_bp_node = $routine_context_node->get_node_ref_attribute( 'conn_link' ) ) {
				$prep_intf = $app_eng->_prepare__call_engine( $app_intf, $routine_node, $cat_link_bp_node );
				last SEARCH;
			}
		}
		foreach my $routine_arg_node (@{$routine_node->get_child_nodes( 'routine_arg' )}) {
			if( my $cat_link_bp_node = $routine_arg_node->get_node_ref_attribute( 'conn_link' ) ) {
				$prep_intf = $app_eng->_prepare__call_engine( $app_intf, $routine_node, $cat_link_bp_node );
				last SEARCH;
			}
		}
		foreach my $routine_var_node (@{$routine_node->get_child_nodes( 'routine_var' )}) {
			if( my $cat_link_bp_node = $routine_var_node->get_node_ref_attribute( 'conn_link' ) ) {
				$prep_intf = $app_eng->_prepare__call_engine( $app_intf, $routine_node, $cat_link_bp_node );
				last SEARCH;
			}
		}
		foreach my $routine_stmt_node (@{$routine_node->get_child_nodes( 'routine_stmt' )}) {
			if( my $sroutine_name = $routine_stmt_node->get_enumerated_attribute( 'call_sroutine' ) ) {
				if( $sroutine_name eq 'CATALOG_LIST' ) {
					$prep_intf = $app_eng->_prepare__srtn_cat_list( $app_intf, $routine_node );
					last SEARCH;
				}
			}
			$prep_intf = $app_eng->_prepare__recurse( $app_intf, $routine_node, $routine_stmt_node );
			$prep_intf and last SEARCH;
		}
		$app_eng->_throw_error_message( 'ROS_D_PREPARE_NO_ENGINE_DETERMINED' );
	}
	return $prep_intf;
}

sub _prepare__recurse {
	my ($app_eng, $app_intf, $routine_node, $routine_stmt_or_expr_node) = @_;
	my $prep_intf = undef;
	foreach my $routine_expr_node (@{$routine_stmt_or_expr_node->get_child_nodes()}) {
		if( my $sroutine_name = $routine_expr_node->get_enumerated_attribute( 'valf_call_sroutine' ) ) {
			if( $sroutine_name eq 'CATALOG_LIST' ) {
				$prep_intf = $app_eng->_prepare__srtn_cat_list( $app_intf, $routine_node );
				last;
			}
		}
		$prep_intf = $app_eng->_prepare__recurse( $app_intf, $routine_node, $routine_expr_node );
		$prep_intf and last;
	}
	return $prep_intf;
}

sub _prepare__srtn_cat_list {
	my ($app_eng, $app_intf, $routine_node) = @_;

	my @lit_prep_intfs = ();
	my $container = $routine_node->get_container();
	foreach my $link_prod_node (@{$container->get_child_nodes( 'data_link_product' )}) {
		my $env_intf = $app_intf->do( $link_prod_node );
		my $lit_prep_intf = $env_intf->prepare( $routine_node );
		push( @lit_prep_intfs, $lit_prep_intf );
	}

	my $routine = sub {
		# This routine is a closure.
		my ($rtv_lit_prep_eng, $rtv_lit_prep_intf, $rtv_args) = @_;

		my @cat_link_bp_nodes = ();

		foreach my $lit_prep_intf (@lit_prep_intfs) {
			my $lit_intf = $lit_prep_intf->execute();
			my $payload = $lit_intf->payload();
			push( @cat_link_bp_nodes, @{$payload} );
		}

		my $rtv_lit_eng = $rtv_lit_prep_eng->new();
		$rtv_lit_eng->{$DPROP_LIT_PAYLOAD} = \@cat_link_bp_nodes;

		my $rtv_lit_intf = $rtv_lit_prep_intf->new( $INTFTP_LITERAL, undef, 
			$rtv_lit_prep_intf, $rtv_lit_eng );
		return $rtv_lit_intf;
	};

	my $lit_prep_eng = $app_eng->new();

	my $lit_prep_intf = $app_intf->new( $INTFTP_PREPARATION, undef, 
		$app_intf, $lit_prep_eng, $routine_node, $routine );
	return $lit_prep_intf;
}

sub _prepare__call_engine {
	my ($app_eng, $app_intf, $routine_node, $cat_link_bp_node) = @_;

	# Now figure out link product by cross-referencing app inst with cat link bp.
	my $app_inst_node = $app_intf->get_srt_node();
	my $cat_link_inst_node = undef;
	foreach my $link (@{$app_inst_node->get_child_nodes( 'catalog_link_instance' )}) {
		if( $link->get_node_ref_attribute( 'blueprint' ) eq $cat_link_bp_node ) {
			$cat_link_inst_node = $link;
			last;
		}
	}
	my $link_prod_node = $cat_link_inst_node->get_node_ref_attribute( 'product' );

	# Now make sure that the Engine we need is loaded.
	my $env_intf = $app_intf->do( $link_prod_node );
	# Now repeat the command we ourselves were given against a specific Environment Interface.
	my $prep_intf = $env_intf->prepare( $routine_node );
	return $prep_intf;
}

######################################################################

sub payload {
	my ($lit_eng, $lit_intf) = @_;
	return $lit_eng->{$DPROP_LIT_PAYLOAD};
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<The previous SYNOPSIS was removed; a new one will be written later.>

=head1 DESCRIPTION

The Rosetta Perl 5 module defines a complete and rigorous API for database
access that provides hassle-free portability between many dozens of database
products for database-using applications of any size and complexity, that
leverage all sorts of advanced database product features.  The Rosetta Native
Interface (RNI) allows you to create specifications for any type of database
task or activity (eg: queries, DML, DDL, connection management) that look like
ordinary routines (procedures or functions) to your programs, and execute them
as such; all routine arguments are named.

Rosetta is trivially easy to install, since it is written in pure Perl and its
whole dependency chain consists of just 2 other pure Perl modules.

One of the main goals of Rosetta is similar to that of the Java platform,
namely "write once, run anywhere".  Code written against the RNI will run in an
identical fashion with zero changes regardless of what underlying database
product is in use.  Rosetta is intended to help free users and developers from
database vendor lock-in, such as that caused by the investment in large
quantities of vendor-specific code.  It also comes with a comprehensive
validation suite that proves it is providing identical behaviour no matter what
the underlying database vendor is.

This module has a multi-layered API that lets you choose between writing fairly
verbose code that performs faster, or fairly terse code that performs slower.

The RNI is structured in a loosely similar fashion to the DBI module's API, and
it should be possible to adapt applications written to use the DBI or one of
its many wrapper modules without too much trouble, if not directly then by way
of an emulation layer.  One aspect of this similarity is the hierarchy of
interface objects; you start with a root, which spawns objects that represent
database connections, each of which spawns objects representing queries or
statements run against a database through said connections.  Another
similarity, which is more specific to DBI itself, is that the API definition is
uncoupled from any particular implementation, such that many specialized
implementations can exist and be distributed separately.  Also, a multiplicity
of implementations can be used in parallel by the same application through a
common interface.  Where DBI gives the name 'driver' to each implementation,
Rosetta gives the name 'Engine', which may be more descriptive as they sit
"beneath" the interface; in some cases, an Engine can even be fully
self-contained, rather than mediating with an external database.  Another
similarity is that the preparation and execution (with place-holder
substitution) of database instructions are distinct activities, and you can
reuse a prepared instruction for multiple executions to get performance gains.

The Rosetta module does not talk to or implement any databases by itself; it 
is up to separately distributed Engine modules to do this.  You can see a 
reference implementation of one in the Rosetta::Engine::Generic module.

The main difference between Rosetta and the DBI is that Rosetta takes its input
primarily as SQL::Routine (SRT) objects, where DBI takes SQL strings.  See the
documentation for SQL::Routine (distributed separately) for details on how to
define those objects.  Also, when Rosetta dumps a scanned database schema, it
does so as SRT objects, while DBI dumps as either SQL strings or simple Perl
arrays, depending on the schema object type.  Each 'routine' that Rosetta takes
as input is equivalent to one or more SQL statements, where later statements
can use the results of earlier ones as their input.  The named argument list of
a 'routine' is analogous to the bind var list of DBI; each one defines what
values can be given to the statements at "execute" time.

Unlike SQL strings, SRT objects have very little redundancy, and the parts are
linked by references rather than by name; the spelling of each SQL identifier
(such as a table or column name) is stored exactly once; if you change the
single copy, then all code that refers to the entity updates at once.  SRT
objects can also store meta-data that SQL strings can't accomodate, and you
define database actions with the objects in exactly the same way regardless of
the database product in use; you do not write slightly different versions for
each as you do with SQL strings.  Developers don't have to restrict their
conceptual processes into the limits or dialect of a single product, or spend
time worrying about how to express the same idea against different products.

Rosetta is especially suited for data-driven applications, since the composite
scalar values in their data dictionaries can often be copied directly to RNI
structures, saving applications the tedious work of generating SQL themselves.

Rosetta is conceptually a DBI wrapper, whose strongest addition is SQL
generation, but it also works without the DBI, and with non-SQL databases; it
is up to each Engine to use or not use DBI, though most will use it because the
DBI is a high quality and mature platform to build upon.

The choice between using DBI and using Rosetta seems to be analogous to the
choice between the C and Java programming languages, respectively, where each
database product is analogous to a hardware CPU architecture or wider hardware
platform.  The DBI is great for people who like working as close to the metal
as possible, with direct access to each database product's native way of doing
things, those who *want* to talk to their database in its native SQL dialect,
and those who want the absolute highest performance.  Rosetta is more high
level, for those who want the write-once run-anywhere experience, less of a
burden on their creativity, more development time saving features, and are
willing to sacrifice a modicum of performance for the privilege.

There exist on CPAN many dozens of other modules or frameworks whose modus
operandi is to wrap the DBI or be used together with it for various reasons,
such as to provide automated object persistence functionality, or a
cross-database portability solution, or to provide part of a wider scoped
application tool kit, or to generate SQL, or to clone databases, or generate
reports, or provide a web interface, or to provide a "simpler" or "easier to
use" interface.  So, outside the DBI question, a choice exists between using
Rosetta and one of these other CPAN modules.  Going into detail on that matter
is outside the scope of this documentation, but a few salient points are
offered.  For one thing, Rosetta allows you to do a lot more than the
alternatives in an elegant fashion; with other modules, you would often have to
inject fragments of raw SQL into their objects (such as "select" query
conditionals) to accomplish what you want; with Rosetta, you should never need
to do any SQL injection.  For another point, Rosetta has a strong emphasis on
portability between many database products; only a handful of other modules
support more than 2-3 database products, and many only claim to support one
(usually MySQL).  Also, more than half of the other modules look like they had
only 5-20 hours of effort at most put into them, while Rosetta and its related
modules have likely had over 1000 hours of full time effort put into them.  For
another point, there is a frequent lack of support for commonly desired
database features in other modules, such as multiple column keys.  Also, most
modules have a common structural deficiency such that they are designed to
support a very specific set of database concepts, and adding more is a lot of
work; by contrast, Rosetta is internally designed in a heavily data-driven
fashion, allowing the addition or alternation of many features with little cost
in effort or complexity.

Perhaps a number of other CPAN modules' authors will see value in adding
back-end support for Rosetta and/or SQL::Routine to their offerings, either as
a supplement to their DBI-using native database SQL back-ends, or as a single
replacement for the lot of them.  Particularly in the latter case, the authors
will be more freed up to focus on their added value, such as object persistence
or web interfaces, rather than worrying about portability issues.  As quid quo
pro, perhaps some of the other CPAN modules (or parts of them) can be used by a
Rosetta Engine to help it do its work.

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
one.  An example of this is that you can invoke a CATALOG_LIST built-in routine without
specifying an Engine to run it against; Dispatcher will run that command
against each individual Engine behind the scenes and combine their results; you
then see a single list of databases that Rosetta can access without regard for
which Engine mediates access.  As a second example, you can invoke a CATALOG_OPEN
built-in off of the root Application Interface rather than having to do it
against the correct Environment Interface; Dispatcher will detect which
Environment is required (based on info in your SQL::Routine) and
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
SQL::Routine "data_link_product" Node that you create; you put the name of
the Rosetta Engine Class, such as "Rosetta::Engine::foo", in that Node's
"product_code" attribute.  The SQL::Routine documentation refers to that
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
Specifically, it is Error Interfaces and Success Interfaces and Application
Interfaces that never have their own associated Engine; every other type of
Interface must have one.

This diagram shows all of the Interface types and how they are allowed to 
relate to each other parent-child wise in an Interface tree:

	1	Error
	2	Success
	3	Application
	4	  Preparation
	5	    Literal
	6	    Environment
	7	      Preparation
	8	        Literal
	9	        Connection
	10	          Preparation
	11	            Literal
	12	            Cursor
	13	              Preparation
	14	                Literal

The "Application" (3) at the top is created using "Rosetta->new()", and you
normally have just one of those in your program.  A "Preparation" (4,7,10,13)
is created when you invoke "prepare()" off of an Interface object of one of
these types: "Application" (3), "Environment" (6), "Connection" (9), "Cursor"
(12).  Every type of Interface except "Application" and "Preparation" is
created by invoking "execute()" of an appropriate "Preparation" method.  The
"prepare()" and "execute()" methods always create a new Interface having the
result of the call, and this is usually a child of the one you invoked it from.

An "Error" (1) Interface can be returned potentially by any method and it is
self-contained; it has no parent Interfaces or children.  Note that any other
kind of Interface can also store an error condition in addition to keeping its
normal properties.

A "Success" (2) Interface is returned by execute() when the method being
executed is a PROCEDURE and it succeeds.  Since procedures by design don't
return anything, but execute() must return something, this is what you get to
indicate a successful procedure; any routine that should return something
meaningful is a FUNCTION.  (An unsuccessful routine of any kind throws an
Error.)  A Success Interface has no parent or child Interfaces.

For convenience, what sometimes happens is that the Rosetta Engine will create
multiple Interface generations for you as appropriate when you say "prepare()".
For example, if you give a "open this database" routine to an "Application" (3)
Interface, you would be given back a great-grand-child "Preparation" (7)
Interface.  Be aware of this if you ever request that an Interface you hold
give you its parent.

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

=head2 new_application( SRT_NODE )

	my $app = Rosetta->new_application( $my_app_inst );
	my $app2 = Rosetta::Interface->new_application( $my_app_inst );
	my $app3 = $app->new_application( $my_app_inst );

This function wraps Rosetta::Interface->new( 'Application', undef, undef,
undef, SRT_NODE ).  It can only create 'Application' Interfaces, and its sole
SRT_NODE argument must be an 'application_instance' SQL::Routine::Node.

=head1 INTERFACE CONSTRUCTOR FUNCTIONS AND METHODS

This function/method is stateless and can be invoked off of either the Interface
class name or an existing Interface object, with the same result.

=head2 new( INTF_TYPE[, ERR_MSG][, PARENT_INTF][, ENGINE][, SRT_NODE][, ROUTINE] )

	my $app = Rosetta::Interface->new( 'Application', undef, undef, undef, $my_app_inst );
	my $conn_prep = $app->new( 'Preparation', undef, $app, undef, $conn_srt_node, $conn_routine );

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
Interface.  The SRT_NODE argument is a SQL::Routine::Node argument that
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
current Interface is either an 'Error' or 'Success', then this method returns
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

=head2 get_srt_node()

	my $node = $interface->get_srt_node();

This "getter" method returns by reference the SQL::Routine::Node object
property of this Interface, if it has one.

=head2 get_srt_container()

	my $container = $interface->get_srt_container();

This "getter" method returns by reference the SQL::Routine::Container object
that is shared by this Interface tree, if there is one.

=head2 get_routine()

	my $routine = $preparation->get_routine();

This "getter" method returns by reference the Perl anonymous routine property
of this Interface, if it has one.  I<This method may be removed later.>

=head2 get_trace_fh()

	my $fh = $interface->get_trace_fh();

This "getter" method returns by reference the writeable Perl trace file handle
property of root 'Application' Interface of the tree that this Interface is in,
if possible; it returns undef otherwise.  This property is set after Intf
creation and can be cleared or set at any time.  When set, details of what
Rosetta is doing will be written to the file handle; to turn off the tracing,
just clear the property.  This class does not open or close the file; your
external code must do that.

=head2 clear_trace_fh()

	$interface->clear_trace_fh();

This "setter" method clears the trace file handle property of this Interface
tree root, if it was set, thereby turning off any tracing output.

=head2 set_trace_fh( NEW_FH )

	$interface->set_trace_fh( \*STDOUT );

This "setter" method sets or replaces the trace file handle property of this
Interface tree root to a new writeable Perl file handle, provided in NEW_FH, so
any subsequent tracing output is sent there.

=head2 features([ FEATURE_NAME ])

This "getter" method may only be invoked off of Interfaces having one of these
types: "Application", "Environment", "Connection"; it will throw an exception
if you invoke it on anything else.  When called with no arguments, it will
return a Perl hash ref whose keys are the names of key feature groups that the
corresponding Engine is declaring its support status for; values are always
either '1' for 'yes' and '0' for 'no'. If a key is absent, then the Engine is
saying that it doesn't know yet whether it will support the feature or not.  If
the optional argument FEATURE_NAME is defined, then this method will treat that
like a key in the previous mentioned hash and return just the associated value
of 1, 0, or undefined (don't know).  When a particular Environment says 'yes'
or 'no' for particular features, then grandchild Connections are guaranteed to
say likewise; when an Environment says "don't know" for a feature, then the
Connections can each change this to 'yes' or 'no' as it applies to them;
however, if a Connection still says "don't know" then this can be read as 'no'
if the Connection state is open; it still means "don't know" if the Connection
state is closed; a closed state's "don't know" can be changed by its
corresponding open state.  Note that invoking Application.features() will cause
all available Engines to load, each of their Environments consulted, and the
results combined to give the final result; for each possible feature, the
combined output is 'yes' iff all input Engines are 'yes', 'no' iff all 'no',
and undefined/missing if any inputs differ or are undefined/missing; if there
are no available Engines, the result is empty-list/undefined.

=head2 prepare( ROUTINE_DEFN )

This "getter"/"setter" method takes a SQL::Routine::Node object usually
representing a "routine" in its ROUTINE_DEFN argument, then "compiles" it into
a new "Preparation" Interface (returned) which is ready to execute the
specified action.  The ROUTINE_DEFN is always a "routine" SRT Node, but with
one exception when it is a "data_link_product" Node.  This method may only be
invoked off of Interfaces having one of these types: "Application",
"Environment", "Connection", "Cursor"; it will throw an exception if you invoke
it on anything else.  Most of the time, this method just passes the buck to the
Engine module that actually does its work, after doing some basic input
checking, or it will instantiate an Engine object.  Any calls to Engine objects
are wrapped in an eval block so that miscellaneous exceptions generated there
don't kill the program.  Note that invoking Application.prepare() where the
ROUTINE_DEFN is a "data_link_product" Node will create a "Preparation"
Interface that would simply load an Engine, but doesn't make a Connection or
otherwise ask the Engine to do anything.  Invoking Application.prepare() with a
"routine" SRT Node will pass the buck to Rosetta::Dispatcher, which usually
passes to a single normal Engine (loading it first if necessary); as an
exception to this, if the routine invokes the 'CATALOG_LIST' built-in standard
routine, then Dispatcher invokes a multitude of Engines (loading if needed) and
combines their results.

=head2 execute([ ROUTINE_ARGS ])

This "getter"/"setter" method can only be invoked off of a "Preparation"
Interface and will actually perform the action that the Interface is created
for.  The optional hash ref argument ROUTINE_ARGS provides run-time arguments
for the previously "compiled" routine, if it takes any.  Unlike prepare(),
which usually calls an Engine module's prepare() to do the actual work,
execute() will not call an Engine directly at all.  Rather, execute() simply
executes the Perl anonymous subroutine property of the "Preparation" Interface.
Said routine is created by an Engine's prepare() method and is usually a
closure, containing within it all the context necessary for work as if the
Engine was doing it.  Said routine returns new non-prep Interfaces.

=head2 do( ROUTINE_DEFN[, ROUTINE_ARGS] )

This is a simple convenience method that wraps a single prepare/execute
operation; it cuts in half the number of method calls you have to make, if you
are only going to execute the same prepared routine once.  You can invoke do()
in any situation that you can invoke a prepare( ROUTINE_DEFN ) with the same
first argument; the Preparation object returned by the prepare() has execute([
ROUTINE_ARGS ]) invoked on it; the Interface object returned by the execute()
is what do() returns.  Any exceptions thrown by the wrapped methods will
propagate unchanged to the code that invoked do().  If the execute() phase
either throws an exception of any kind, usually an 'Error' Interface, or it
returns a 'Success' Interface, the do() method will destroy() the Preparation
object that it just made before returning or re-throwing the execute() result;
if execute() returns any other kind of Interface, the Preparation will not get
destroyed, as the caller will have a handle on it via the returned result.

=head2 payload()

This "getter" method can only be invoked off of a "Literal" Interface.  It will
return the actual payload that the "Literal" Interface represents.  This can
either be an ordinary string or number or boolean, or a SRT Node ref, or an
array ref or hash ref containing other literal values.

=head2 routine_source_code( ROUTINE_NODE )

This "getter" method can only be invoked off of a "Environment" Interface.  It
will return, as a character string, the Perl source code of the user-defined
routine that was successfully prepared out of the ROUTINE_NODE SRT Node by the
Engine behind this Environment, either because the method was invoked directly
by prepare(), or it was invoked by another method that was; this method returns
the undefined value if the ROUTINE_NODE was never compiled by this Engine. 
This method is only intended for use when debugging an Engine.

=head1 ENGINE OBJECT FUNCTIONS AND METHODS

Rosetta::Engine defines shims for all of the required Engine methods, each of
which will throw an exception if the sub-classing Engine module doesn't
override them.  These methods all have the same names and functions as
Interface methods, which just turn around and call them.  Every Engine method
takes as its first argument a reference to the Interface object that it is
implementing (the Interface shim provides it); otherwise, each method's
argument list is the same as its same-named Interface method.  These are the
methods: destroy(), features(), prepare(), payload(), routine_source_code(). 
Every Engine must also implement a new() method which will be called in the
form [class-name-or-object-ref]->new() and must instantiate the Engine object;
typically this is called by the parent Engine, which also makes the Interface
for the new Engine.

=head1 DISPATCHER OBJECT FUNCTIONS AND METHODS

Rosetta::Dispatcher should never be either invoked or sub-classed by you, so
its method list will remain undocumented and private.

=head1 INTERFACE FUNCTIONS AND METHODS FOR RAPID DEVELOPMENT

The following 9 "setter" functions and methods should assist more rapid
development of code that uses Rosetta, at the cost of some flexibility.  They
differ from the other Interface functions and methods in that they also create
or alter the SQL::Routine model associated with a Rosetta Interface tree. 
These methods are implemented as wrappers over other Rosetta and SQL::Routine
methods, and allow you to accomplish with one method call what otherwise
requires at least 4-40 function or method calls, meaning your code base is
significantly smaller (unless you implement your own simplifying wrapper
functions, which is recommended in some situations).

Note that when a subroutine is referred to as a "function", it is stateless and
can be invoked off of either a class name or class object; when a subroutine is
called a "method", it can only be invoked off of Interface objects.

=head2 build_application()

	my $app_intf = Rosetta->build_application();

This function is like new_application() in that it will create and return a new
Application Interface object.  This function differs in that it will also
create a new SQL::Routine model by itself and associate the new Interface with
it, rather than requiring you to separately make the SRT model.  The created
model is as close to empty as possible; it contains only 2 SRT Nodes, which are
1 'application' and 1 related 'application_instance'; the latter becomes the
SRT_NODE argument for new_application().  The "id" and "si_name" of each new
Node is given a default generated value.  You can invoke get_srt_node() or
get_srt_container() on the new Application Interface to access the SRT Nodes
and model for further additions or changes.

=head2 build_application_with_node_trees( SRT_NODE_DEFN_LIST[, AUTO_ASSERT[, AUTO_IDS[, MATCH_SURR_IDS]]] )

	my $app_intf = Rosetta->build_application_with_node_trees( [...] );

This function is like build_application() except that it lets you define the
entire SRT Node hierarchy for the new model yourself; that definition is
provided in the SRT_NODE_DEFN_LIST argument.  This function expects you to
define the 'application' and 'application_instance' Nodes yourself, in
SRT_NODE_DEFN_LIST, and it will link the new Application Interface to the first
'application_instance' Node that it finds in the newly created SRT model.  This
method invokes SQL::Routine->build_container( SRT_NODE_DEFN_LIST, AUTO_ASSERT,
AUTO_IDS, MATCH_SURR_IDS ) to do most of the work.

=head2 build_environment( ENGINE_NAME )

	my $env_intf = Rosetta->build_environment( 'Rosetta::Engine::Generic' );

This function is like build_application() except that it will also create a new
'data_link_product' Node, using ENGINE_NAME as the 'product_code' attribute,
and it will create a new associated Environment Interface object, that fronts a
newly instantiated Engine object of the ENGINE_NAME class; the Environment
Interface is returned.

=head2 build_child_environment( ENGINE_NAME )

	my $env_intf = $app_intf->build_child_environment( 'Rosetta::Engine::Generic' );

This method may only be invoked off of an Application Interface.  This method
is like build_environment( ENGINE_NAME ) except that it will reuse the
Application Interface that it is invoked off of, and associated Nodes, rather
than making new ones.  Moreover, if an Environment Interface with the same
'product_code' already exists under the current Application Interface, then
build_child_environment() will not create or change anything, but simply return
the existing Environment Interface object instead of a new one.

=head2 build_connection( SETUP_OPTIONS[, RT_SI_NAME[, RT_ID]] )

	my $conn_intf_sqlite = Rosetta->build_connection( {
		'data_storage_product' => {
			'product_code' => 'SQLite',
			'is_file_based' => 1,
		},
		'data_link_product' => {
			'product_code' => 'Rosetta::Engine::Generic',
		},
		'catalog_instance' => {
			'file_path' => 'test',
		},
	} );
	my $conn_intf_mysql = Rosetta->build_connection( {
		'data_storage_product' => {
			'product_code' => 'MySQL',
			'is_network_svc' => 1,
		},
		'data_link_product' => {
			'product_code' => 'Rosetta::Engine::Generic',
		},
		'catalog_link_instance' => {
			'local_dsn' => 'test',
			'login_name' => 'jane',
			'login_pass' => 'pwd',
		},
	}, 'declare_conn_to_mysql', 3 );

This function will create and return a new Connection Interface object plus the
prerequisite SQL::Routine model and Interface and Engine objects.  The
SETUP_OPTIONS argument is a two-dimensional hash, where each outer hash element
corresponds to a Node type and each inner hash element corresponds to an
attribute name and value for that Node type.  There are 6 allowed Node types:
data_storage_product, data_link_product, catalog_instance,
catalog_link_instance, catalog_instance_opt, catalog_link_instance_opt; the
first 4 have a specific set of actual scalar or enumerated attributes that may
be set; with the latter 2, you can set any number of virtual attributes that
you choose.  The "setup options" say what Rosetta Engine to test and how to
configure it to work in your customized environment.  The actual attributes of
the first 4 Node types should be recognized by all Engines and have the same
meaning to them; you can set any or all of them (see the SQL::Routine
documentation for the list) except for "id" and "si_name", which are given
default generated values.  The build_connection() function requires that, at
the very least, you provide a 'data_link_product'.'product_code' SETUP_OPTIONS
value, since that specifies the class name of the Rosetta Engine that
implements the Connection.  The virtual attributes of the last 2 Node types are
specific to each Engine (see the Engine's documentation for a list), though an
Engine may not define any at all.  This function will generate 1 Node each of
the first 4 Node types, and zero or more each of the last 2 Node types, all of
which are cross-associated, plus the same Nodes that build_application() does,
plus 1 each of: 'catalog', catalog_link, 'routine', plus several child Nodes of
the 'routine'.  The new 'routine' that this function creates is what declares
the new Connection Interface, and becomes its SRT Node.  Since you are likely
to declare many routines subsequently in the same SRT model (but unlikely to
declare more of any of the other aforementioned Node types), this function lets
you provide explicit "si_name" and "id" attributes for the new 'routine' Node
only, in the optional arguments RT_SI_NAME and RT_ID respectively.

=head2 build_child_connection( SETUP_OPTIONS[, RT_SI_NAME[, RT_ID]] )

	my $conn_intf_postgres = $env_intf->build_child_connection( {
		'data_storage_product' => {
			'product_code' => 'PostgreSQL',
			'is_network_svc' => 1,
		},
		'catalog_link_instance' => {
			'local_dsn' => 'test',
			'login_name' => 'jane',
			'login_pass' => 'pwd',
		},
	} );

This method may only be invoked off of an Application or Environment Interface.
This method is like build_connection( SETUP_OPTIONS, RT_SI_NAME, RT_ID ) except
that it will reuse the Application and/or Environment Interface that it is
invoked off of, and associated Nodes, rather than making new ones.  If invoked
off of an Environment Interface, then any 'data_link_product' info that might
be provided in SETUP_OPTIONS is ignored.  If invoked off of an Application
Interface, this method will try to reuse an existing child Environment
Interface, that matches the given 'data_link_product'.'product_code', before
making a new one, just as build_child_environment() does.  This method will not
attempt to reuse any other types of Nodes, so if that's what you want, you
can't use this method to do it.

=head2 validate_connection_setup_options( SETUP_OPTIONS )

This function is used internally by build_connection() and
build_child_connection() to confirm that its SETUP_OPTIONS argument is valid,
prior to it changing the state of anything.  This function is public so that
external code can use it to perform advance validation on an identical
configuration structure without side-effects.  Note that this function is not
thorough; except for the 'data_link_product'.'product_code' (Rosetta Engine
class name), it does not test that Node attribute entries in SETUP_OPTIONS have
defined values, and even that single attribute isn't tested beyond that it is
defined.  Testing for defined and mandatory option values is left to the
SQL::Routine methods, which are only invoked by build_[child_]_connection().

=head2 destroy_interface_tree()

	my $container = $app_intf->destroy_interface_tree();

This method can be invoked on any Rosetta Interface object and will recursively
destroy an entire Rosetta Interface tree, starting with the child-most
Interface objects and working down to the root Interface.  This method does not
destroy the SQL::Routine model used by the Interfaces, and returns a reference
to it upon completion, so that you have the option to re-use the model later,
such as with a new Interface tree.  Note that it is pointless to invoke this on
an 'Error' or 'Success' Interface object because those types do not live in
Interface trees, and lack the circular refs to prevent them being
auto-destroyed when references to them are gone.

=head2 destroy_interface_tree_and_srt_container()

	$app_intf->destroy_interface_tree_and_srt_container();

This function is like destroy_interface_tree() except that it will also destroy
the SQL::Routine model that the invoked-on Interface tree is using.

=head1 CONNECTION INTERFACE METHODS FOR RAPID DEVELOPMENT

These methods provide a simplified interface to many commonly performed
database activities, and should should assist more rapid development of code
that uses Rosetta; they are all implemented as wrappers over other, more
generic Rosetta and SQL::Routine methods.  All of these methods can only be 
invoked off of a Connection Interface, because they only make sense within the 
context of a database connection.  Each of these methods will generate a new 
SRT 'routine' whose 'routine_context' is the 'CONN' that the invoked-on 
Connection Interface represents.

I<WARNING: These methods are early prototypes and will be replaced within 1-2
subsequent Rosetta releases with other methods that behave differently.  The
current versions will prepare() the new SRT routines and return the Preparation
Interface to you to execute().  For each method, optional RT_SI_NAME and RT_ID
arguments are provided; you can give explicit "si_name" and "id" attributes to
the new 'routine' Node, or such values will be generated.>

=head2 sroutine_catalog_list([ RT_SI_NAME[, RT_ID] ])

This method will build and return a prepared wrapper function for the
CATALOG_LIST built-in SRT standard routine, which when executed, will return a
Literal Interface whose payload is an array ref having zero or more newly
generated 'catalog_link' SRT Nodes, each of which represents an auto-detected
database catalog instance.

=head2 sroutine_catalog_open([ RT_SI_NAME[, RT_ID] ])

This method will build and return a prepared wrapper procedure for the
CATALOG_OPEN built-in SRT standard routine, which when executed, will change
the invoked on Connection from a closed state to an opened state, and will
return a Success Interface.  The prepared procedure will take 2 optional
arguments at execute() time, which are 'login_name' and 'login_pass'; these
values will be used if and only if a 'login_name' and 'login_pass' were not
provided by the 'catalog_link' SRT Node that was used to make the invoked from
Connection Interface.

=head2 sroutine_catalog_close([ RT_SI_NAME[, RT_ID] ])

This method will build and return a prepared wrapper procedure for the
CATALOG_CLOSE built-in SRT standard routine, which when executed, will change
the invoked on Connection from an opened state to a closed state, and will
return a Success Interface.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways;
however, I believe that any further incompatible changes will be small.  The
current state is analogous to 'developer releases' of operating systems; it is
reasonable to being writing code that uses this module now, but you should be
prepared to maintain it later in keeping with API changes.  All of this said, I
plan to move this module into alpha development status within the next few
releases, once I start using it in a production environment myself.

=head1 SEE ALSO

L<perl(1)>, L<Rosetta::L::en>, L<Rosetta::Features>, L<Rosetta::Framework>,
L<Locale::KeyedText>, L<SQL::Routine>, L<Rosetta::Engine::Generic>, L<DBI>,
L<Alzabo>, L<SPOPS>, L<Class::DBI>, L<Tangram>, L<HDB>, L<Genezzo>,
L<DBIx::RecordSet>, L<DBIx::SearchBuilder>, L<SQL::Schema>, L<DBIx::Abstract>,
L<DBIx::AnyDBD>, L<DBIx::Browse>, L<DBIx::SQLEngine>, L<MKDoc::SQL>,
L<Data::Transactional>, L<DBIx::ModelUpdate>, L<DBIx::ProcedureCall>, and
various other modules.

=cut
