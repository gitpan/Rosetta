=head1 NAME

Rosetta::Validator - A common comprehensive test suite to run against all Engines

=cut

######################################################################

package Rosetta::Validator;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.03';

use Locale::KeyedText 0.06;
use SQL::SyntaxModel 0.38;
use Rosetta 0.33;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Locale::KeyedText 0.06 (for error messages)
	SQL::SyntaxModel 0.38
	Rosetta 0.33

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
my $PROP_ENGINE_NAME = 'engine_name'; # Name of the Rosetta Engine module to test.
# These are just used internally for holding state:
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
my $TRS_PASS = 'PASS'; # the test was run and passed (Engine said it had feature to be tested)
my $TRS_FAIL = 'FAIL'; # the test was run and failed (Engine said it had feature to be tested)
my $TRS_SKIP = 'SKIP'; # the test was not run at all (Engine said it lacked feature to be tested)

# Other constant values go here:
my $TOTAL_POSSIBLE_TESTS = 1; # how many elements should be in results array (P+F+S) 

######################################################################

sub new {
	my ($class) = @_;
	my $validator = bless( {}, ref($class) || $class );

	$validator->{$PROP_ENGINE_NAME} = undef;
	$validator->{$PROP_TEST_RESULTS} = [];

	return( $validator );
}

######################################################################

sub engine_name {
	my ($validator, $new_value) = @_;
	if( defined( $new_value ) ) {
		$validator->{$PROP_ENGINE_NAME} = $new_value;
	}
	return( $validator->{$PROP_ENGINE_NAME} );
}

######################################################################


######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

	use strict; use warnings;
	use Rosetta::Validator;

	my $validator = Rosetta::Validator->new();
	$validator->engine_name->( 'Rosetta::Engine::Generic' );

	...

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
object's life and aren't changed later, since they are generally static
configuration data.

=head2 engine_name([ NEW_VALUE ])

	my $old_val = $validator->engine_name();
	$validator->engine_name( 'Rosetta::Engine::Generic' );

This getter/setter method returns this object's "engine name" character string
property; if the optional NEW_VALUE argument is defined, this property is first
set to that value.  This property defines the name of the Rosetta Engine module 
that you want this Validator object to test.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

perl(1), Rosetta, SQL::SyntaxModel, Locale::KeyedText, Rosetta::Engine::Generic.

=cut
