=head1 NAME

Rosetta::Engine::Null - An Engine with no functionality, for testing the Rosetta core

=cut

######################################################################

package Rosetta::Engine::Null;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Rosetta 0.10;

use base qw( Rosetta::Engine );

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Rosetta 0.10

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
######################################################################

sub new {
	my ($class) = @_;
	my $engine = bless( {}, ref($class) || $class );
	# Now DO something.
	return( $engine );
}

######################################################################

sub destroy {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################

sub prepare {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################

sub execute {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################

sub finalize {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################

sub has_more_rows {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################

sub fetch_row {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################

sub fetch_all_rows {
	my ($engine, $interface) = @_;
	# Now DO something.
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<To come later.>

=head1 DESCRIPTION

The Rosetta::Engine::Null Perl 5 module is a trivial Rosetta Engine whose only
purpose in life is to help test the core Rosetta module.  It can't actually do
anything itself, and certainly doesn't either interface to or implement a
database.  Look at the other Rosetta::Engine::* modules for that.

As with all Rosetta::Engine::* modules, you are not supposed to instantiate
objects of Rosetta::Engine::Null directly; rather, you use this module
indirectly through the Rosetta::Interface class.  Following this logic, there 
is no class function or method documentation here.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

Rosetta.

=cut
