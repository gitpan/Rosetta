=head1 NAME

SQL::SyntaxModel::ByTree::L::en - Localization of SQL::SyntaxModel::ByTree for English

=cut

######################################################################

package SQL::SyntaxModel::ByTree::L::en;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: I<This module has no enforced dependencies, but it is
designed to be used by Locale::KeyedText when that module localizes error
messages generated by SQL::SyntaxModel::ByTree.>

=head1 COPYRIGHT AND LICENSE

This file is part of the SQL::SyntaxModel library (libSQLSM).

SQL::SyntaxModel is Copyright (c) 1999-2004, Darren R. Duncan.  All rights
reserved.  Address comments, suggestions, and bug reports to
B<perl@DarrenDuncan.net>, or visit "http://www.DarrenDuncan.net" for more
information.

SQL::SyntaxModel is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License (GPL) version 2 as published
by the Free Software Foundation (http://www.fsf.org/).  You should have
received a copy of the GPL as part of the SQL::SyntaxModel distribution, in the
file named "LICENSE"; if not, write to the Free Software Foundation, Inc., 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA.

Any versions of SQL::SyntaxModel that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits. SQL::SyntaxModel is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GPL for more details.

Linking SQL::SyntaxModel statically or dynamically with other modules is making
a combined work based on SQL::SyntaxModel.  Thus, the terms and conditions of
the GPL cover the whole combination.

As a special exception, the copyright holders of SQL::SyntaxModel give you
permission to link SQL::SyntaxModel with independent modules that are
interfaces to or implementations of databases, regardless of the license terms
of these independent modules, and to copy and distribute the resulting combined
work under terms of your choice, provided that every copy of the combined work
is accompanied by a complete copy of the source code of SQL::SyntaxModel (the
version of SQL::SyntaxModel used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on SQL::SyntaxModel, and
which is fully useable when not linked to SQL::SyntaxModel in any form.

Note that people who make modified versions of SQL::SyntaxModel are not
obligated to grant this special exception for their modified versions; it is
their choice whether to do so.  The GPL gives permission to release a modified
version without this exception; this exception also makes it possible to
release a modified version which carries forward this exception.

While it is by no means required, the copyright holders of SQL::SyntaxModel
would appreciate being informed any time you create a modified version of
SQL::SyntaxModel that you are willing to distribute, because that is a
practical way of suggesting improvements to the standard version.

=cut

######################################################################

my %text_strings = (
	'SSMBTR_N_CR_NODE_TREE_NO_ARGS' => 
		"create_child_node_tree(): missing argument",
	'SSMBTR_N_CR_NODE_TREE_BAD_ARGS' => 
		"create_child_node_tree(): invalid argument; it is not a hash ref, but rather is '{ARG}'",

	'SSMBTR_C_CR_NODE_TREE_NO_ARGS' => 
		"create_node_tree(): missing argument",
	'SSMBTR_C_CR_NODE_TREE_BAD_ARGS' => 
		"create_node_tree(): invalid argument; it is not a hash ref, but rather is '{ARG}'",
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
	use SQL::SyntaxModel::ByTree;

	# do work ...

	my $translator = Locale::KeyedText->new_translator( 
		['SQL::SyntaxModel::ByTree::L::', 'SQL::SyntaxModel::L::'], ['en'] );

	# do work ...

	eval {
		# do work with SQL::SyntaxModel::ByTree, which may throw an exception ...
	};
	if( my $error_message_object = $@ ) {
		# examine object here if you want and programmatically recover...

		# or otherwise do the next few lines...
		my $error_user_text = $translator->translate_message( $error_message_object );
		# display $error_user_text to user by some appropriate means
	}

	# continue working, which may involve using SQL::SyntaxModel::ByTree some more ...

=head1 DESCRIPTION

The SQL::SyntaxModel::ByTree::L::en Perl 5 object class contains localization
data for SQL::SyntaxModel::ByTree.  It is designed to be interpreted by
Locale::KeyedText.

This class is optional and you can still use SQL::SyntaxModel::ByTree
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

	my $user_text_template = SQL::SyntaxModel::ByTree::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the associated
user text template string, if there is one, or undef if not.

=head1 SEE ALSO

perl(1), Locale::KeyedText, SQL::SyntaxModel::ByTree, SQL::SyntaxModel::L::*.

=cut
