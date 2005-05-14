#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::L::en;
our $VERSION = '0.17';

######################################################################

=encoding utf8

=head1 NAME

Rosetta::L::en - Localization of Rosetta for English

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: I<This module has no enforced dependencies, but it is
designed to be used by Locale::KeyedText when that module localizes error
messages generated by Rosetta.>

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

my $CI = 'Rosetta::Interface';
my $CE = 'Rosetta::Engine';
my $CD = 'Rosetta::Dispatcher';
my $GEN = 'Rosetta Generic Engine Error';

my %text_strings = (
	'ROS_I_NEW_INTF_NO_TYPE' => 
		$CI.'.new(): missing INTF_TYPE argument',
	'ROS_I_NEW_INTF_BAD_TYPE' => 
		$CI.'.new(): invalid INTF_TYPE argument; there is no Interface Type named "{TYPE}"',
	'ROS_I_NEW_INTF_BAD_ERR' => 
		$CI.'.new(): invalid ERR_MSG argument; an Error Message may only be a '.
		'Locale::KeyedText::Message object; you tried to set it to "{ERR}"',
	'ROS_I_NEW_INTF_NO_ERR' => 
		$CI.'.new(): missing ERR_MSG argument; it is mandatory for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_YES_ENG' => 
		$CI.'.new(): the ENGINE argument must be undefined for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_NO_ENG' => 
		$CI.'.new(): missing ENGINE argument; it is mandatory for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_BAD_ENG' => 
		$CI.'.new(): invalid ENGINE argument; an Engine may only be a '.
		'Rosetta::Engine (subclass) object; you tried to set it to "{ENG}"',
	'ROS_I_NEW_INTF_NO_RTN' => 
		$CI.'.new(): missing ROUTINE argument; it is mandatory for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_BAD_RTN' => 
		$CI.'.new(): invalid ROUTINE argument; a Routine may only be a '.
		'Perl anonymous subroutine / "CODE" reference (or closure); you tried to set it to "{RTN}"',
	'ROS_I_NEW_INTF_YES_RTN' => 
		$CI.'.new(): the ROUTINE argument must be undefined for "{TYPE}" Interfaces',

	'ROS_I_NEW_INTF_YES_PARENT' => 
		$CI.'.new(): the PARENT_INTF argument must be undefined for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_NO_PARENT' => 
		$CI.'.new(): missing PARENT_INTF argument; it is mandatory for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_BAD_PARENT' => 
		$CI.'.new(): invalid PARENT_INTF argument; a Parent Interface may only be a '.
		'Rosetta::Interface object; you tried to set it to "{PAR}"',
	'ROS_I_NEW_INTF_P_INCOMP' =>
		$CI.'.new(): invalid PARENT_INTF argument; a "{TYPE}" Interface may not have a '.
		'"{PTYPE}" Interface as its parent',
	'ROS_I_NEW_INTF_PP_INCOMP' =>
		$CI.'.new(): invalid PARENT_INTF argument; a "{TYPE}" Interface may not have a '.
		'"{PPTYPE}" Interface as its grand-parent (but its "{PTYPE}" parent type is okay)',

	'ROS_I_NEW_INTF_YES_NODE' => 
		$CI.'.new(): the SRT_NODE argument must be undefined for "{TYPE}" Interfaces; '.
		'this Interface property would be set for you by using its parent Preparation',
	'ROS_I_NEW_INTF_NO_NODE' => 
		$CI.'.new(): missing SRT_NODE argument; it is mandatory for "{TYPE}" Interfaces',
	'ROS_I_NEW_INTF_BAD_NODE' => 
		$CI.'.new(): invalid SRT_NODE argument; it may only be a '.
		'SQL::Routine::Node object; you tried to set it to "{SRT}"',
	'ROS_I_NEW_INTF_NODE_NOT_SAME_CONT' =>
		$CI.'.new(): invalid SRT_NODE argument; that Node is not in the same Container '.
		'as the Node associated with PARENT_INTF, so it can not be used',
	'ROS_I_NEW_INTF_NODE_TYPE_NOT_SUPP' =>
		$CI.'.new(): the given SRT_NODE argument, having a Node Type of "{NTYPE}", '.
		'can not be associated with a "{ITYPE}" Interface',
	'ROS_I_NEW_INTF_NODE_TYPE_NOT_SUPP_UNDER_P' =>
		$CI.'.new(): the given SRT_NODE argument, having a Node Type of "{NTYPE}", '.
		'can not be associated with a "{ITYPE}" Interface, when that Interface has '.
		'a "{PITYPE}" Interface as its direct parent',

	'ROS_I_DESTROY_HAS_CHILD' => 
		$CI.'.destroy(): this Interface has child Interfaces of its '.
		'own, so it can not be destroyed yet',

	'ROS_I_FEATURES_BAD_ARG' =>
		$CI.'.features(): invalid FEATURE_NAME argument; '.
		'"{ARG}" does not match any known Rosetta Feature Name',
	'ROS_I_FEATURES_BAD_RESULT_SCALAR' =>
		$CI.'.features(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return a valid boolean value, as expressed by "0" or "1", '.
		'for the scalar query; it is instead: "{VALUE}"',
	'ROS_I_FEATURES_BAD_RESULT_LIST' =>
		$CI.'.features(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return a valid Hash ref for the list query, but rather: "{VALUE}"',
	'ROS_I_FEATURES_BAD_RESULT_ITEM_NAME' =>
		$CI.'.features(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'returned a list key that does not match any known Rosetta Feature Name: "{FNAME}"',
	'ROS_I_FEATURES_BAD_RESULT_ITEM_NO_VAL' =>
		$CI.'.features(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return a valid boolean value, as expressed by "0" or "1", '.
		'for the "{FNAME}" feature name in this list query; it is instead undefined',
	'ROS_I_FEATURES_BAD_RESULT_ITEM_BAD_VAL' =>
		$CI.'.features(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return a valid boolean value, as expressed by "0" or "1", '.
		'for the "{FNAME}" feature name in this list query; it is instead: "{VALUE}"',

	'ROS_I_PREPARE_BAD_RESULT_NO_INTF' =>
		$CI.'.prepare(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return a Rosetta::Interface object, but rather: "{VALUE}"',
	'ROS_I_PREPARE_BAD_RESULT_WRONG_ITREE' =>
		$CI.'.prepare(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'returned a Rosetta::Interface object that is in a different Interface tree '.
		'than the Interface upon which this method was invoked',
	'ROS_I_PREPARE_BAD_RESULT_WRONG_ITYPE' =>
		$CI.'.prepare(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return the correct type of Rosetta::Interface object (Prep, Err); '.
		'it instead returned a "{RET_ITYPE}" Interface',

	'ROS_I_PREPARE_NO_NODE' => 
		$CI.'.prepare(): missing ROUTINE_DEFN argument; it is mandatory for "{TYPE}" Interfaces',
	'ROS_I_PREPARE_BAD_NODE' => 
		$CI.'.prepare(): invalid ROUTINE_DEFN argument; it may only be a '.
		'SQL::Routine::Node object; you tried to set it to "{SRT}"',
	'ROS_I_PREPARE_NODE_NOT_SAME_CONT' =>
		$CI.'.prepare(): invalid ROUTINE_DEFN argument; that Node is not in the same Container '.
		'as the Node associated with PARENT_INTF, so it can not be used',
	'ROS_I_PREPARE_NODE_TYPE_NOT_SUPP' =>
		$CI.'.prepare(): the given ROUTINE_DEFN argument, having a Node Type of "{NTYPE}", '.
		'can not be associated with a "{ITYPE}" Interface',
	'ROS_I_PREPARE_NODE_TYPE_NOT_SUPP_UNDER_P' =>
		$CI.'.prepare(): the given SRT_NODE argument, having a Node Type of "{NTYPE}", '.
		'can not be associated with a "{ITYPE}" Interface, when that Interface has '.
		'a "{PITYPE}" Interface as its direct parent',

	'ROS_I_PREPARE_ENGINE_NO_LOAD' =>
		$CI.'.prepare(): the Engine class "{CLASS}" failed to load: {ERR}',
	'ROS_I_PREPARE_ENGINE_NO_ENGINE' =>
		$CI.'.prepare(): the class "{CLASS}" does not sub-class Rosetta::Engine so it is not a valid Engine class',
	'ROS_I_PREPARE_ENGINE_YES_DISPATCHER' =>
		$CI.'.prepare(): the class "{CLASS}" sub-classes Rosetta::Dispatcher so it is not a valid Engine class',

	'ROS_I_EXECUTE_BAD_ARG' =>
		$CI.'.execute(): invalid ROUTINE_ARGS argument; it must be a hash ref if '.
		'it is defined, but you tried to set it to "{ARG}"',
	'ROS_I_EXECUTE_BAD_RESULT_NO_INTF' =>
		$CI.'.execute(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return a Rosetta::Interface object, but rather: "{VALUE}"',
	'ROS_I_EXECUTE_BAD_RESULT_WRONG_ITREE' =>
		$CI.'.execute(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'returned a Rosetta::Interface object that is in a different Interface tree '.
		'than the Interface upon which this method was invoked',
	'ROS_I_EXECUTE_BAD_RESULT_WRONG_ITYPE' =>
		$CI.'.execute(): the "{CLASS}" Rosetta Engine that implements this "{ITYPE}" Interface '.
		'did not return the correct type of Rosetta::Interface object '.
		'(Err, Succ, Lit, Env, Conn, Curs); it instead returned a "{RET_ITYPE}" Interface',

	'ROS_I_BUILD_CH_ENV_NO_ARG' =>
		$CI.'.build_child_environment(): missing ENGINE_NAME argument',

	'ROS_I_V_CONN_SETUP_OPTS_NO_ARG' =>
		$CI.'.validate_connection_setup_options(): missing SETUP_OPTIONS argument',
	'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG' =>
		$CI.'.validate_connection_setup_options(): invalid SETUP_OPTIONS argument; '.
		'it must be a hash ref, but you tried to set it to "{ARG}"',
	'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG_NTYPE' => 
		$CI.'.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; '.
		'the settable Node types are "{ALLOWED}"; you gave "{GIVEN}"',
	'ROS_I_V_CONN_SETUP_OPTS_NO_ARG_ELEM' =>
		$CI.'.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; the value '.
		'with the "{NTYPE}" Node type key is missing',
	'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG_ELEM' =>
		$CI.'.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; the value '.
		'with the "{NTYPE}" Node type key must be a hash ref, but you tried to set it to "{ARG}"',
	'ROS_I_V_CONN_SETUP_OPTS_BAD_ARG_OPTNM' => 
		$CI.'.validate_connection_setup_options(): invalid SETUP_OPTIONS argument element; '.
		'the settable options for "{NTYPE}" Nodes are "{ALLOWED}"; you gave "{GIVEN}"',
	'ROS_I_V_CONN_SETUP_OPTS_NO_ENG_NM' => 
		$CI.'.validate_connection_setup_options(): missing SETUP_OPTIONS argument element; '.
		'you must provide a "data_link_product"."product_code", which is a Rosetta Engine class name',

	'ROS_I_METH_NOT_SUPP' =>
		$CI.'.{METH}(): you may not invoke this method on Rosetta "{ITYPE}" Interfaces',
	'ROS_I_METH_MISC_EXCEPTION' =>
		$CI.'.{METH}(): the {CLASS} Rosetta Engine that implements this "{ITYPE}" Interface '.
		'has thrown a non-Locale::KeyedText::Message exception: "{VALUE}"',

	'ROS_E_METH_NOT_IMPL' =>
		$CE.'.{METH}(): this method is not implemented by the "{CLASS}" Rosetta Engine class',

	'ROS_D_PREPARE_NO_ENGINE_DETERMINED' =>
		$CD.'.prepare(): can"t determine what Rosetta Engine to dispatch this App invocation to',

	'ROS_G_PERL_COMPILE_FAIL' =>
		$GEN.' 00001 - {CLASS} - concerning the SRT routine "{RNAME}"; '.
		'can"t compile a generated Perl routine ({PERL_ERROR}): \n{PERL_CODE}',
	'ROS_G_RTN_TP_NO_INVOK' =>
		$GEN.' 00002 - {CLASS} - concerning the SRT routine "{RNAME}"; '.
		'can"t directly invoke a "{RTYPE}" routine (only FUNCTION and PROCEDURE calls are allowed)',
	'ROS_G_NEST_RTN_NO_INVOK' =>
		$GEN.' 00003 - {CLASS} - concerning the SRT routine "{RNAME}"; '.
		'can"t externally invoke a nested routine (a routine that is declared inside another routine)',
	'ROS_G_STD_RTN_NO_IMPL' =>
		$GEN.' 00004 - {CLASS} - concerning the SRT routine "{RNAME}"; '.
		'can"t invoke the standard routine "{SRNAME}"; it isn"t implemented',
	'ROS_G_CATALOG_OPEN_CONN_STATE_OPEN' =>
		$GEN.' 00005 - {CLASS} - concerning the SRT routine "{RNAME}"; '.
		'failure in standard routine "CATALOG_OPEN"; the given CONN_CX is already open',
	'ROS_G_CATALOG_CLOSE_CONN_STATE_CLOSED' =>
		$GEN.' 00006 - {CLASS} - concerning the SRT routine "{RNAME}"; '.
		'failure in standard routine "CATALOG_CLOSE"; the given CONN_CX is already closed',
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
	use Rosetta;

	# do work ...

	my $translator = Locale::KeyedText->new_translator( 
		['Rosetta::L::', 'SQL::Routine::L::'], ['en'] );

	# do work ...

	eval {
		# do work with Rosetta, which may throw an exception ...
	};
	if( my $error_message_object = $@ ) {
		# examine object here if you want and programmatically recover...

		# or otherwise do the next few lines...
		my $error_user_text = $translator->translate_message( $error_message_object );
		# display $error_user_text to user by some appropriate means
	}

	# continue working, which may involve using Rosetta some more ...

=head1 DESCRIPTION

The Rosetta::L::en Perl 5 module contains localization data for Rosetta.  It is
designed to be interpreted by Locale::KeyedText.  Besides localizing generic
error messages that Rosetta produces itself, this file also provides a
ready-made set of generic database error strings that can be thrown by any
Rosetta Engine.

This class is optional and you can still use Rosetta effectively without it,
especially if you plan to either show users different error messages than this
class defines, or not show them anything because you are "handling it".

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

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta>.

=cut
