#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::L::en;
use version; our $VERSION = qv('0.20.0');

######################################################################

my $GEN = 'Rosetta Generic Engine Error';

my %text_strings = (
    'ROS_CLASS_METH_ARG_UNDEF' =>
        q[{CLASS}.{METH}(): ]
        . q[undefined (or missing) {ARGNM} argument],
    'ROS_CLASS_METH_ARG_NO_ARY' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Array ref, but rather is "{ARGVL}"],
    'ROS_CLASS_METH_ARG_NO_HASH' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Hash ref, but rather is "{ARGVL}"],
    'ROS_CLASS_METH_ARG_NO_SUB' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Perl anonymous subroutine / "CODE" ref / closure, but rather is "{ARGVL}"],
    'ROS_CLASS_METH_ARG_NO_OBJ' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not an object, but rather is "{ARGVL}"],
    'ROS_CLASS_METH_ARG_NO_FH' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not an open file handle, but rather is "{ARGVL}"],
    'ROS_CLASS_METH_ARG_NO_NODE' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a Rosetta::Model Node object, but rather is "{ARGVL}"],

    'ROS_CLASS_METH_ARG_WRONG_OBJ_TYPE' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a "{EXPOTYPE}" object, but rather is a "{ARGOTYPE}" object],

    'ROS_CLASS_METH_ARG_WRONG_NODE_TYPE' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[it is not a "{EXPNTYPE}" Node, but rather is a "{ARGNTYPE}" Node],

    'ROS_CLASS_METH_ARG_NODE_NOT_SAME_CONT' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid {ARGNM} argument; ]
        . q[the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}" ]
        . q[is not in the Rosetta::Model Container used by this Rosetta Interface tree],

    'ROS_CLASS_METH_ENG_MISC_EXCEPTION' =>
        q[{CLASS}.{METH}(): ]
        . q[when trying to invoke the "{ENG_CLASS}" Rosetta Engine, ]
        . q[an exception was thrown that is neither a Rosetta::Interface::Error ]
        . q[nor a Locale::KeyedText::Message, but rather is "{ERR}"],

    'ROS_CLASS_METH_ENG_RESULT_UNDEF' =>
        q[{CLASS}.{METH}(): ]
        . q[undefined (or missing) return value ]
        . q[from the Rosetta Engine method {ENG_CLASS}.{METH}()],
    'ROS_CLASS_METH_ENG_RESULT_NO_OBJ' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid return value ]
        . q[from the Rosetta Engine method {ENG_CLASS}.{METH}(); ]
        . q[it is not an object, but rather is "{RESULTVL}"],

    'ROS_CLASS_METH_ENG_RESULT_WRONG_OBJ_TYPE' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid return value ]
        . q[from the Rosetta Engine method {ENG_CLASS}.{METH}(); ]
        . q[it is not a "{EXPOTYPE}" object, but rather is a "{RESULTOTYPE}" object],

    'ROS_CLASS_METH_ENG_RESULT_WRONG_ITREE' =>
        q[{CLASS}.{METH}(): ]
        . q[invalid return value ]
        . q[from the Rosetta Engine method {ENG_CLASS}.{METH}(); ]
        . q[that Rosetta Interface does not share a common Rosetta Interface tree ]
        . q[with the invocant Interface],

    'ROS_I_NEW_ARGS_DIFF_ITREES' =>
        q[{CLASS}.new(): ]
        . q[invalid PARENT_BYC[RE|XT]_INTF arguments; ]
        . q[they do not share a common Rosetta Interface tree, so no ]
        . q[new Interface can be made that has both of them as parents],

    'ROS_IN_NEW_ENGINE_NO_LOAD' =>
        q[{CLASS}.new(): ]
        . q[the Engine class "{ENG_CLASS}" failed to load: {ERR}],
    'ROS_IN_NEW_ENGINE_NO_ENGINE' =>
        q[{CLASS}.new(): ]
        . q[the class "{ENG_CLASS}" does not sub-class Rosetta::Engine so it is not a valid Engine class],

    'ROS_I_FEATURES_BAD_ARG' =>
        q[{CLASS}.features(): ]
        . q[invalid FEATURE_NAME argument; ]
        . q["{ARGVL}" does not match any known Rosetta Feature Name],
    'ROS_I_FEATURES_BAD_RESULT_SCALAR' =>
        q[{CLASS}.features(): ]
        . q[the "{ENG_CLASS}" Rosetta Engine ]
        . q[did not return a valid boolean value (or undef), as expressed by "0" or "1", ]
        . q[for the scalar query on the Rosetta feature named "{FNAME}"; it is instead: "{VALUE}"],
    'ROS_I_FEATURES_BAD_RESULT_LIST_UNDEF' =>
        q[{CLASS}.features(): ]
        . q[the "{ENG_CLASS}" Rosetta Engine ]
        . q[did not return a defined value for the list query, but rather: "{VALUE}"],
    'ROS_I_FEATURES_BAD_RESULT_LIST_NO_HASH' =>
        q[{CLASS}.features(): ]
        . q[the "{ENG_CLASS}" Rosetta Engine ]
        . q[did not return a valid Hash ref for the list query, but rather: "{VALUE}"],
    'ROS_I_FEATURES_BAD_RESULT_ITEM_NAME' =>
        q[{CLASS}.features(): ]
        . q[the "{ENG_CLASS}" Rosetta Engine ]
        . q[returned a list key that does not match any known Rosetta feature name: "{FNAME}"],
    'ROS_I_FEATURES_BAD_RESULT_ITEM_NO_VAL' =>
        q[{CLASS}.features(): ]
        . q[the "{ENG_CLASS}" Rosetta Engine ]
        . q[did not return a valid boolean value, as expressed by "0" or "1", ]
        . q[for the "{FNAME}" feature name in this list query; it is instead undefined],
    'ROS_I_FEATURES_BAD_RESULT_ITEM_BAD_VAL' =>
        q[{CLASS}.features(): ]
        . q[the "{ENG_CLASS}" Rosetta Engine ]
        . q[did not return a valid boolean value, as expressed by "0" or "1", ]
        . q[for the "{FNAME}" feature name in this list query; it is instead: "{VALUE}"],

    'ROS_E_METH_NOT_IMPL' =>
        q[Rosetta::Engine.{METH}(): ]
        . q[this method is not implemented by the "{CLASS}" Rosetta Engine class],

    'ROS_D_PREPARE_NO_ENGINE_DETERMINED' =>
        q[Rosetta::Dispatcher.prepare(): ]
        . q[can't determine what Rosetta Engine to dispatch this App invocation to],

    'ROS_G_PERL_COMPILE_FAIL' =>
        $GEN . q[ 00001 - {CLASS} - concerning the ROS M routine "{RNAME}"; ]
        . q[can"t compile a generated Perl routine ({PERL_ERROR}):\n{PERL_CODE}],
    'ROS_G_RTN_TP_NO_INVOK' =>
        $GEN . q[ 00002 - {CLASS} - concerning the ROS M routine "{RNAME}"; ]
        . q[can"t directly invoke a "{RTYPE}" routine (only FUNCTION and PROCEDURE calls are allowed)],
    'ROS_G_NEST_RTN_NO_INVOK' =>
        $GEN . q[ 00003 - {CLASS} - concerning the ROS M routine "{RNAME}"; ]
        . q[can"t externally invoke a nested routine (a routine that is declared inside ]
        . q[another routine) or a routine that lives in a schema],
    'ROS_G_STD_RTN_NO_IMPL' =>
        $GEN . q[ 00004 - {CLASS} - concerning the ROS M routine "{RNAME}"; ]
        . q[can"t invoke the standard routine "{SRNAME}"; it isn"t implemented],
    'ROS_G_CATALOG_OPEN_CONN_STATE_OPEN' =>
        $GEN . q[ 00005 - {CLASS} - concerning the ROS M routine "{RNAME}"; ]
        . q[failure in standard routine "CATALOG_OPEN"; the given CONN_CX is already open],
    'ROS_G_CATALOG_CLOSE_CONN_STATE_CLOSED' =>
        $GEN . q[ 00006 - {CLASS} - concerning the ROS M routine "{RNAME}"; ]
        . q[failure in standard routine "CATALOG_CLOSE"; the given CONN_CX is already closed],
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

Rosetta::L::en - Localization of Rosetta for English

=head1 VERSION

This document describes Rosetta::L::en version 0.20.0.

=head1 SYNOPSIS

    use Locale::KeyedText;
    use Rosetta;

    # do work ...

    my $translator = Locale::KeyedText->new_translator(
        ['Rosetta::L::', 'Rosetta::Model::L::'], ['en'] );

    # do work ...

    eval {
        # do work with Rosetta, which may throw an exception ...
    };
    if (my $error_message_object = $@) {
        # examine object here if you want and programmatically recover...

        # or otherwise do the next few lines...
        my $error_user_text = $translator->translate_message( $error_message_object );
        # display $error_user_text to user by some appropriate means
    }

    # continue working, which may involve using Rosetta some more ...

=head1 DESCRIPTION

The Rosetta::L::en Perl 5 module contains localization data for Rosetta.
It is designed to be interpreted by Locale::KeyedText.  Besides localizing
generic error messages that Rosetta produces itself, this file also
provides a ready-made set of generic database error strings that can be
thrown by any Rosetta Engine.

This class is optional and you can still use Rosetta effectively without
it, especially if you plan to either show users different error messages
than this class defines, or not show them anything because you are
"handling it".

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

    my $user_text_template = Rosetta::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the
associated user text template string, if there is one, or undef if not.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl module L<version>, which would conceptually be
built-in to Perl, but isn't, so it is on CPAN instead.

This module has no enforced dependencies on L<Locale::KeyedText>, which is
on CPAN, or on L<Rosetta>, which is in the current distribution, but it is
designed to be used in conjunction with them.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta>.

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
