=head1 NAME

Rosetta::L::en - Localization of Rosetta for English

=cut

######################################################################

package Rosetta::L::en;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.03';

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: I<This module has no enforced dependencies, but it is
designed to be used by Locale::KeyedText when that module localizes error
messages generated by Rosetta.>

=head1 COPYRIGHT AND LICENSE

This file is part of the Rosetta database abstraction framework.

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

my %text_strings = (
	'ROS_I_NEW_INTF_NO_TYPE' => 
		"new(): missing INTF_TYPE argument",
	'ROS_I_NEW_INTF_BAD_TYPE' => 
		"new(): invalid INTF_TYPE argument; there is no Interface Type named '{TYPE}'",
	'ROS_I_NEW_INTF_BAD_ERR' => 
		"new(): invalid ERR_MSG argument; an Error Message may only be a ".
		"Locale::KeyedText::Message object; you tried to set it to '{ERR}'",
	'ROS_I_NEW_INTF_NO_ERR' => 
		"new(): missing ERR_MSG argument; it is mandatory for '{TYPE}' Interfaces",
	'ROS_I_NEW_INTF_YES_ENG' => 
		"new(): the ENGINE argument must be undefined for '{TYPE}' Interfaces",
	'ROS_I_NEW_INTF_NO_ENG' => 
		"new(): missing ENGINE argument; it is mandatory for '{TYPE}' Interfaces",
	'ROS_I_NEW_INTF_BAD_ENG' => 
		"new(): invalid ENGINE argument; an Engine may only be a ".
		"Rosetta::Engine (subclass) object; you tried to set it to '{ENG}'",

	'ROS_I_NEW_INTF_YES_PARENT' => 
		"new(): the PARENT_INTF argument must be undefined for '{TYPE}' Interfaces",
	'ROS_I_NEW_INTF_NO_PARENT' => 
		"new(): missing PARENT_INTF argument; it is mandatory for '{TYPE}' Interfaces",
	'ROS_I_NEW_INTF_BAD_PARENT' => 
		"new(): invalid PARENT_INTF argument; a Parent Interface may only be a ".
		"Rosetta::Interface object; you tried to set it to '{PAR}'",
	'ROS_I_NEW_INTF_P_INCOMP' =>
		"new(): invalid PARENT_INTF argument; a '{TYPE}' Interface may not have a ".
		"'{PTYPE}' Interface as its parent",
	'ROS_I_NEW_INTF_PP_INCOMP' =>
		"new(): invalid PARENT_INTF argument; a '{TYPE}' Interface may not have a ".
		"'{PPTYPE}' Interface as its grand-parent (but its '{PTYPE}' parent type is okay)",

	'ROS_I_NEW_INTF_YES_NODE' => 
		"new(): the SSM_NODE argument must be undefined for '{TYPE}' Interfaces; ".
		"this Interface property would be set for you by using its parent Preparation",
	'ROS_I_NEW_INTF_NO_NODE' => 
		"new(): missing SSM_NODE argument; it is mandatory for '{TYPE}' Interfaces",
	'ROS_I_NEW_INTF_BAD_NODE' => 
		"new(): invalid SSM_NODE argument; a Parent Interface may only be a ".
		"SQL::SyntaxModel::Node object; you tried to set it to '{SSM}'",
	'ROS_I_NEW_INTF_NODE_NOT_IN_CONT' =>
		"new(): invalid SSM_NODE argument; that Node is not in a Container",
	'ROS_I_NEW_INTF_NODE_NOT_SAME_CONT' =>
		"new(): invalid SSM_NODE argument; that Node is not in the same Container ".
		"as the Node associated with PARENT_INTF, so it can not be used",
	'ROS_I_NEW_INTF_NODE_TYPE_NOT_SUPP' =>
		"new(): the given SSM_NODE argument, having a Node Type of '{NTYPE}', ".
		"can not be associated with a '{ITYPE}' Interface",
	'ROS_I_NEW_INTF_NODE_CMD_TYPE_NOT_SUPP' =>
		"new(): the given SSM_NODE 'command' Node argument, having a command ".
		"type of '{CTYPE}', can not be associated with a '{ITYPE}' Interface",

	'ROS_I_DESTROY_HAS_CHILD' => 
		"destroy(): this Interface has child Interfaces of its ".
		"own, so it can not be destroyed yet",

	'ROS_I_THROW_ERR_BAD_ARG' => 
		"throw_errors(): invalid NEW_VALUE argument; this flag may only be a ".
		"boolean value, as expressed by '0' or '1'; you tried to set it to '{ARG}'",

	'ROS_I_PREPARE_MISC_EXCEPTION' =>
		"prepare(): the Rosetta Engine that implements this '{ITYPE}' Interface ".
		"has thrown a non-Locale::KeyedText::Message exception: '{VALUE}'",
	'ROS_I_PREPARE_BAD_RESULT' =>
		"prepare(): the Rosetta Engine that implements this '{ITYPE}' Interface ".
		"did not return a Rosetta::Interface object, but rather: '{VALUE}'",

	'ROS_I_EXECUTE_BAD_ARG' =>
		"execute(): invalid BIND_VARS argument; it must be a hash ref if ".
		"it is defined, but you tried to set it to '{ARG}'",
	'ROS_I_EXECUTE_MISC_EXCEPTION' =>
		"execute(): the Rosetta Engine that implements this '{ITYPE}' Interface ".
		"has thrown a non-Locale::KeyedText::Message exception: '{VALUE}'",
	'ROS_I_EXECUTE_BAD_RESULT' =>
		"execute(): the Rosetta Engine that implements this '{ITYPE}' Interface ".
		"did not return a Rosetta::Interface object, but rather: '{VALUE}'",

	'ROS_I_METH_NOT_SUPP' =>
		"{METH}(): you may not invoke this method on Rosetta '{TYPE}' Interfaces",

	'ROS_E_METH_NOT_IMPL' =>
		"{METH}(): this method is not implemented by the Rosetta '{CLASS}' Engine class",

	'ROS_G_ENGINE_NO_LOAD' =>
		"the Engine class '{NAME}' failed to load: {ERR}",
	'ROS_G_ENGINE_NO_ENGINE' =>
		"the class '{NAME}' does not sub-class Rosetta::Engine so it is not a valid Engine class",
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
	use Rosetta;

	# do work ...

	my $translator = Locale::KeyedText->new_translator( 
		['Rosetta::L::', 'SQL::SyntaxModel::L::'], ['en'] );

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
designed to be interpreted by Locale::KeyedText.

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

perl(1), Locale::KeyedText, Rosetta, SQL::SyntaxModel::L::*.

=cut
