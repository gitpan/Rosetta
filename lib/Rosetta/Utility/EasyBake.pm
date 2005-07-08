#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Utility::EasyBake;
our $VERSION = '0.01';

use Rosetta 0.46;

######################################################################

=encoding utf8

=head1 NAME

Rosetta::Utility::EasyBake - Perform common tasks with less effort

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: 

	Rosetta 0.46

=head1 COPYRIGHT AND LICENSE

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 2002-2005, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to perl@DarrenDuncan.net, or
visit http://www.DarrenDuncan.net/ for more information.

Rosetta is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License (GPL) as published by the Free Software
Foundation (http://www.fsf.org/); either version 2 of the License, or (at your
option) any later version.  You should have received a copy of the GPL as part
of the Rosetta distribution, in the file named "GPL"; if not, write to the Free
Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301,
USA.

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

# Names of properties for objects of the Rosetta::Utility::EasyBake class are declared here:
	# Currently, there are no properties; the functions are all stateless.

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

sub new {
	my ($class) = @_;
	my $easybake = bless( {}, ref($class) || $class );
	return $easybake;
}

######################################################################

sub validate_connection_setup_options {
	my ($easybake, $setup_options) = @_;
	defined( $setup_options ) or $easybake->_throw_error_message( 'ROS_UEB_V_CONN_SETUP_OPTS_NO_ARG' );
	unless( ref($setup_options) eq 'HASH' ) {
		$easybake->_throw_error_message( 'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG', { 'ARG' => $setup_options } );
	}
	while( my ($node_type, $rh_attrs) = each %{$setup_options} ) {
		unless( $BC_SETUP_NODE_TYPES{$node_type} ) {
			$easybake->_throw_error_message( 'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG_NTYPE', 
			{ 'GIVEN' => $node_type, 'ALLOWED' => "@{[keys %BC_SETUP_NODE_TYPES]}" } );
		}
		defined( $rh_attrs ) or $easybake->_throw_error_message( 
			'ROS_UEB_V_CONN_SETUP_OPTS_NO_ARG_ELEM', { 'NTYPE' => $node_type } );
		unless( ref($rh_attrs) eq 'HASH' ) {
			$easybake->_throw_error_message( 'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG_ELEM', 
				{ 'NTYPE' => $node_type, 'ARG' => $rh_attrs } );
		}
		ref($BC_SETUP_NODE_TYPES{$node_type}) eq 'HASH' or next; # all opt names accepted
		while( my ($option_name, $option_value) = each %{$rh_attrs} ) {
			unless( $BC_SETUP_NODE_TYPES{$node_type}->{$option_name} ) {
				$easybake->_throw_error_message( 'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG_OPTNM', 
					{ 'NTYPE' => $node_type, 'GIVEN' => $option_name, 
					'ALLOWED' => "@{[keys %{$BC_SETUP_NODE_TYPES{$node_type}}]}" } );
			}
		}
	}
	unless( $setup_options->{'data_link_product'} and 
			$setup_options->{'data_link_product'}->{'product_code'} ) {
		$easybake->_throw_error_message( 'ROS_UEB_V_CONN_SETUP_OPTS_NO_ENG_NM' );
	}
}

######################################################################

sub build_application {
	my ($easybake) = @_;
	my $container = SQL::Routine->new_container();
	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );
	my $app_bp_node = $easybake->_build_node_auto_name( $container, 'application' );
	my $app_inst_node = $easybake->_build_node_auto_name( $container, 'application_instance', 
		{ 'blueprint' => $app_bp_node } );
	$container->auto_set_node_ids( $orig_asni_vl );
	my $app_intf = Rosetta->new_application_interface( $app_inst_node );
	return $app_intf;
}

sub build_application_with_node_trees {
	my ($easybake, $children, $auto_assert, $auto_ids, $match_surr_ids) = @_;
	my $container = SQL::Routine->build_container( $children, $auto_assert, $auto_ids, $match_surr_ids );
	my $app_inst_node = @{$container->get_child_nodes( 'application_instance' )}[0];
	my $app_intf = Rosetta->new_application_interface( $app_inst_node );
	return $app_intf;
}

######################################################################

sub build_environment {
	my ($easybake, $engine_name) = @_;
	my $app_intf = $easybake->build_application();
	my $env_intf = $easybake->build_child_environment( $app_intf, $engine_name );
	return $env_intf;
}

sub build_child_environment {
	my ($easybake, $app_intf, $engine_name) = @_;
	$easybake->_assert_arg_intf_obj_type( 'build_child_environment', 
		'APP_INTF', ['Application'], $app_intf );
	defined( $engine_name ) or $app_intf->_throw_error_message( 'ROS_I_BUILD_CH_ENV_NO_ARG', 
		{ 'METH' => 'build_child_environment', 'ARGNM' => 'ENGINE_NAME' } );
	my $container = $app_intf->get_srt_container();
	my $env_intf = undef;
	foreach my $ch_env_intf (@{$app_intf->get_child_by_context_interfaces()}) {
		if( $ch_env_intf->get_link_prod_node()->get_literal_attribute( 'product_code' ) eq $engine_name ) {
			$env_intf = $ch_env_intf;
			last;
		}
	}
	unless( $env_intf ) {
		my $dlp_node = $container->build_node( 'data_link_product', 
			{ 'id' => $container->get_next_free_node_id(), 
			'si_name' => $engine_name, 'product_code' => $engine_name } );
		$env_intf = $app_intf->new_environment_interface( $app_intf, $dlp_node ); # dies if bad Engine
	}
	return $env_intf;
}

######################################################################

sub build_connection {
	my ($easybake, $setup_options, $rt_si_name, $rt_id) = @_;
	my $app_intf = $easybake->build_application();
	my $conn_intf = $easybake->build_child_connection( $app_intf, $setup_options, $rt_si_name, $rt_id );
	return $conn_intf;
}

sub build_child_connection {
	my ($easybake, $interface, $setup_options, $rt_si_name, $rt_id) = @_;
	$easybake->_assert_arg_intf_obj_type( 'build_child_connection', 
		'INTERFACE', ['Application','Environment'], $interface );

	$easybake->validate_connection_setup_options( $setup_options ); # dies on input errors

	my $env_intf = undef;
	if( UNIVERSAL::isa( $interface, 'Rosetta::Interface::Environment' ) ) {
		$env_intf = $interface;
	} else { # $interface isa Application
		my %dlp_setup = %{$setup_options->{'data_link_product'} || {}};
		$env_intf = $easybake->build_child_environment( $interface, $dlp_setup{'product_code'} );
	}
	my $dlp_node = $env_intf->get_link_prod_node();

	my $container = $interface->get_srt_container();
	my $app_inst_node = $interface->get_root_interface()->get_app_inst_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $cat_bp_node = $easybake->_build_node_auto_name( $container, 'catalog' );

	my $cat_link_bp_node = $easybake->_build_child_node_auto_name( $app_bp_node, 'catalog_link', 
		{ 'target' => $cat_bp_node } );

	my $routine_node = $easybake->_build_child_node_auto_name( $app_bp_node, 'routine', 
		{ 'routine_type' => 'FUNCTION', 'return_cont_type' => 'CONN', 'return_conn_link' => $cat_link_bp_node } );
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

	my $dsp_node = $easybake->_build_node_auto_name( $container, 'data_storage_product', 
		$setup_options->{'data_storage_product'} );

	my $cat_inst_node = $easybake->_build_node_auto_name( $container, 'catalog_instance', 
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

sub sroutine_catalog_list {
	my ($easybake, $interface, $rt_si_name, $rt_id) = @_;
	$easybake->_assert_arg_intf_obj_type( 'sroutine_catalog_list', 
		'INTERFACE', ['Application','Environment'], $interface );

	my $container = $interface->get_srt_container();
	my $app_inst_node = $interface->get_root_interface()->get_app_inst_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $routine_node = $easybake->_build_child_node_auto_name( $app_bp_node, 'routine', 
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
	my ($easybake, $conn_intf, $rt_si_name, $rt_id) = @_;
	$easybake->_assert_arg_intf_obj_type( 'sroutine_catalog_open', 
		'CONN_INTF', ['Connection'], $conn_intf );

	my $container = $conn_intf->get_srt_container();
	my $app_inst_node = $conn_intf->get_root_interface()->get_app_inst_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $conn_routine_node = $conn_intf->get_parent_by_creation_interface()->get_routine_node();
	my $cat_link_bp_node = (
		grep { $_->get_enumerated_attribute( 'cont_type' ) eq 'CONN' } 
		@{$conn_routine_node->get_child_nodes( 'routine_var' )}
		)[0]->get_node_ref_attribute( 'conn_link' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $sdt_auth_node = $easybake->_build_node_auto_name( $container, 'scalar_data_type', 
		{ 'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8' } );

	my $routine_node = $easybake->_build_child_node_auto_name( $app_bp_node, 'routine', 
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
	my ($easybake, $conn_intf, $rt_si_name, $rt_id) = @_;
	$easybake->_assert_arg_intf_obj_type( 'sroutine_catalog_close', 
		'CONN_INTF', ['Connection'], $conn_intf );

	my $container = $conn_intf->get_srt_container();
	my $app_inst_node = $conn_intf->get_root_interface()->get_app_inst_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );

	my $conn_routine_node = $conn_intf->get_parent_by_creation_interface()->get_routine_node();
	my $cat_link_bp_node = (
		grep { $_->get_enumerated_attribute( 'cont_type' ) eq 'CONN' } 
		@{$conn_routine_node->get_child_nodes( 'routine_var' )}
		)[0]->get_node_ref_attribute( 'conn_link' );

	my $orig_asni_vl = $container->auto_set_node_ids();
	$container->auto_set_node_ids( 1 );

	my $routine_node = $easybake->_build_child_node_auto_name( $app_bp_node, 'routine', 
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
# These are 'protected' methods; only sub-classes should invoke them.

sub _build_node_auto_name {
	my ($easybake, $container, $node_type, $attrs) = @_;
	my $node_id = $container->get_next_free_node_id();
	my $si_name = 'EasyBake Default '.
		join( ' ', map { ucfirst( $_ ) } split( '_', $node_type ) ).' '.$node_id;
	return $container->build_node( $node_type, 
		{ 'si_name' => $si_name, %{$attrs || {}} } );
}

sub _build_child_node_auto_name {
	my ($easybake, $pp_node, $node_type, $attrs) = @_;
	my $container = $pp_node->get_container();
	my $node_id = $container->get_next_free_node_id();
	my $si_name = 'EasyBake Default '.
		join( ' ', map { ucfirst( $_ ) } split( '_', $node_type ) ).' '.$node_id;
	return $pp_node->build_child_node( $node_type, 
		{ 'si_name' => $si_name, %{$attrs || {}} } );
}

######################################################################
# These are 'protected' methods; only sub-classes should invoke them.

sub _throw_error_message {
	my ($easybake, $msg_key, $msg_vars) = @_;
	# Throws an exception consisting of an object.
	ref($msg_vars) eq 'HASH' or $msg_vars = {};
	$msg_vars->{'CLASS'} ||= ref($easybake) || $easybake;
	foreach my $var_key (keys %{$msg_vars}) {
		if( ref($msg_vars->{$var_key}) eq 'ARRAY' ) {
			$msg_vars->{$var_key} = 'PERL_ARRAY:['.join(',',map {$_||''} @{$msg_vars->{$var_key}}).']';
		}
	}
	die Locale::KeyedText->new_message( $msg_key, $msg_vars );
}

sub _assert_arg_obj_type {
	my ($easybake, $meth_name, $arg_name, $exp_obj_types, $arg_value) = @_;
	unless( defined( $arg_value ) ) {
		$easybake->_throw_error_message( 'ROS_CLASS_METH_ARG_UNDEF', 
			{ 'METH' => $meth_name, 'ARGNM' => $arg_name } );
	}
	unless( ref($arg_value) ) {
		$easybake->_throw_error_message( 'ROS_CLASS_METH_ARG_NO_OBJ', 
			{ 'METH' => $meth_name, 'ARGNM' => $arg_name, 'ARGVL' => $arg_value } );
	}
	unless( grep { UNIVERSAL::isa( $arg_value, $_ ) } @{$exp_obj_types} ) {
		$easybake->_throw_error_message( 'ROS_CLASS_METH_ARG_WRONG_OBJ_TYPE', 
			{ 'METH' => $meth_name, 'ARGNM' => $arg_name, 
			'EXPOTYPE' => $exp_obj_types, 'ARGOTYPE' => ref($arg_value) } );
	}
	# If we get here, $arg_value is acceptable to the method.
}

sub _assert_arg_intf_obj_type {
	my ($easybake, $meth_name, $arg_name, $exp_obj_types, $arg_value) = @_;
	$exp_obj_types = [map { 'Rosetta::Interface::'.$_ } @{$exp_obj_types}];
	$easybake->_assert_arg_obj_type( $meth_name, $arg_name, $exp_obj_types, $arg_value );
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<This documentation section will be written later.>

=head1 DESCRIPTION

The Rosetta::Utility::EasyBake Perl 5 module contains an optional set of
convenience methods that let you define and perform common tasks using Rosetta
while expending less effort in the process.  You can have a significantly
reduced application code size at the expense of some flexibility.

This module is implemented as a stateless utility class, and its methods are
higher level wrappers around Rosetta and SQL::Routine methods.  When one of its
methods would conceptually be a 'Rosetta::Interface::*' method, it will take an
object of that class as its first argument.  The kind of functionality that
EasyBake has an outward appearance relative to 'Rosetta' that resembles the
general appearance of many DBIx wrappers relative to 'DBI'.

Rosetta::Utility::EasyBake contains some functionality that is common to
Rosetta::Validator and Rosetta::Emulator::DBI, plus miscellaneous other modules
and applications, so that each of those doesn't have to maintain its own copy.

While it is fairly new, you should consider this EasyBake module to be
deprecated and you should not use it except for quick-and-dirty applications or
experimental purposes.  Writers of reuseable modules that want to use and/or
extend Rosetta, particularly modules providing a database access or object
persistence solution, should write directly to the 'Rosetta' module, which is a
lot more flexible and will be better maintained.  Likewise if you're making a 
large application having a distinct database access layer within it.  Your own 
custom equivalent of what EasyBake does will serve you better in many cases.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$easybake-E<gt>method()>. 

=head1 CONSTRUCTOR FUNCTIONS

This function is stateless and can be invoked off of either this
module's name or an existing module object, with the same result.

=head2 new()

	my $easybake = Rosetta::Utility::EasyBake->new();
	my $easybake2 = $easybake->new();

This "getter" function will create and return a single
Rosetta::Utility::EasyBake (or subclass) object.

=head1 CONFIGURATION INPUT VALIDATION METHODS

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

=head1 DECLARATION BUILDERS FOR RAPID DEVELOPMENT

=head2 build_application()

	my $app_intf = $easybake->build_application();

This function is like Rosetta.new_application_interface() in that it will create
and return a new Application Interface object.  This function differs in that it
will also create a new SQL::Routine model by itself and associate the new
Interface with it, rather than requiring you to separately make the SRT model.
The created model is as close to empty as possible; it contains only 2 SRT
Nodes, which are 1 'application' and 1 related 'application_instance'; the
latter becomes the SRT_NODE argument for new_application_interface().  The "id"
and "si_name" of each new Node is given a default generated value.  You can
invoke get_app_inst_node() or get_srt_container() on the new Application
Interface to access the SRT Nodes and model for further additions or changes.

=head2 build_application_with_node_trees( CHILDREN[, AUTO_ASSERT[, AUTO_IDS[, MATCH_SURR_IDS]]] )

	my $app_intf = $easybake->build_application_with_node_trees( [...] );

This function is like build_application() except that it lets you define the
entire SRT Node hierarchy for the new model yourself; that definition is
provided in the CHILDREN argument.  This function expects you to define the
'application' and 'application_instance' Nodes yourself, in CHILDREN, and it
will link the new Application Interface to the first 'application_instance' Node
that it finds in the newly created SRT model.  This method invokes
SQL::Routine->build_container( CHILDREN, AUTO_ASSERT, AUTO_IDS, MATCH_SURR_IDS )
to do most of the work.

=head2 build_environment( ENGINE_NAME )

	my $env_intf = $easybake->build_environment( 'Rosetta::Engine::Generic' );

This function is like build_application() except that it will also create a new
'data_link_product' Node, using ENGINE_NAME as the 'product_code' attribute,
and it will create a new associated Environment Interface object, that fronts a
newly instantiated Engine object of the ENGINE_NAME class; the Environment
Interface is returned.

=head2 build_child_environment( APP_INTF, ENGINE_NAME )

	my $env_intf = $easybake->build_child_environment( $app_intf, 'Rosetta::Engine::Generic' );

This function is like build_environment( ENGINE_NAME ) except that it will reuse
the Application Interface given in APP_INTF, and associated Nodes, rather than
making new ones.  Moreover, if an Environment Interface with the same
'product_code' already exists under the current Application Interface, then
build_child_environment() will not create or change anything, but simply return
the existing Environment Interface object instead of a new one.

=head2 build_connection( SETUP_OPTIONS[, RT_SI_NAME[, RT_ID]] )

	my $conn_intf_sqlite = $easybake->build_connection( {
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
	my $conn_intf_mysql = $easybake->build_connection( {
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

=head2 build_child_connection( INTERFACE, SETUP_OPTIONS[, RT_SI_NAME[, RT_ID]] )

	my $conn_intf_postgres = $easybake->build_child_connection( $app_intf, {
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

This function is like build_connection( SETUP_OPTIONS, RT_SI_NAME, RT_ID )
except that it will reuse the Application and/or Environment Interface that it
is given in INTERFACE, and associated Nodes, rather than making new ones.  If
invoked off of an Environment Interface, then any 'data_link_product' info that
might be provided in SETUP_OPTIONS is ignored.  If invoked off of an Application
Interface, this method will try to reuse an existing child Environment
Interface, that matches the given 'data_link_product'.'product_code', before
making a new one, just as build_child_environment() does.  This method will not
attempt to reuse any other types of Nodes, so if that's what you want, you can't
use this method to do it.

=head1 STANDARD ROUTINE WRAPPER BUILDERS FOR RAPID DEVELOPMENT

For each of these functions, optional RT_SI_NAME and RT_ID arguments are
provided; you can give explicit "si_name" and "id" attributes to the new
'routine' Node, or such values will be generated.

=head2 sroutine_catalog_list( INTERFACE[, RT_SI_NAME[, RT_ID] ])

This method will build and return a prepared wrapper function for the
CATALOG_LIST built-in SRT standard routine, which when executed, will return a
Literal Interface whose payload is an array ref having zero or more newly
generated 'catalog_link' SRT Nodes, each of which represents an auto-detected
database catalog instance.

=head2 sroutine_catalog_open( CONN_INTF[, RT_SI_NAME[, RT_ID] ])

This method will build and return a prepared wrapper procedure for the
CATALOG_OPEN built-in SRT standard routine, which when executed, will change
the invoked on Connection from a closed state to an opened state, and will
return a Success Interface.  The prepared procedure will take 2 optional
arguments at execute() time, which are 'login_name' and 'login_pass'; these
values will be used if and only if a 'login_name' and 'login_pass' were not
provided by the 'catalog_link' SRT Node that was used to make the invoked from
Connection Interface.

=head2 sroutine_catalog_close( CONN_INTF[, RT_SI_NAME[, RT_ID] ])

This method will build and return a prepared wrapper procedure for the
CATALOG_CLOSE built-in SRT standard routine, which when executed, will change
the invoked on Connection from an opened state to a closed state, and will
return a Success Interface.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

L<perl(1)>, L<Rosetta::Utility::EasyBake::L::en>, L<Rosetta>, L<SQL::Routine>,
L<Locale::KeyedText>, L<Rosetta::Validator>, L<Rosetta::Emulator::DBI>.

=cut
