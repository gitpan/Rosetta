=head1 NAME

Rosetta::Validator::L::en - Localization of Rosetta::Validator for English

=cut

######################################################################

package Rosetta::Validator::L::en;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.06';

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: I<This module has no enforced dependencies, but it is
designed to be used by Locale::KeyedText when that module localizes error
messages generated by Rosetta::Validator module.>

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

my $CV = 'Rosetta::Validator';
my $FAIL = 'Rosetta::Validator Test Failure';

my %text_strings = (
	'ROSVAL_SET_ENG_NO_ARG' => 
		"$CV.set_engine_name(): missing ENGINE_NAME argument",

	'ROSVAL_GET_ECO_NO_ARG' => 
		"$CV.get_engine_config_option(): missing ECO_NAME argument",

	'ROSVAL_CLEAR_ECO_NO_ARG' => 
		"$CV.clear_engine_config_option(): missing ECO_NAME argument",

	'ROSVAL_SET_ECO_NO_NAME' => 
		"$CV.set_engine_config_option(): missing ECO_NAME argument",
	'ROSVAL_SET_ECO_NO_VALUE' => 
		"$CV.set_engine_config_option(): missing ECO_VALUE argument",

	'ROSVAL_SET_ECOS_NO_ARGS' => 
		"$CV.set_engine_config_options(): missing EC_OPTS argument",
	'ROSVAL_SET_ECOS_BAD_ARGS' => 
		"$CV.set_engine_config_options(): invalid EC_OPTS argument; ".
		"it is not a hash ref, but rather is '{ARG}'",

	'ROSVAL_PER_TESTS_NO_ENG_NM' => 
		"$CV.perform_tests(): you can not invoke this method until ".
		"after you provide an Engine name to Validator.set_engine_name()",

	'ROSVAL_DESC_LOAD' => 
		"compiles and declares the Engine class",

	'ROSVAL_DESC_CATALOG_LIST' => 
		"gather a list of auto-detectable database instances",

	'ROSVAL_DESC_CATALOG_INFO' => 
		"gather more details on a specific database instance",

	'ROSVAL_DESC_CONN_BASIC' => 
		"open and close a connection to a specific database instance",

	'ROSVAL_DESC_TRAN_BASIC' => 
		"full basic support for transactions",

	'ROSVAL_FAIL_MISC_STR' => 
		"$FAIL: Miscellaneous Error: {VALUE}",
	'ROSVAL_FAIL_MISC_OBJ' => 
		"$FAIL: Miscellaneous Error",
);

######################################################################

sub get_text_by_key {
	return( $text_strings{$_[1]} );
}

######################################################################

1;
__END__

=head1 SYNOPSIS

	use Locale::KeyedText;
	use Rosetta::Validator;

	# do work ...

	my $translator = Locale::KeyedText->new_translator( ['Rosetta::Validator::L::', 
		'Rosetta::L::', 'SQL::Routine::L::'], ['en'] );

	# do work ...

	eval {
		# do work with Rosetta::Validator, which may throw an exception ...
	};
	if( my $error_message_object = $@ ) {
		# examine object here if you want and programmatically recover...

		# or otherwise do the next few lines...
		my $error_user_text = $translator->translate_message( $error_message_object );
		# display $error_user_text to user by some appropriate means
	}

	# continue working, which may involve using Rosetta::Validator some more ...

=head1 DESCRIPTION

The Rosetta::Validator::L::en Perl 5 module contains localization data for the
Rosetta::Validator module.  It is designed to be interpreted by
Locale::KeyedText.

This class is optional and you can still use Rosetta::Validator effectively
without it, especially if you plan to either show users different error
messages than this class defines, or not show them anything because you are
"handling it".

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>.  

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

	my $user_text_template = Rosetta::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the associated
user text template string, if there is one, or undef if not.

=head1 SEE ALSO

perl(1), Locale::KeyedText, Rosetta::Validator.

=cut
