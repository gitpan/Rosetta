#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta;
our $VERSION = '0.45';

use Locale::KeyedText 1.04;
use SQL::Routine 0.62;

######################################################################

=encoding utf8

=head1 NAME

Rosetta - Rigorous database portability

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: 

	Locale::KeyedText 1.04 (for error messages)
	SQL::Routine 0.62

=head1 COPYRIGHT AND LICENSE

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 2002-2005, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to perl@DarrenDuncan.net, or
visit http://www.DarrenDuncan.net/ for more information.

Rosetta is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License (GPL) as published by the Free Software
Foundation (http://www.fsf.org/); either version 2 of the License, or (at your
option) any later version.  You should have received a copy of the GPL as part
of the Rosetta distribution, in the file named "GPL"; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA.

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
my $IPROP_SRT_CONT = 'srt_cont'; # ref to SQL::Routine Container that srt_node lives in
	# We must ref the Container explicitly, or it can easily be garbage collected from under us
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
	my ($self, $srt_node) = @_;
	return Rosetta::Interface->new( $INTFTP_APPLICATION, undef, undef, undef, $srt_node );
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
	$interface->{$IPROP_SRT_CONT} = $srt_node && $srt_node->get_container();
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
	my ($interface) = @_;
	return $interface->{$IPROP_INTF_TYPE};
}

######################################################################

sub get_error_message {
	# This method returns the Message object by reference.
	my ($interface) = @_;
	return $interface->{$IPROP_ERROR_MSG};
}

######################################################################

sub get_parent_interface {
	# This method returns the Interface object by reference.
	my ($interface) = @_;
	return $interface->{$IPROP_PARENT_INTF};
}

######################################################################

sub get_root_interface {
	# This method returns the Interface object by reference.
	my ($interface) = @_;
	return $interface->{$IPROP_ROOT_INTF};
}

######################################################################

sub get_child_interfaces {
	# This method returns each Interface object by reference.
	my ($interface) = @_;
	return [@{$interface->{$IPROP_CHILD_INTFS}}];
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
	my ($interface) = @_;
	return $interface->{$IPROP_ENGINE};
}

######################################################################

sub get_srt_node {
	# This method returns the Node object by reference.
	my ($interface) = @_;
	return $interface->{$IPROP_SRT_NODE};
}

sub get_srt_container {
	my ($interface) = @_;
	if( my $app_intf = $interface->{$IPROP_ROOT_INTF} ) {
		return $app_intf->{$IPROP_SRT_CONT};
	}
	return;
}

######################################################################
# We may not keep this method

sub get_routine {
	my ($interface) = @_;
	return $interface->{$IPROP_ROUTINE};
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

I<To cut down on the size of the SQL::Routine module itself, most of the POD
documentation is in these other files: L<Rosetta::Details>,
L<Rosetta::Features>, L<Rosetta::Framework>.>

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

=head1 BRIEF FUNCTION AND METHOD LIST

Here is a compact list of this module's functions and methods along with their 
arguments.  For full details on each one, please see L<Rosetta::Details>.

CONSTRUCTOR WRAPPER FUNCTIONS:

	new_application( SRT_NODE )

INTERFACE CONSTRUCTOR FUNCTIONS AND METHODS:

	new( INTF_TYPE[, ERR_MSG][, PARENT_INTF][, ENGINE][, SRT_NODE][, ROUTINE] )

INTERFACE OBJECT METHODS:

	destroy()
	get_interface_type()
	get_error_message()
	get_parent_interface()
	get_root_interface()
	get_child_interfaces()
	get_sibling_interfaces([ SKIP_SELF ])
	get_engine()
	get_srt_node()
	get_srt_container()
	get_routine()
	get_trace_fh()
	clear_trace_fh()
	set_trace_fh( NEW_FH )
	features([ FEATURE_NAME ])
	prepare( ROUTINE_DEFN )
	execute([ ROUTINE_ARGS ])
	do( ROUTINE_DEFN[, ROUTINE_ARGS] )
	payload()
	routine_source_code( ROUTINE_NODE )

ENGINE OBJECT FUNCTIONS AND METHODS: (none are public)

DISPATCHER OBJECT FUNCTIONS AND METHODS: (none are public)

INTERFACE FUNCTIONS AND METHODS FOR RAPID DEVELOPMENT:

	build_application()
	build_application_with_node_trees( SRT_NODE_DEFN_LIST[, AUTO_ASSERT[, AUTO_IDS[, MATCH_SURR_IDS]]] )
	build_environment( ENGINE_NAME )
	build_child_environment( ENGINE_NAME )
	build_connection( SETUP_OPTIONS[, RT_SI_NAME[, RT_ID]] )
	build_child_connection( SETUP_OPTIONS[, RT_SI_NAME[, RT_ID]] )
	validate_connection_setup_options( SETUP_OPTIONS )
	destroy_interface_tree()

CONNECTION INTERFACE METHODS FOR RAPID DEVELOPMENT:

	sroutine_catalog_list([ RT_SI_NAME[, RT_ID] ])
	sroutine_catalog_open([ RT_SI_NAME[, RT_ID] ])
	sroutine_catalog_close([ RT_SI_NAME[, RT_ID] ])

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

L<perl(1)>, L<Rosetta::L::en>, L<Rosetta::Details>, L<Rosetta::Features>,
L<Rosetta::Framework>, L<Locale::KeyedText>, L<SQL::Routine>,
L<Rosetta::Engine::Generic>, L<DBI>, L<Alzabo>, L<SPOPS>, L<Class::DBI>,
L<Tangram>, L<HDB>, L<Genezzo>, L<DBIx::RecordSet>, L<DBIx::SearchBuilder>,
L<SQL::Schema>, L<DBIx::Abstract>, L<DBIx::AnyDBD>, L<DBIx::Browse>,
L<DBIx::SQLEngine>, L<MKDoc::SQL>, L<Data::Transactional>, L<DBIx::ModelUpdate>,
L<DBIx::ProcedureCall>, and various other modules.

=cut
