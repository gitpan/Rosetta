=head1 NAME

Rosetta::Validator - A common comprehensive test suite to run against all Engines

=cut

######################################################################

package Rosetta::Validator;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.38';

use Rosetta '0.38';

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Rosetta 0.38

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

# Names of properties for objects of the Rosetta::Validator class are declared here:
# These are static configuration properties:
my $PROP_TRACE_FH = 'trace_fh'; # ref to writeable Perl file handle
my $PROP_ENGINE_NAME = 'engine_name'; # str - Name of the Rosetta Engine module to test.
my $PROP_ENGINE_ECO = 'engine_eco'; # hash(str,str) - Engine Config Options for module to test.
# These are just used internally for holding state:
my $PROP_ENG_ENV_FEAT = 'eng_env_feat'; # The Engine's declared feature support at Env level.
my $PROP_TEST_RESULTS = 'test_results'; # Accumulate test results while tests being run.

# Names of $PROP_TEST_RESULTS list elements go here:
my $TR_FEATURE_KEY = 'FEATURE_KEY';
my $TR_FEATURE_STATUS = 'FEATURE_STATUS';
my $TR_FEATURE_DESC_MSG = 'FEATURE_DESC_MSG'; # object (Locale::KeyedText::Message) - 
	# This is the Validator module's description of what DBMS/Engine feature is being tested.
my $TR_VAL_ERROR_MSG = 'VAL_ERROR_MSG'; # object (Locale::KeyedText::Message) - 
	# This is the Validator module's own Error Message, if a test failed.
	# This is made for a failure regardless of whether the Engine threw its own exception.
my $TR_ENG_ERROR_MSG = 'ENG_ERROR_MSG'; # object (Locale::KeyedText::Message) - 
	# This is the Error Message that the Rosetta Interface or Engine threw, if any.

# Possible values for $TR_STATUS go here:
my $TRS_SKIP = 'SKIP'; # the test was not run at all (Engine said it lacked feature to be tested)
my $TRS_PASS = 'PASS'; # the test was run and passed (Engine said it had feature to be tested)
my $TRS_FAIL = 'FAIL'; # the test was run and failed (Engine said it had feature to be tested)

# Other constant values go here:
my $TOTAL_POSSIBLE_TESTS = 5; # how many elements should be in results array (S+P+F) 

######################################################################

sub total_possible_tests {
	return( $TOTAL_POSSIBLE_TESTS );
}

######################################################################
# These are private utility functions.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	die Locale::KeyedText->new_message( $error_code, $args );
}

######################################################################
# These are private utility functions.

sub _new_result {
	my ($validator, $feature_key) = @_;
	my $result = {
		$TR_FEATURE_KEY => $feature_key,
		$TR_FEATURE_STATUS => $TRS_SKIP,
		$TR_FEATURE_DESC_MSG => Locale::KeyedText->new_message( 'ROSVAL_DESC_'.$feature_key ),
	};
	push( @{$validator->{$PROP_TEST_RESULTS}}, $result );
	return( $result );
}

sub _pass_result {
	my ($validator, $result) = @_;
	$result->{$TR_FEATURE_STATUS} = $TRS_PASS;
}

sub _fail_result {
	my ($validator, $result, $error_code, $args, $eng_message) = @_;
	$result->{$TR_FEATURE_STATUS} = $TRS_FAIL;
	$result->{$TR_VAL_ERROR_MSG} = Locale::KeyedText->new_message( $error_code, $args );
	if( $eng_message ) {
		if( ref($eng_message) and UNIVERSAL::isa( $eng_message, 'Rosetta::Interface' ) ) {
			$eng_message = $eng_message->get_error_message();
		}
		$result->{$TR_ENG_ERROR_MSG} = $eng_message;
	}
}

sub _misc_result {
	my ($validator, $result, $exception) = @_;
	if( $exception ) {
		if( ref($exception) ) {
			$validator->_fail_result( $result, 'ROSVAL_FAIL_MISC_OBJ', undef, $exception );
		} else {
			$validator->_fail_result( $result, 'ROSVAL_FAIL_MISC_STR', { 'VALUE' => $exception } );
		}
	} else {
		$validator->_pass_result( $result );
	}
}

######################################################################
# These are private utility functions.

sub _setup_test {
	my ($validator) = @_;
	my $engine_name = $validator->{$PROP_ENGINE_NAME};

	my $model = SQL::Routine->new_container();
	$model->auto_assert_deferrable_constraints( 1 );
	$model->auto_set_node_ids( 1 );

	my $dlp_node = $model->build_node( 'data_link_product', 
		{ 'name' => $engine_name, 'product_code' => $engine_name, } );

	my $app_bp_node = $model->build_node( 'application', 
		{ 'name' => 'Validator Application Blueprint' } );
	my $app_inst_node = $model->build_node( 'application_instance', 
		{ 'name' => 'Validator Application Instance', 'blueprint' => $app_bp_node } );

	my $app_intf = Rosetta->new_application( $app_inst_node );
	$app_intf->set_trace_fh( $validator->{$PROP_TRACE_FH} );

	$model->assert_deferrable_constraints();

	return( $app_intf );
}

sub _takedown_test {
	my ($validator, $app_intf) = @_;
	my $model = $app_intf->get_srt_node()->get_container();
	$validator->_takedown_test_destroy_intf_tree( $app_intf );
	$model->destroy();
}

sub _takedown_test_destroy_intf_tree {
	my ($validator, $intf) = @_;
	foreach my $child_intf (@{$intf->get_child_interfaces()}) {
		$validator->_takedown_test_destroy_intf_tree( $child_intf );
	}
	$intf->destroy();
}

######################################################################

sub new {
	my ($class) = @_;
	my $validator = bless( {}, ref($class) || $class );

	$validator->{$PROP_TRACE_FH} = undef;
	$validator->{$PROP_ENGINE_NAME} = undef;
	$validator->{$PROP_ENGINE_ECO} = {};
	$validator->{$PROP_ENG_ENV_FEAT} = {};
	$validator->{$PROP_TEST_RESULTS} = [];

	return( $validator );
}

######################################################################

sub get_trace_fh {
	my ($validator) = @_;
	return( $validator->{$PROP_TRACE_FH} );
}

sub clear_trace_fh {
	my ($validator) = @_;
	$validator->{$PROP_TRACE_FH} = undef;
}

sub set_trace_fh {
	my ($validator, $new_fh) = @_;
	$validator->{$PROP_TRACE_FH} = $new_fh;
}

######################################################################

sub get_engine_name {
	my ($validator) = @_;
	return( $validator->{$PROP_ENGINE_NAME} );
}

sub clear_engine_name {
	my ($validator) = @_;
	$validator->{$PROP_ENGINE_NAME} = undef;
}

sub set_engine_name {
	my ($validator, $engine_name) = @_;
	defined( $engine_name ) or $validator->_throw_error_message( 'ROSVAL_SET_ENG_NO_ARG' );
	$validator->{$PROP_ENGINE_NAME} = $engine_name;
}

######################################################################

sub get_engine_config_option {
	my ($validator, $eco_name) = @_;
	defined( $eco_name ) or $validator->_throw_error_message( 'ROSVAL_GET_ECO_NO_ARG' );
	return( $validator->{$PROP_ENGINE_ECO}->{$eco_name} );
}

sub get_engine_config_options {
	my ($validator) = @_;
	return( {%{$validator->{$PROP_ENGINE_ECO}}} );
}

sub clear_engine_config_option {
	my ($validator, $eco_name) = @_;
	defined( $eco_name ) or $validator->_throw_error_message( 'ROSVAL_CLEAR_ECO_NO_ARG' );
	$validator->{$PROP_ENGINE_ECO}->{$eco_name} = undef;
}

sub clear_engine_config_options {
	my ($validator) = @_;
	%{$validator->{$PROP_ENGINE_ECO}} = ();
}

sub set_engine_config_option {
	my ($validator, $eco_name, $eco_value) = @_;
	defined( $eco_name ) or $validator->_throw_error_message( 'ROSVAL_SET_ECO_NO_NAME' );
	defined( $eco_value ) or $validator->_throw_error_message( 'ROSVAL_SET_ECO_NO_VALUE' );
	$validator->{$PROP_ENGINE_ECO}->{$eco_name} = $eco_value;
}

sub set_engine_config_options {
	my ($validator, $ec_opts) = @_;
	defined( $ec_opts ) or $validator->_throw_error_message( 'ROSVAL_SET_ECOS_NO_ARGS' );
	unless( ref($ec_opts) eq 'HASH' ) {
		$validator->_throw_error_message( 'ROSVAL_SET_ECOS_BAD_ARGS', { 'ARG' => $ec_opts } );
	}
	%{$validator->{$PROP_ENGINE_ECO}} = (%{$validator->{$PROP_ENGINE_ECO}}, %{$ec_opts});
}

######################################################################

sub get_test_results {
	my ($validator) = @_;
	return( [@{$validator->{$PROP_TEST_RESULTS}}] );
}

sub clear_test_results {
	my ($validator) = @_;
	@{$validator->{$PROP_TEST_RESULTS}} = ();
}

######################################################################

sub perform_tests {
	my ($validator) = @_;
	defined( $validator->{$PROP_ENGINE_NAME} ) or 
		$validator->_throw_error_message( 'ROSVAL_PER_TESTS_NO_ENG_NM' );
	$validator->perform_tests_load();
	$validator->perform_tests_catalog_list();
	$validator->perform_tests_catalog_info();
	$validator->perform_tests_conn_basic();
	$validator->perform_tests_tran_basic();
}

######################################################################

sub perform_tests_load {
	my ($validator) = @_;
	my $result = $validator->_new_result( 'LOAD' );
	$validator->{$PROP_ENGINE_NAME} or return( 1 ); # all tests skipped

	my $app_intf = $validator->_setup_test();
	my $model = $app_intf->get_srt_node()->get_container();
	my $dlp_node = $model->get_node( 'data_link_product', 1 );

	SWITCH: {
		my $env_intf = eval {
			my $prep_intf = $app_intf->prepare( $dlp_node );
			return( $prep_intf->execute() );
		};
		$validator->_misc_result( $result, $@ ); $@ and last SWITCH;

		$validator->{$PROP_ENG_ENV_FEAT} = eval {
			return( $env_intf->features() );
		};
		$validator->_misc_result( $result, $@ ); $@ and last SWITCH;
	}

	$validator->_takedown_test( $app_intf );
}

######################################################################

sub perform_tests_catalog_list {
	my ($validator) = @_;
	my $result = $validator->_new_result( 'CATALOG_LIST' );

	$validator->{$PROP_ENG_ENV_FEAT}->{'CATALOG_LIST'} or return;

	my $app_intf = $validator->_setup_test();
	my $model = $app_intf->get_srt_node()->get_container();
	my $app_bp_node = $app_intf->get_srt_node()->get_node_ref_attribute( 'blueprint' );

	my $routine_node = $app_bp_node->build_child_node_tree( 'routine', 
		{ 'name' => 'catalog_list', 'routine_type' => 'FUNCTION', 'return_cont_type' => 'SRT_NODE_LIST' }, 
		[
			[ 'routine_stmt', { 'call_sroutine' => 'RETURN' }, 
				[
					[ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 
						'cont_type' => 'SRT_NODE_LIST', 'valf_call_sroutine' => 'CATALOG_LIST' } ],
				],
			],
		],
	);
	$model->assert_deferrable_constraints();

	SWITCH: {
		my $payload = eval {
			my $prep_intf = $app_intf->prepare( $routine_node );
			my $lit_intf = $prep_intf->execute();
			my $payload = $lit_intf->payload();
			$model->assert_deferrable_constraints();
			return( $payload );
		};
		$validator->_misc_result( $result, $@ ); $@ and last SWITCH;

		if( my $trace_fh = $validator->{$PROP_TRACE_FH} ) {
			my $engine_name = $validator->{$PROP_ENGINE_NAME};
			print $trace_fh "$engine_name returned a Literal Interface having this payload:".
				"\n----------\n".
				join( "", map { $_->get_all_properties_as_xml_str() } @{$payload} ).
				"\n----------\n";
		}
	}

	$validator->_takedown_test( $app_intf );
}

######################################################################

sub perform_tests_catalog_info {
	my ($validator) = @_;
	my $result = $validator->_new_result( 'CATALOG_INFO' );

	$validator->{$PROP_ENG_ENV_FEAT}->{'CATALOG_INFO'} or return;

	# ... TODO ...
}

######################################################################

sub perform_tests_conn_basic {
	my ($validator) = @_;
	my $result = $validator->_new_result( 'CONN_BASIC' );

	$validator->{$PROP_ENG_ENV_FEAT}->{'CONN_BASIC'} or return;

	my $rh_config = $validator->{$PROP_ENGINE_ECO};

	my $app_intf = $validator->_setup_test();
	my $app_inst_node = $app_intf->get_srt_node();
	my $app_bp_node = $app_inst_node->get_node_ref_attribute( 'blueprint' );
	my $model = $app_inst_node->get_container();
	my $dlp_node = $model->get_node( 'data_link_product', 1 );

	my $sdt_auth_node = $model->build_node( 'scalar_data_type', 
		{ 'name' => 'loginauth', 'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8' } );

	my $cat_bp_node = $model->build_node( 'catalog', 
		{ 'name' => 'Validator Catalog Blueprint' } );
	my $cat_link_bp_node = $app_bp_node->build_child_node( 'catalog_link', 
		{ 'name' => 'da_link', 'target' => $cat_bp_node } );

	my $rt_decl_node = $app_bp_node->build_child_node( 'routine', 
		{ 'name' => 'declare_db_conn', 'routine_type' => 'FUNCTION', 'return_cont_type' => 'CONN' } );
	my $rtv_decl_conn_cx_node = $rt_decl_node->build_child_node( 'routine_var', 
		{ 'name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => $cat_link_bp_node } );
	my $rts_decl_return_node = $rt_decl_node->build_child_node_tree( 'routine_stmt', 
		{ 'call_sroutine' => 'RETURN' }, 
		[
			[ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 
				'cont_type' => 'CONN', 'valf_p_routine_var' => $rtv_decl_conn_cx_node } ],
		],
	);

	my $rt_open_node = $app_bp_node->build_child_node( 'routine', 
		{ 'name' => 'open_db_conn', 'routine_type' => 'PROCEDURE' } );
	my $rtc_open_conn_cx_node = $rt_open_node->build_child_node( 'routine_context', 
		{ 'name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => $cat_link_bp_node } );
	my $rta_open_user_node = $rt_open_node->build_child_node( 'routine_arg', 
		{ 'name' => 'login_name', 'cont_type' => 'SCALAR', 'scalar_data_type' => $sdt_auth_node } );
	my $rta_open_pass_node = $rt_open_node->build_child_node( 'routine_arg', 
		{ 'name' => 'login_pass', 'cont_type' => 'SCALAR', 'scalar_data_type' => $sdt_auth_node } );
	my $rts_open_node = $rt_open_node->build_child_node_tree( 'routine_stmt', 
		{ 'call_sroutine' => 'CATALOG_OPEN' }, 
		[
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 
				'cont_type' => 'CONN', 'valf_p_routine_cxt' => $rtc_open_conn_cx_node } ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_NAME', 
				'cont_type' => 'SCALAR', 'valf_p_routine_arg' => $rta_open_user_node } ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_PASS', 
				'cont_type' => 'SCALAR', 'valf_p_routine_arg' => $rta_open_pass_node } ],
		],
	);

	my $rt_close_node = $app_bp_node->build_child_node( 'routine', 
		{ 'name' => 'close_db_conn', 'routine_type' => 'PROCEDURE' } );
	my $rtc_close_conn_cx_node = $rt_close_node->build_child_node( 'routine_context', 
		{ 'name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => $cat_link_bp_node } );
	my $rts_close_node = $rt_close_node->build_child_node_tree( 'routine_stmt', 
		{ 'call_sroutine' => 'CATALOG_CLOSE' }, 
		[
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 
				'cont_type' => 'CONN', 'valf_p_routine_cxt' => $rtc_close_conn_cx_node } ],
		],
	);

	my $dsp_node = $model->build_node( 'data_storage_product', 
		{ 'name' => 'The Data Storage Product', 
		'product_code' => ($rh_config->{'product_code'} || 'ExampleP'),
		'is_local_proc' => 0 } );

	my $cat_inst_node = $model->build_node( 'catalog_instance', 
		{ 'name' => 'Validator Catalog Instance', 'product' => $dsp_node, 'blueprint' => $cat_bp_node } );
	my $cat_link_inst_node = $app_inst_node->build_child_node( 'catalog_link_instance', 
		{ 'product' => $dlp_node, 'unrealized' => $cat_link_bp_node, 'target' => $cat_inst_node } );

	foreach my $opt_key (keys %{$rh_config}) {
		my $opt_value = $rh_config->{$opt_key};
		$cat_link_inst_node->build_child_node( 'catalog_link_instance_opt', 
			{ 'key' => $opt_key, 'value' => $opt_value } );
	}

	$model->assert_deferrable_constraints();

	SWITCH: {
		my $conn_intf = eval {
			my $prep_intf = $app_intf->prepare( $rt_decl_node );
			return( $prep_intf->execute() );
		};
		$validator->_misc_result( $result, $@ ); $@ and last SWITCH;

		eval {
			my $prep_intf = $conn_intf->prepare( $rt_open_node );
			$prep_intf->execute();
		};
		$validator->_misc_result( $result, $@ ); $@ and last SWITCH;

		eval {
			my $prep_intf = $conn_intf->prepare( $rt_close_node );
			$prep_intf->execute();
		};
		$validator->_misc_result( $result, $@ ); $@ and last SWITCH;
	}

	$validator->_takedown_test( $app_intf );
}

######################################################################

sub perform_tests_tran_basic {
	my ($validator) = @_;
	my $result = $validator->_new_result( 'TRAN_BASIC' );

	$validator->{$PROP_ENG_ENV_FEAT}->{'TRAN_BASIC'} or return;

	# ... TODO ...
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

This example demonstrates how Rosetta::Validator could be used in the standard
test suite for an Engine module; in fact, this example is a simplified version
of the actual t/*.t file for the Rosetta::Engine::Generic module.

	#!/usr/bin/perl

	use strict; use warnings;
	use Rosetta::Validator;

	BEGIN { $| = 1; }

	my $test_num = 0;

	sub print_result {
		my ($result) = @_;
		$test_num ++;
		my ($feature_key, $feature_status, $feature_desc_msg, $val_error_msg, $eng_error_msg) = 
			@{$result}{'FEATURE_KEY', 'FEATURE_STATUS', 'FEATURE_DESC_MSG', 'VAL_ERROR_MSG', 'ENG_ERROR_MSG'};
		my $result_str = 
			($feature_status eq 'PASS' ? "ok $test_num (PASS)" : 
				$feature_status eq 'FAIL' ? "not ok $test_num (FAIL)" : 
				"ok $test_num (SKIP)").
			" - $feature_key - ".object_to_string( $feature_desc_msg ).
			($val_error_msg ? ' - '.object_to_string( $val_error_msg ) : '').
			($eng_error_msg ? ' - '.object_to_string( $eng_error_msg ) : '');
		print "$result_str\n";
	}

	sub object_to_string {
		my ($message) = @_;
		if( ref($message) and UNIVERSAL::isa( $message, 'Rosetta::Interface' ) ) {
			$message = $message->get_error_message();
		}
		if( ref($message) and UNIVERSAL::isa( $message, 'Locale::KeyedText::Message' ) ) {
			my $translator = Locale::KeyedText->new_translator( ['Rosetta::Engine::Generic::L::', 
				'Rosetta::Validator::L::', 'Rosetta::L::', 'SQL::Routine::L::'], ['en'] );
			my $user_text = $translator->translate_message( $message );
			unless( $user_text ) {
				return( "internal error: can't find user text for a message: ".
					$message->as_string()." ".$translator->as_string() );
			}
			return( $user_text );
		}
		return( $message ); # if this isn't the right kind of object
	}

	eval {
		my $total_tests_per_invoke = Rosetta::Validator->total_possible_tests();
		print "1..$total_tests_per_invoke\n";

		my $config_filepath = shift( @ARGV ); # set from first command line arg; '0' means none
		my $rh_config = {};
		if( $config_filepath ) {
			$rh_config = do $config_filepath;
		}

		my $trace_to_stdout = shift( @ARGV ) ? 1 : 0; # set from second command line arg

		my $validator = Rosetta::Validator->new();
		$trace_to_stdout and $validator->set_trace_fh( \*STDOUT );
		$validator->set_engine_name( 'Rosetta::Engine::Generic' );
		$validator->set_engine_config_options( $rh_config );

		$validator->perform_tests();

		foreach my $result (@{$validator->get_test_results()}) {
			print_result( $result );
		}
	};
	$@ and print "TESTS ABORTED: ".object_to_string( $@ ); # errors in test suite itself, or core modules

	1;

Here is the content of an example configuration file that one can use with said
test script:

	my $rh_config = {
		'product_code' => 'MySQL',
		'local_dsn' => 'test',
		'login_name' => 'jane',
		'login_pass' => 'pwd',
	};

=head1 DESCRIPTION

The Rosetta::Validator Perl 5 module is a common comprehensive test suite to
run against all Rosetta Engines.  You run it against a Rosetta Engine module to
ensure that the Engine and/or the database behind it implements the parts of
the Rosetta API that your application needs, and that the API is implemented
correctly.  Rosetta::Validator is intended to guarantee a measure of quality
assurance (QA) for Rosetta, so your application can use the database access
framework with confidence of safety.

Alternately, if you are writing a Rosetta Engine module yourself,
Rosetta::Validator saves you the work of having to write your own test suite
for it.  You can also be assured that if your module passes
Rosetta::Validator's approval, then your module can be easily swapped in for
other Engine modules by your users, and that any changes you make between
releases haven't broken something important.

Rosetta::Validator would be used similarly to how Sun has an official
validation suite for Java Virtual Machines to make sure they implement the
official Java specification.

For reference and context, please see the FEATURE SUPPORT VALIDATION
documentation section in the core "Rosetta" module.

Note that, as is the nature of test suites, Rosetta::Validator will be getting
regular updates and additions, so that it anticipates all of the different ways
that people want to use their databases.  This task is unlikely to ever be
finished, given the seemingly infinite size of the task.  You are welcome and
encouraged to submit more tests to be included in this suite at any time, as
holes in coverage are discovered.

=head1 CONSTRUCTOR FUNCTIONS AND METHODS

This function/method is stateless and can be invoked off of either this
module's name or an existing module object, with the same result.

=head2 new()

	my $validator = Rosetta::Validator->new();
	my $validator2 = $validator->new();

This "getter" function/method will create and return a single
Rosetta::Validator (or subclass) object.  All of this object's properties are
set to default undefined values; you will at the very least have to set
engine_name() afterwards.

=head1 STATIC CONFIGURATION PROPERTY ACCESSOR METHODS

These methods are stateful and can only be invoked from this module's objects.
This set of properties are generally set once at the start of a Validator
object's life and aren't changed later (though they can be), since they are
generally static configuration data.

=head2 get_trace_fh()

	my $fh = $validator->get_trace_fh();

This "getter" method returns by reference the writeable Perl trace file handle
property of of this object, if it is set.  When set, details of what
Rosetta::Validator and the Engines that it tests are doing will be written to
the file handle; to turn off the tracing, just clear the property.  This class
does not open or close the file; your external code must do that.

=head2 clear_trace_fh()

	$validator->clear_trace_fh();

This "setter" method clears the trace file handle property of this object, if
it was set, thereby turning off any tracing output.

=head2 set_trace_fh( NEW_FH )

	$validator->set_trace_fh( \*STDOUT );

This "setter" method sets or replaces the trace file handle property of this
object to a new writeable Perl file handle, provided in NEW_FH, so any
subsequent tracing output is sent there.

=head2 get_engine_name()

	my $engine_name = $validator->get_engine_name();

This "getter" method returns this object's "engine name" character string
property.  This property defines the name of the Rosetta Engine module that you
want this Validator object to test.

=head2 clear_engine_name()

	$validator->clear_engine_name();

This "setter" method clears the "engine name" property.

=head2 set_engine_name( ENGINE_NAME )

	$validator->set_engine_name( 'Rosetta::Engine::Generic' );

This "setter" method sets or replaces the "engine name" property.

=head2 get_engine_config_option( ECO_NAME )

This "getter" method will return one value for this object's "engine
configuration options" property, which matches the ECO_NAME argument.  This
property sets up operational parameters for the Rosetta Engine module, where it
takes options; examples being the name of the data source name or the
authorization identifier to use.

=head2 get_engine_config_options()

This "getter" method will fetch all of this object's "engine configuration
options", returning them in a Hash ref.

=head2 clear_engine_config_option( ECO_NAME )

This "setter" method will clear one "engine configuration options" value, which
matches the ECO_NAME argument.

=head2 clear_engine_config_options()

This "setter" method will clear all of the "engine configuration options".

=head2 set_engine_config_option( ECO_NAME, ECO_VALUE )

	$validator->set_engine_config_option( 'local_dsn', 'test' );
	$validator->set_engine_config_option( 'dbi_driver', 'mysql' );

This "setter" method will set or replace one "engine configuration options"
value, which matches the ECO_NAME argument, giving it the new value specified
in ECO_VALUE.

=head2 set_engine_config_options( EC_OPTS )

	$validator->set_engine_config_options( { 'login_name' => 'jane', 'login_pass' => 'pawd' } );

This "setter" method will set or replace multiple "engine configuration
options" values, whose names and values are specified by keys and values of the
EC_OPTS hash ref argument.

=head1 DYNAMIC STATE MAINTENANCE PROPERTY ACCESSOR METHODS

These methods are stateful and can only be invoked from this module's objects.
Each of these contains the results of a test performing method call.

=head2 get_test_results()

This "getter" method returns a new array ref having a copy of this object's
"test results" array property.  This property is explicitely emptied by
external code, by invoking the clear_test_results() method, prior to that code
requesting that we perform one or more tests.  As soon as said tests are
performed, external code reads this array's values using the get_test_results()
method.  Each element of the "test results" array is a hash ref containing
these 5 elements:  1. 'FEATURE_KEY'.  2. 'FEATURE_STATUS'; one of 'SKIP' (test
was not run at all), 'PASS' (test was run and passed), 'FAIL' (test was run and
failed); for the first 2, the Engine said it had support for the feature, and
for the third it said that it did not.  3. 'FEATURE_DESC_MSG'; a
Locale::KeyedText::Message (LKT) object that is the Validator module's
description of what DBMS/Engine feature is being tested.  4. 'VAL_ERROR_MSG'; a
LKT object that is set when 'FEATURE_STATUS' is 'FAIL'; this is the Validator
module's own Error Message, if a test failed; this is made for a failure
regardless of whether the Engine threw its own exception.  5. 'ENG_ERROR_MSG';
a LKT object that is the Error Message that the Rosetta Interface or Engine
threw, if any.

=head2 clear_test_results()

This "setter" method empties this object's "positional host param map array"
array property.  See the previous method's documentation for when to use it.

=head1 TEST PERFORMING METHODS

These methods are stateful and can only be invoked from this module's objects.
These methods comprise the core of the Rosetta::Validator module, and are what 
actually perform the tests on the Rosetta Engines.

=head2 perform_tests()

This method will instantiate a new Rosetta Interface tree, and a SQL::Routine
Container, populate the latter, invoke the former, saying to use the Engine
specified in the "engine name" property, try all sorts of database actions, and
record the results in the "test results" property, and then destroy the Rosetta
and SQL::Routine objects.

=head1 INFORMATION FUNCTIONS AND METHODS

These "getter" functions/methods return Rosetta::Validator constant information
which is useful when interpreting or using other aspects of the class.

=head2 total_possible_tests()

This method returns an integer that says how many elements are supposed to be
in the "test results" array after perform_tests() is run; it should be equal to
the number of skips + passes + fails.  You can use this number at the start of
your test script when declaring the 1..N total number of tests that will be
considered, and you can compare that to the actual results.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

perl(1), Rosetta, SQL::Routine, Locale::KeyedText, Rosetta::Engine::Generic.

=cut
