#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Validator::L::en;
use version; our $VERSION = qv('0.15.0');

######################################################################

my $CV = 'Rosetta::Validator';
my $FAIL = 'Rosetta::Validator Test Failure';

my %text_strings = (
    'ROS_VAL_V_CONN_SETUP_OPTS_NO_ARG' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[missing SETUP_OPTIONS argument],
    'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[invalid SETUP_OPTIONS argument; ]
        . q[it must be a hash ref, but you tried to set it to "{ARG}"],
    'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG_NTYPE' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[invalid SETUP_OPTIONS argument element; ]
        . q[the settable Node types are "{ALLOWED}"; you gave "{GIVEN}"],
    'ROS_VAL_V_CONN_SETUP_OPTS_NO_ARG_ELEM' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[invalid SETUP_OPTIONS argument element; the value ]
        . q[with the "{NTYPE}" Node type key is missing],
    'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG_ELEM' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[invalid SETUP_OPTIONS argument element; the value ]
        . q[with the "{NTYPE}" Node type key must be a hash ref, but you tried to set it to "{ARG}"],
    'ROS_VAL_V_CONN_SETUP_OPTS_BAD_ARG_OPTNM' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[invalid SETUP_OPTIONS argument element; ]
        . q[the settable options for "{NTYPE}" Nodes are "{ALLOWED}"; you gave "{GIVEN}"],
    'ROS_VAL_V_CONN_SETUP_OPTS_NO_ENG_NM' =>
        $CV . q[.validate_connection_setup_options(): ]
        . q[missing SETUP_OPTIONS argument element; ]
        . q[you must provide a "data_link_product"."product_code", which is a Rosetta Engine class name],

    'ROS_VAL_V_MAIN_ARG_TRACE_NO_FH' =>
        $CV . q[.main(): ]
        . q[invalid TRACE_FH argument; ]
        . q[it is not an open file handle, but rather is "{ARGVL}"],

    'ROS_VAL_DESC_LOAD' =>
        q[compiles and declares the Engine class],

    'ROS_VAL_DESC_CATALOG_LIST' =>
        q[gather a list of auto-detectable database instances],

    'ROS_VAL_DESC_CATALOG_INFO' =>
        q[gather more details on a specific database instance],

    'ROS_VAL_DESC_CONN_BASIC' =>
        q[open and close a connection to a specific database instance],

    'ROS_VAL_DESC_TRAN_BASIC' =>
        q[full basic support for transactions],

    'ROS_VAL_FAIL_MISC_STR' =>
        $FAIL . q[: Miscellaneous Error: {VALUE}],
    'ROS_VAL_FAIL_MISC_OBJ' =>
        $FAIL . q[: Miscellaneous Error],
);

######################################################################

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    return $text_strings{$msg_key};
}

######################################################################

1;
__END__

=encoding utf8

=head1 NAME

Rosetta::Validator::L::en - Localization of Rosetta::Validator for English

=head1 VERSION

This document describes Rosetta::Validator::L::en version 0.15.0.

=head1 SYNOPSIS

    use Locale::KeyedText;
    use Rosetta::Validator;

    # do work ...

    my $translator = Locale::KeyedText->new_translator(
        ['Rosetta::Validator::L::', 'Rosetta::L::', 'Rosetta::Model::L::'], ['en'] );

    # do work ...

    eval {
        # do work with Rosetta::Validator, which may throw an exception ...
    };
    if (my $error_message_object = $@) {
        # examine object here if you want and programmatically recover...

        # or otherwise do the next few lines...
        my $error_user_text = $translator->translate_message( $error_message_object );
        # display $error_user_text to user by some appropriate means
    }

    # continue working, which may involve using Rosetta::Validator some more ...

=head1 DESCRIPTION

The Rosetta::Validator::L::en Perl 5 module contains localization data for
the Rosetta::Validator module.  It is designed to be interpreted by
Locale::KeyedText.

This class is optional and you can still use Rosetta::Validator effectively
without it, especially if you plan to either show users different error
messages than this class defines, or not show them anything because you are
"handling it".

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

    my $user_text_template = Rosetta::Validator::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the
associated user text template string, if there is one, or undef if not.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl module L<version>, which would conceptually be
built-in to Perl, but isn't, so it is on CPAN instead.

This module has no enforced dependencies on L<Locale::KeyedText>, which is
on CPAN, or on L<Rosetta::Validator>, which is in the current distribution,
but it is designed to be used in conjunction with them.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta::Validator>.

=head1 BUGS AND LIMITATIONS

The structure of this module is trivially simple and has no known bugs.

However, the locale data that this module contains may be subject to large
changes in the future; you can determine the likeliness of this by
examining the development status and/or BUGS AND LIMITATIONS documentation
of the other module that this one is localizing; there tends to be a high
correlation in the rate of change between that module and this one.

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
