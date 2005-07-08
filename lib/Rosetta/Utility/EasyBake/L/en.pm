#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Utility::EasyBake::L::en;
our $VERSION = '0.01';

######################################################################

=encoding utf8

=head1 NAME

Rosetta::Utility::EasyBake::L::en - Localization of Rosetta::Utility::EasyBake for English

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: I<This module has no enforced dependencies, but it is
designed to be used by Locale::KeyedText when that module localizes error
messages generated by Rosetta::Utility::EasyBake.>

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

my %text_strings = (
	'ROS_UEB_V_CONN_SETUP_OPTS_NO_ARG' =>
		'{CLASS}.validate_connection_setup_options(): missing SETUP_OPTIONS argument',
	'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG' =>
		'{CLASS}.validate_connection_setup_options(): invalid SETUP_OPTIONS argument; '.
		'it must be a hash ref, but you tried to set it to "{ARG}"',
	'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG_NTYPE' => 
		'{CLASS}.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; '.
		'the settable Node types are "{ALLOWED}"; you gave "{GIVEN}"',
	'ROS_UEB_V_CONN_SETUP_OPTS_NO_ARG_ELEM' =>
		'{CLASS}.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; the value '.
		'with the "{NTYPE}" Node type key is missing',
	'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG_ELEM' =>
		'{CLASS}.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; the value '.
		'with the "{NTYPE}" Node type key must be a hash ref, but you tried to set it to "{ARG}"',
	'ROS_UEB_V_CONN_SETUP_OPTS_BAD_ARG_OPTNM' => 
		'{CLASS}.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; '.
		'the settable options for "{NTYPE}" Nodes are "{ALLOWED}"; you gave "{GIVEN}"',
	'ROS_UEB_V_CONN_SETUP_OPTS_NO_ENG_NM' => 
		'{CLASS}.validate_connection_setup_options(): missing SETUP_OPTIONS argument element; '.
		'you must provide a "data_link_product"."product_code", which is a Rosetta Engine class name',
);

######################################################################

sub get_text_by_key {
	my (undef, $msg_key) = @_;
	return $text_strings{$msg_key};
}

######################################################################

1;
__END__

=head1 SYNOPSIS

	use Locale::KeyedText;
	use Rosetta::Utility::EasyBake;

	# do work ...

	my $translator = Locale::KeyedText->new_translator( ['Rosetta::Utility::EasyBake::L::', 
		'Rosetta::L::', 'SQL::Routine::L::'], ['en'] );

	# do work ...

	eval {
		# do work with Rosetta::Utility::EasyBake, which may throw an exception ...
	};
	if( my $error_message_object = $@ ) {
		# examine object here if you want and programmatically recover...

		# or otherwise do the next few lines...
		my $error_user_text = $translator->translate_message( $error_message_object );
		# display $error_user_text to user by some appropriate means
	}

	# continue working, which may involve using Rosetta::Utility::EasyBake some more ...

=head1 DESCRIPTION

The Rosetta::Utility::EasyBake::L::en Perl 5 module contains localization data
for the Rosetta::Utility::EasyBake module.  It is designed to be interpreted by
Locale::KeyedText.

This class is optional and you can still use Rosetta::Utility::EasyBake
effectively without it, especially if you plan to either show users different
error messages than this class defines, or not show them anything because you
are "handling it".

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>.  

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

	my $user_text_template = Rosetta::Utility::EasyBake::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the associated
user text template string, if there is one, or undef if not.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta::Utility::EasyBake>.

=cut
