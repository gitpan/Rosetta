=head1 NAME

SQL::SyntaxModel::ByTree::L::en - Localization of SQL::SyntaxModel::ByTree for English

=cut

######################################################################

package SQL::SyntaxModel::ByTree::L::en;
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
messages generated by SQL::SyntaxModel::ByTree.>

=head1 COPYRIGHT AND LICENSE

This module is Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>, or
visit "http://www.DarrenDuncan.net" for more information.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl 5.8 itself.

Any versions of this module that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits.  This
module is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

######################################################################

my %text_strings = (
	'SSMBTR_C_CR_NODE_TREE_NO_ARGS' => 
		"create_node_tree(): missing argument",
	'SSMBTR_C_CR_NODE_TREE_BAD_ARGS' => 
		"create_node_tree(): invalid argument; it is not a hash ref, but rather is '{ARG}'",

	'SSMBTR_N_CR_NODE_TREE_NO_ARGS' => 
		"create_child_node_tree(): missing argument",
	'SSMBTR_N_CR_NODE_TREE_BAD_ARGS' => 
		"create_child_node_tree(): invalid argument; it is not a hash ref, but rather is '{ARG}'",
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

The SQL::SyntaxModel::ByTree::L::en Perl 5 module contains localization
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
