#!perl

use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Validator;
our $VERSION = '0.41';

use Rosetta '0.41';

######################################################################

=encoding utf8

=head1 NAME

Rosetta::Validator - A common comprehensive test suite to run against all Engines

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: 

	Rosetta 0.41

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

######################################################################

sub total_possible_tests {
	return $TOTAL_POSSIBLE_TESTS;
}

######################################################################

sub main {
	my ($class, $setup_options, $trace_fh) = @_;
	my $validator = bless( {}, ref($class) || $class );

	Rosetta->validate_connection_setup_options( $setup_options ); # dies on problem

	$validator->{$PROP_TRACE_FH} = $trace_fh; # may be undef
	$validator->{$PROP_SETUP_OPTS} = $setup_options;
	$validator->{$PROP_TEST_RESULTS} = [];
	$validator->{$PROP_ENG_ENV_FEAT} = {};

	$validator->main_dispatch(); # any errors generated here go in TEST_RESULTS, presumably

	return $validator->{$PROP_TEST_RESULTS}; # by ref not a problem, orig ref is now gone
}

######################################################################

sub new_result {
	my ($validator, $feature_key) = @_;
	my $result = {
		$TR_FEATURE_KEY => $feature_key,
		$TR_FEATURE_STATUS => $TRS_SKIP,
		$TR_FEATURE_DESC_MSG => Locale::KeyedText->new_message( 'ROSVAL_DESC_'.$feature_key ),
	};
	push( @{$validator->{$PROP_TEST_RESULTS}}, $result );
	return $result;
}

sub pass_result {
	my ($validator, $result) = @_;
	$result->{$TR_FEATURE_STATUS} = $TRS_PASS;
}

sub fail_result {
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

sub misc_result {
	my ($validator, $result, $exception) = @_;
	if( $exception ) {
		if( ref($exception) ) {
			$validator->fail_result( $result, 'ROSVAL_FAIL_MISC_OBJ', undef, $exception );
		} else {
			$validator->fail_result( $result, 'ROSVAL_FAIL_MISC_STR', { 'VALUE' => $exception } );
		}
	} else {
		$validator->pass_result( $result );
	}
}

######################################################################

sub setup_app {
	my ($validator) = @_;
	my $app_intf = Rosetta->build_application();
	$app_intf->set_trace_fh( $validator->{$PROP_TRACE_FH} );
	my $container = $app_intf->get_srt_container();
	$container->auto_assert_deferrable_constraints( 1 );
	$container->auto_set_node_ids( 1 );
	return $app_intf;
}

sub setup_env {
	my ($validator) = @_;
	my $app_intf = $validator->setup_app();
	my $env_intf = eval {
		my $engine_name = $validator->{$PROP_SETUP_OPTS}->{'data_link_product'}->{'product_code'};
		return $app_intf->build_child_environment( $engine_name );
	};
	if( my $exception = $@ ) {
		$app_intf->destroy_interface_tree_and_srt_container(); # avoid memory leaks
		die $exception;
	}
	return $env_intf;
}

sub setup_conn {
	my ($validator, $rt_si_name) = @_;
	my $app_intf = $validator->setup_app();
	my $conn_intf = eval {
		return $app_intf->build_child_connection( 
			$validator->{$PROP_SETUP_OPTS}, $rt_si_name );
	};
	if( my $exception = $@ ) {
		$app_intf->destroy_interface_tree_and_srt_container(); # avoid memory leaks
		die $exception;
	}
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
		$env_intf->destroy_interface_tree_and_srt_container();
		$validator->misc_result( $result, $@ ); $@ and last SWITCH;

		my $conn_intf = eval {
			return $validator->setup_conn( 'declare_db_conn' );
		};
		$validator->misc_result( $result, $@ ); $@ and last SWITCH;

		$validator->{$PROP_ENG_CONN_FEAT} = eval {
			return $conn_intf->features();
		};
		$conn_intf->destroy_interface_tree_and_srt_container();

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
			my $prep_intf = $env_intf->sroutine_catalog_list( 'catalog_list' );
			my $lit_intf = $prep_intf->execute();
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

	$env_intf->destroy_interface_tree_and_srt_container();
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

	SWITCH: {
		eval {
			my $prep_intf = $conn_intf->sroutine_catalog_open( 'open_db_conn' );
			$prep_intf->execute();
		};
		$validator->misc_result( $result, $@ ); $@ and last SWITCH;

		eval {
			my $prep_intf = $conn_intf->sroutine_catalog_close( 'close_db_conn' );
			$prep_intf->execute();
		};
		$validator->misc_result( $result, $@ ); $@ and last SWITCH;
	}

	$conn_intf->destroy_interface_tree_and_srt_container();
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

=head1 SYNOPSIS

I<The previous SYNOPSIS was removed; a new one will be written later.>

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

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS

You invoke all of these functions off of the class name.  No Rosetta::Validator 
objects are ever returned, so you can not invoke methods off of them.

=head2 total_possible_tests()

This method returns an integer that says how many elements are supposed to be
in the "test results" array returned by main(); it should be equal to the
number of skips + passes + fails.  You can use this number at the start of your
test script when declaring the 1..N total number of tests that will be
considered, and you can compare that to the actual results.

=head2 main( SETUP_OPTIONS[, TRACE_FH] )

This function comprises the core of the Rosetta::Validator module, and is what
actually performs the tests on the Rosetta Engines.  This method will
instantiate a new Rosetta Interface tree, and a SQL::Routine Container,
populate the latter, invoke the former, saying to use the Engine and related
configuration settings in SETUP_OPTIONS, try all sorts of database actions, and
record the results in the "test results" property, and then destroy the Rosetta
and SQL::Routine objects.  The two function arguments, SETUP_OPTIONS (a hash
ref), and TRACE_FH (an open file handle, optional), are input to these Rosetta
functions for use and validation, respectively: build_connection(),
set_trace_fh(); either may throw an exception which propagates out of main(). 
This function returns a new array ref having the details of the test results.

=head1 INTERPRETING THE TEST RESULTS

Each element of the test results array that main() returns is a hash ref
containing these 5 elements:  1. 'FEATURE_KEY'.  2. 'FEATURE_STATUS'; one of
'SKIP' (test was not run at all), 'PASS' (test was run and passed), 'FAIL'
(test was run and failed); for the first one, the Engine said it did not have
support for the feature, and for the last two, it said that it did.  3.
'FEATURE_DESC_MSG'; a Locale::KeyedText::Message (LKT) object that is the
Validator module's description of what DBMS/Engine feature is being tested.  4.
'VAL_ERROR_MSG'; a LKT object that is set when 'FEATURE_STATUS' is 'FAIL'; this
is the Validator module's own Error Message, if a test failed; this is made for
a failure regardless of whether the Engine threw its own exception.  5.
'ENG_ERROR_MSG'; a LKT object that is the Error Message that the Rosetta
Interface or Engine threw, if any.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

L<perl(1)>, L<Rosetta>, L<SQL::Routine>, L<Locale::KeyedText>, L<Rosetta::Engine::Generic>.

=cut
