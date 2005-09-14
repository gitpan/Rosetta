#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Validator;
use version; our $VERSION = qv('0.48.2');

use only 'Rosetta' => '0.48.2';

######################################################################
######################################################################

# Names of properties for objects of the Rosetta::Validator class are declared here:
# These are static configuration properties:
my $PROP_TRACE_FH = 'trace_fh'; # ref to writeable Perl file handle
my $PROP_SETUP_OPTS = 'setup_opts'; # hash(str,hash(str,str)) - 
    # Says what Engine to test and how to configure it to work in the tester's environment.
    # Outer hash has a SRT Node name as a key and a hash of attribute name/value pairs as the value.
# These are just used internally for holding state:
my $PROP_TEST_RESULTS = 'test_results'; # Accumulate test results while tests being run.
my $PROP_ENG_ENV_FEAT = 'eng_env_feat'; # The Engine's declared feature support at Env level.
my $PROP_ENG_CONN_FEAT = 'eng_conn_feat'; # The Engine's declared feature support at Conn level.

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

# Names of SRT Node types and attributes that may be given in SETUP_OPTIONS for main():
my %BC_SETUP_NODE_TYPES = ();
foreach my $_node_type (qw( 
            data_storage_product data_link_product catalog_instance catalog_link_instance
        )) {
    my $attrs = $BC_SETUP_NODE_TYPES{$_node_type} = {}; # node type accepts only specific key names
    foreach my $attr_name (keys %{SQL::Routine->valid_node_type_literal_attributes( $_node_type ) || {}}) {
        $attr_name eq 'si_name' and next; # All 'si_name' attrs are set by us, not the user.
        $attrs->{$attr_name} = 1;
    }
    foreach my $attr_name (keys %{SQL::Routine->valid_node_type_enumerated_attributes( $_node_type ) || {}}) {
        $attrs->{$attr_name} = 1;
    }
    # All nref attrs are set by us, not the user.
}
$BC_SETUP_NODE_TYPES{'catalog_instance_opt'} = 1; # node type accepts any key name
$BC_SETUP_NODE_TYPES{'catalog_link_instance_opt'} = 1; # node type accepts any key name

######################################################################

sub total_possible_tests {
    return $TOTAL_POSSIBLE_TESTS;
}

######################################################################

sub validate_connection_setup_options {
    my ($validator, $setup_options) = @_;
    defined( $setup_options ) or die Locale::KeyedText->new_message( 'ROS_VAL_V_CONN_SETUP_OPTS_NO_ARG' );
    unless( ref($setup_options) eq 'HASH' ) {
        die Locale::KeyedText->new_message( 'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG', { 'ARG' => $setup_options } );
    }
    while( my ($node_type, $rh_attrs) = each %{$setup_options} ) {
        unless( $BC_SETUP_NODE_TYPES{$node_type} ) {
            die Locale::KeyedText->new_message( 'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG_NTYPE', 
            { 'GIVEN' => $node_type, 'ALLOWED' => "@{[keys %BC_SETUP_NODE_TYPES]}" } );
        }
        defined( $rh_attrs ) or die Locale::KeyedText->new_message( 
            'ROS_VAL_V_CONN_SETUP_OPTS_NO_ARG_ELEM', { 'NTYPE' => $node_type } );
        unless( ref($rh_attrs) eq 'HASH' ) {
            die Locale::KeyedText->new_message( 'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG_ELEM', 
                { 'NTYPE' => $node_type, 'ARG' => $rh_attrs } );
        }
        ref($BC_SETUP_NODE_TYPES{$node_type}) eq 'HASH' or next; # all opt names accepted
        while( my ($option_name, $option_value) = each %{$rh_attrs} ) {
            unless( $BC_SETUP_NODE_TYPES{$node_type}->{$option_name} ) {
                die Locale::KeyedText->new_message( 'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG_OPTNM', 
                    { 'NTYPE' => $node_type, 'GIVEN' => $option_name, 
                    'ALLOWED' => "@{[keys %{$BC_SETUP_NODE_TYPES{$node_type}}]}" } );
            }
        }
    }
    unless( $setup_options->{'data_link_product'} and 
            $setup_options->{'data_link_product'}->{'product_code'} ) {
        die Locale::KeyedText->new_message( 'ROS_VAL_V_CONN_SETUP_OPTS_NO_ENG_NM' );
    }
}

######################################################################

sub main {
    my ($class, $setup_options, $trace_fh) = @_;
    my $validator = bless( {}, ref($class) || $class );

    $validator->validate_connection_setup_options( $setup_options ); # dies on problem

    $validator->{$PROP_TRACE_FH} = $trace_fh; # may be undef
    $validator->{$PROP_SETUP_OPTS} = $setup_options;
    $validator->{$PROP_TEST_RESULTS} = [];
    $validator->{$PROP_ENG_ENV_FEAT} = {};
    $validator->{$PROP_ENG_CONN_FEAT} = {};

    $validator->main_dispatch(); # any errors generated here go in TEST_RESULTS, presumably

    return $validator->{$PROP_TEST_RESULTS}; # by ref not a problem, orig ref is now gone
}

######################################################################

sub new_result {
    my ($validator, $feature_key) = @_;
    my $result = {
        $TR_FEATURE_KEY => $feature_key,
        $TR_FEATURE_STATUS => $TRS_SKIP,
        $TR_FEATURE_DESC_MSG => Locale::KeyedText->new_message( 'ROS_VAL_DESC_'.$feature_key ),
    };
    push( @{$validator->{$PROP_TEST_RESULTS}}, $result );
    return $result;
}

sub pass_result {
    my ($validator, $result) = @_;
    $result->{$TR_FEATURE_STATUS} = $TRS_PASS;
}

sub fail_result {
    my ($validator, $result, $error_msg_key, $error_msg_args, $eng_message) = @_;
    $result->{$TR_FEATURE_STATUS} = $TRS_FAIL;
    $result->{$TR_VAL_ERROR_MSG} = Locale::KeyedText->new_message( $error_msg_key, $error_msg_args );
    if( $eng_message ) {
        if( ref($eng_message) and UNIVERSAL::isa( $eng_message, 'Rosetta::Interface' ) ) {
            $eng_message = $eng_message->get_error_message();
        }
        $result->{$TR_ENG_ERROR_MSG} = $eng_message;
    }
}

sub misc_result {
    my ($validator, $result, $exception) = @_;
    if( $exception ) {
        if( ref($exception) ) {
            $validator->fail_result( $result, 'ROS_VAL_FAIL_MISC_OBJ', undef, $exception );
        } else {
            $validator->fail_result( $result, 'ROS_VAL_FAIL_MISC_STR', { 'VALUE' => $exception } );
        }
    } else {
        $validator->pass_result( $result );
    }
}

######################################################################

sub setup_env {
    my ($validator) = @_;
    my $setup_options = $validator->{$PROP_SETUP_OPTS};

    my $container = SQL::Routine->new_container();
    $container->auto_assert_deferrable_constraints( 1 );
    $container->auto_set_node_ids( 1 );
    $container->may_match_surrogate_node_ids( 1 );

    my $app_bp_node = $container->build_node( 'application', { 'si_name' => 'val_app_bp' } );
    my $app_inst_node = $container->build_node( 'application_instance', 
        { 'si_name' => 'val_app_inst', 'blueprint' => $app_bp_node } );

    my $dlp_node = $container->build_node( 'data_link_product', 
        { 'si_name' => 'val_dlp', 'product_code' => $setup_options->{'data_link_product'}->{'product_code'} } );

    my $app_intf = Rosetta->new_application_interface( $app_inst_node );
    $app_intf->set_trace_fh( $validator->{$PROP_TRACE_FH} );
    my $env_intf = $app_intf->new_environment_interface( $app_intf, $dlp_node ); # dies if bad Engine
    return $env_intf;
}

sub setup_conn {
    my ($validator, $rt_si_name) = @_;
    my $setup_options = $validator->{$PROP_SETUP_OPTS};

    my $container = SQL::Routine->new_container();
    $container->auto_assert_deferrable_constraints( 1 );
    $container->auto_set_node_ids( 1 );
    $container->may_match_surrogate_node_ids( 1 );

    my $app_bp_node = $container->build_node( 'application', { 'si_name' => 'val_app_bp' } );
    my $app_inst_node = $container->build_node( 'application_instance', 
        { 'si_name' => 'val_app_inst', 'blueprint' => $app_bp_node } );

    $container->build_node( 'data_storage_product', 
        { 'si_name' => 'val_dsp', %{$setup_options->{'data_storage_product'} || {}} } );
    my $dlp_node = $container->build_node( 'data_link_product', 
        { 'si_name' => 'val_dlp', 'product_code' => $setup_options->{'data_link_product'}->{'product_code'} } );

    $container->build_node( 'catalog', { 'si_name' => 'val_cat_bp' } );
    my $cat_inst_node = $container->build_child_node_tree( 'catalog_instance', { 'si_name' => 'val_cat_inst', 
        'product' => 'val_dsp', 'blueprint' => 'val_cat_bp', %{$setup_options->{'catalog_instance'} || {}} } );
    while( my ($opt_key, $opt_value) = each %{$setup_options->{'catalog_instance_opt'} || {}} ) {
        $cat_inst_node->build_child_node( 'catalog_instance_opt', 
            { 'si_key' => $opt_key, 'value' => $opt_value } );
    }

    $app_bp_node->build_child_node( 'catalog_link', { 'si_name' => 'val_cat_link_bp', 'target' => 'val_cat_bp' } );
    my $cat_link_inst_node = $app_inst_node->build_child_node( 'catalog_link_instance', 
        { 'product' => 'val_dlp', 'blueprint' => 'val_cat_link_bp', 'target' => $cat_inst_node, 
        %{$setup_options->{'catalog_link_instance'} || {}} } );
    while( my ($opt_key, $opt_value) = each %{$setup_options->{'catalog_link_instance_opt'} || {}} ) {
        $cat_link_inst_node->build_child_node( 'catalog_link_instance_opt', 
            { 'si_key' => $opt_key, 'value' => $opt_value } );
    }

    my $routine_node = $app_bp_node->build_child_node_tree( 'routine', { 'si_name' => 'setup_conn', 
            'routine_type' => 'FUNCTION', 'return_cont_type' => 'CONN', 'return_conn_link' => 'val_cat_link_bp', }, [
        [ 'routine_var', { 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => 'val_cat_link_bp', }, ],
        [ 'routine_stmt', { 'call_sroutine' => 'RETURN', }, [
            [ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 
                'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
        ], ],
    ] );

    $container->build_child_node( 'scalar_data_type', { 'si_name' => 'login_auth', 
        'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8', } );
    $app_bp_node->build_child_node_tree( 'routine', { 'si_name' => 'sroutine_catalog_open', 
            'routine_type' => 'PROCEDURE', }, [
        [ 'routine_context', { 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => 'val_cat_link_bp', }, ],
        [ 'routine_arg', { 'si_name' => 'login_name', 'cont_type' => 'SCALAR', 'scalar_data_type' => 'login_auth' }, ],
        [ 'routine_arg', { 'si_name' => 'login_pass', 'cont_type' => 'SCALAR', 'scalar_data_type' => 'login_auth' }, ],
        [ 'routine_stmt', { 'call_sroutine' => 'CATALOG_OPEN', }, [
            [ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
            [ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_NAME', 'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'login_name', }, ],
            [ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_PASS', 'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'login_pass', }, ],
        ], ],
    ] );

    $app_bp_node->build_child_node_tree( 'routine', { 'si_name' => 'sroutine_catalog_close', 
            'routine_type' => 'PROCEDURE', }, [
        [ 'routine_context', { 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => 'val_cat_link_bp', }, ],
        [ 'routine_stmt', { 'call_sroutine' => 'CATALOG_CLOSE', }, [
            [ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
        ], ],
    ] );

    my $app_intf = Rosetta->new_application_interface( $app_inst_node );
    $app_intf->set_trace_fh( $validator->{$PROP_TRACE_FH} );
    my $env_intf = $app_intf->new_environment_interface( $app_intf, $dlp_node ); # dies if bad Engine
    my $conn_intf = $env_intf->do( $routine_node );
    return $conn_intf;
}

######################################################################

sub main_dispatch {
    my ($validator) = @_;
    $validator->test_load();
    $validator->test_catalog_list();
    $validator->test_catalog_info();
    $validator->test_conn_basic();
    $validator->test_tran_basic();
}

######################################################################

sub test_load {
    my ($validator) = @_;
    my $result = $validator->new_result( 'LOAD' );

    SWITCH: {
        my $env_intf = eval {
            return $validator->setup_env();
        };
        $validator->misc_result( $result, $@ ); $@ and last SWITCH;

        $validator->{$PROP_ENG_ENV_FEAT} = eval {
            return $env_intf->features();
        };
        $validator->misc_result( $result, $@ ); $@ and last SWITCH;

        my $conn_intf = eval {
            return $validator->setup_conn( 'declare_db_conn' );
        };
        $validator->misc_result( $result, $@ ); $@ and last SWITCH;

        $validator->{$PROP_ENG_CONN_FEAT} = eval {
            return $conn_intf->features();
        };

        $validator->misc_result( $result, $@ ); $@ and last SWITCH;
    }
}

######################################################################

sub test_catalog_list {
    my ($validator) = @_;
    my $result = $validator->new_result( 'CATALOG_LIST' );

    $validator->{$PROP_ENG_ENV_FEAT}->{'CATALOG_LIST'} or return;

    my $env_intf = $validator->setup_env();
    my $container = $env_intf->get_srt_container();

    SWITCH: {
        my $payload = eval {
            my $app_inst_node = $env_intf->get_root_interface()->get_app_inst_node();
            my $app_bp_node = $app_inst_node->get_attribute( 'blueprint' );
            my $routine_node = $app_bp_node->build_child_node_tree( 'routine', { 'si_name' => 'sroutine_catalog_list', 
                    'routine_type' => 'FUNCTION', 'return_cont_type' => 'SRT_NODE_LIST', }, [
                [ 'routine_stmt', { 'call_sroutine' => 'RETURN', }, [
                    [ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 
                        'cont_type' => 'SRT_NODE_LIST', 'valf_call_sroutine' => 'CATALOG_LIST', }, ],
                ], ],
            ] );
            my $lit_intf = $env_intf->do( $routine_node );
            my $payload = $lit_intf->payload();
            $container->assert_deferrable_constraints();
            return $payload;
        };
        $validator->misc_result( $result, $@ ); $@ and last SWITCH;

        if( my $trace_fh = $validator->{$PROP_TRACE_FH} ) {
            my $engine_name = $validator->{$PROP_SETUP_OPTS}->{'data_link_product'}->{'product_code'};
            print $trace_fh "$engine_name returned a Literal Interface having this payload:".
                "\n----------\n".
                join( "", map { $_->get_all_properties_as_xml_str() } @{$payload} ).
                "\n----------\n";
        }
    }
}

######################################################################

sub test_catalog_info {
    my ($validator) = @_;
    my $result = $validator->new_result( 'CATALOG_INFO' );

    $validator->{$PROP_ENG_ENV_FEAT}->{'CATALOG_INFO'} or return;

    # ... TODO ...
}

######################################################################

sub test_conn_basic {
    my ($validator) = @_;
    my $result = $validator->new_result( 'CONN_BASIC' );

    $validator->{$PROP_ENG_ENV_FEAT}->{'CONN_BASIC'} or return;

    my $conn_intf = $validator->setup_conn( 'declare_db_conn' );
    my $container = $conn_intf->get_srt_container();

    SWITCH: {
        eval {
            $conn_intf->do( $container->find_child_node_by_surrogate_id( 
                [undef,'root','blueprints','val_app_bp','sroutine_catalog_open'] ) );
        };
        $validator->misc_result( $result, $@ ); $@ and last SWITCH;

        eval {
            $conn_intf->do( $container->find_child_node_by_surrogate_id( 
                [undef,'root','blueprints','val_app_bp','sroutine_catalog_close'] ) );
        };
        $validator->misc_result( $result, $@ ); $@ and last SWITCH;
    }
}

######################################################################

sub test_tran_basic {
    my ($validator) = @_;
    my $result = $validator->new_result( 'TRAN_BASIC' );

    $validator->{$PROP_ENG_ENV_FEAT}->{'TRAN_BASIC'} or return;

    # ... TODO ...
}

######################################################################
######################################################################

1;
__END__

=encoding utf8

=head1 NAME

Rosetta::Validator - A common comprehensive test suite to run against all Engines

=head1 VERSION

This document describes Rosetta::Validator version 0.48.2.

=head1 SYNOPSIS

This example demonstrates how Rosetta::Validator could be used in the
standard test suite for an Engine module; in fact, this example is a
simplified version of the actual t/*.t file for the
Rosetta::Engine::Generic module.

This is the content of a t_setup.pl, for a SQLite database:

    my $setup_options = {
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
    };

This is the content of a t_setup.pl, for a MySQL database:

    my $setup_options = {
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
    };

This is the content of a t_setup.pl, for a PostgreSQL database:

    my $setup_options = {
        'data_storage_product' => {
            'product_code' => 'PostgreSQL',
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
    };

This is a generalized version of Rosetta_Engine_Generic.t:

    #!perl
    use 5.008001; use utf8; use strict; use warnings;

    use Test::More;
    use Rosetta::Validator;

    plan( 'tests' => Rosetta::Validator->total_possible_tests() );

    sub print_result {
        my ($result) = @_;
        my ($feature_key, $feature_status, $feature_desc_msg, $val_error_msg, $eng_error_msg) = 
            @{$result}{'FEATURE_KEY', 'FEATURE_STATUS', 'FEATURE_DESC_MSG', 'VAL_ERROR_MSG', 'ENG_ERROR_MSG'};
        my $result_str = 
            $feature_key.' - '.object_to_string( $feature_desc_msg ).
            ($val_error_msg ? ' - '.object_to_string( $val_error_msg ) : '').
            ($eng_error_msg ? ' - '.object_to_string( $eng_error_msg ) : '');
        if( $feature_status eq 'PASS' ) {
            pass( $result_str ); # prints "ok N - $result_str\n"
        } elsif( $feature_status eq 'FAIL' ) {
            fail( $result_str ); # prints "not ok N - $result_str\n"
        } else { # $feature_status eq 'SKIP'
            SKIP: {
                skip( $result_str, 1 ); # prints "ok N # skip $result_str\n"
                fail( '' ); # this text will NOT be output; call required by skip()
            }
        }
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
                return 'internal error: can\'t find user text for a message: '.
                    $message->as_string().' '.$translator->as_string();
            }
            return $user_text;
        }
        return $message; # if this isn't the right kind of object
    }

    sub import_setup_options {
        my ($setup_filepath) = @_;
        my $err_str = "can't obtain test setup specs from Perl file '".$setup_filepath."'; ";
        my $setup_options = do $setup_filepath;
        unless( ref($setup_options) eq 'HASH' ) {
            if( defined( $setup_options ) ) {
                $err_str .= "result is not a hash ref, but '$setup_options'";
            } elsif( $@ ) {
                $err_str .= "compilation or runtime error of '$@'";
            } else {
                $err_str .= "file system error of '$!'";
            }
            die "$err_str\n";
        }
        unless( scalar( keys %{$setup_options} ) ) {
            die $err_str."result is a hash ref that contains no elements\n";
        }
        eval {
            Rosetta::Validator->validate_connection_setup_options( $setup_options ); # dies on problem
        };
        if( my $exception = $@ ) {
            die $err_str."result is a hash ref having invalid elements; ".
                object_to_string( $exception )."\n";
        }
        return $setup_options;
    }

    my $setup_filepath = shift( @ARGV ) || 't_setup.pl'; # set from first command line arg; '0' means use default name
    my $trace_to_stdout = shift( @ARGV ) ? 1 : 0; # set from second command line arg

    my $setup_options = import_setup_options( $setup_filepath ); # dies if bad config file
    my $trace_fh = $trace_to_stdout ? \*STDOUT : undef;

    my $test_results = Rosetta::Validator->main( $setup_options, $trace_fh ); # shouldn't ever die

    foreach my $result (@{$test_results}) {
        print_result( $result );
    }

    1;

=head1 DESCRIPTION

The Rosetta::Validator Perl 5 module is a common comprehensive test suite
to run against all Rosetta Engines.  You run it against a Rosetta Engine
module to ensure that the Engine and/or the database behind it implements
the parts of the Rosetta API that your application needs, and that the API
is implemented correctly.  Rosetta::Validator is intended to guarantee a
measure of quality assurance (QA) for Rosetta, so your application can use
the database access framework with confidence of safety.

Alternately, if you are writing a Rosetta Engine module yourself,
Rosetta::Validator saves you the work of having to write your own test
suite for it.  You can also be assured that if your module passes
Rosetta::Validator's approval, then your module can be easily swapped in
for other Engine modules by your users, and that any changes you make
between releases haven't broken something important.

Rosetta::Validator would be used similarly to how Sun has an official
validation suite for Java Virtual Machines to make sure they implement the
official Java specification.

For reference and context, please see the FEATURE SUPPORT VALIDATION
documentation section in the core "Rosetta" module.

Note that, as is the nature of test suites, Rosetta::Validator will be
getting regular updates and additions, so that it anticipates all of the
different ways that people want to use their databases.  This task is
unlikely to ever be finished, given the seemingly infinite size of the
task.  You are welcome and encouraged to submit more tests to be included
in this suite at any time, as holes in coverage are discovered.

=head1 PUBLIC FUNCTIONS

You invoke all of these functions off of the class name.  No
Rosetta::Validator objects are ever returned, so you can not invoke methods
off of them.

=head2 total_possible_tests()

This method returns an integer that says how many elements are supposed to
be in the "test results" array returned by main(); it should be equal to
the number of skips + passes + fails.  You can use this number at the start
of your test script when declaring the 1..N total number of tests that will
be considered, and you can compare that to the actual results.

=head2 validate_connection_setup_options( SETUP_OPTIONS )

This function is used internally by main() to confirm that its
SETUP_OPTIONS argument is valid, prior to it running any tests; it will
throw an exception if it can find anything wrong.  This function is public
so that external code can use it to perform advance validation on an
identical configuration structure without side-effects.  Note that this
function is not thorough; except for the 'data_link_product'.'product_code'
(Rosetta Engine class name), it does not test that Node attribute entries
in SETUP_OPTIONS have defined values, and even that single attribute isn't
tested beyond that it is defined.  Testing for defined and mandatory option
values is left to the SQL::Routine methods.

=head2 main( SETUP_OPTIONS[, TRACE_FH] )

This function comprises the core of the Rosetta::Validator module, and is
what actually performs the tests on the Rosetta Engines.  This method will
instantiate a new Rosetta Interface tree, and a SQL::Routine Container,
populate the latter, invoke the former, saying to use the Engine and
related configuration settings in SETUP_OPTIONS, try all sorts of database
actions, and record the results as "test results", and then let the Rosetta
and SQL::Routine objects be auto-destructed.  This function returns a new
array ref having the details of the test results.  The SETUP_OPTIONS
argument is a two-dimensional hash, where each outer hash element
corresponds to a Node type and each inner hash element corresponds to an
attribute name and value for that Node type. There are 6 allowed Node
types: data_storage_product, data_link_product, catalog_instance,
catalog_link_instance, catalog_instance_opt, catalog_link_instance_opt; the
first 4 have a specific set of actual scalar or enumerated attributes that
may be set; with the latter 2, you can set any number of virtual attributes
that you choose.  The "setup options" say what Rosetta Engine to test and
how to configure it to work in your customized environment. The actual
attributes of the first 4 Node types should be recognized by all Engines
and have the same meaning to them; you can set any or all of them (see the
SQL::Routine documentation for the list) except for "id" and "si_name",
which are given default generated values.  The build_connection() function
requires that, at the very least, you provide a
'data_link_product'.'product_code' SETUP_OPTIONS value, since that
specifies the class name of the Rosetta Engine that implements the
Connection.  The virtual attributes of the last 2 Node types are specific
to each Engine (see the Engine's documentation for a list), though an
Engine may not define any at all. The optional TRACE_FH argument is an open
file handle to be given to Rosetta.set_trace_fh().  This function should
return all errors in "test results" that aren't caught by
validate_connection_setup_options().

=head1 INTERPRETING THE TEST RESULTS

Each element of the test results array that main() returns is a hash ref
containing these 5 elements:  1. 'FEATURE_KEY'.  2. 'FEATURE_STATUS'; one
of 'SKIP' (test was not run at all), 'PASS' (test was run and passed),
'FAIL' (test was run and failed); for the first one, the Engine said it did
not have support for the feature, and for the last two, it said that it
did.  3. 'FEATURE_DESC_MSG'; a Locale::KeyedText::Message (LKT) object that
is the Validator module's description of what DBMS/Engine feature is being
tested.  4. 'VAL_ERROR_MSG'; a LKT object that is set when 'FEATURE_STATUS'
is 'FAIL'; this is the Validator module's own Error Message, if a test
failed; this is made for a failure regardless of whether the Engine threw
its own exception.  5. 'ENG_ERROR_MSG'; a LKT object that is the Error
Message that the Rosetta Interface or Engine threw, if any.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl modules L<version> and L<only>, which would
conceptually be built-in to Perl, but aren't, so they are on CPAN instead.

It also requires these modules that are in the current distribution:

    Rosetta 0.48.2

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Rosetta::Validator::L::en>, L<Rosetta>, L<SQL::Routine>,
L<Locale::KeyedText>, L<Rosetta::Engine::Generic>.

=head1 BUGS AND LIMITATIONS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible
ways.

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 2002-2005, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to C<perl@DarrenDuncan.net>,
or visit L<http://www.DarrenDuncan.net/> for more information.

Rosetta is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (L<http://www.fsf.org/>); either version 2 of the
License, or (at your option) any later version.  You should have received a
copy of the GPL as part of the Rosetta distribution, in the file named
"GPL"; if not, write to the Free Software Foundation, Inc., 51 Franklin St,
Fifth Floor, Boston, MA  02110-1301, USA.

Linking Rosetta statically or dynamically with other modules is making a
combined work based on Rosetta.  Thus, the terms and conditions of the GPL
cover the whole combination.  As a special exception, the copyright holders
of Rosetta give you permission to link Rosetta with independent modules,
regardless of the license terms of these independent modules, and to copy
and distribute the resulting combined work under terms of your choice,
provided that every copy of the combined work is accompanied by a complete
copy of the source code of Rosetta (the version of Rosetta used to produce
the combined work), being distributed under the terms of the GPL plus this
exception.  An independent module is a module which is not derived from or
based on Rosetta, and which is fully useable when not linked to Rosetta in
any form.

Any versions of Rosetta that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits.
Rosetta is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of
suggesting improvements to the standard version.

=cut
