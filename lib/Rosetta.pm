=head1 NAME

Rosetta - Framework for RDBMS-generic apps and schemas

=cut

######################################################################

package Rosetta;
require 5.004;

# Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.05';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004 (by intent; tested with 5.6)

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	Rosetta::Engine (only if "new" method used)

=head1 SYNOPSIS

I<Please see the file Rosetta::Framework.pod for a SYNOPSIS.>

=head1 DESCRIPTION

The Rosetta class currently has little functionality of its own, but rather
mainly exists to help the CPAN indexers and users find the actual main
documentation for the Rosetta framework, which starts in the file
"Rosetta::Framework.pod".  Similarly, the CPAN indexers like to find a module
with the same name as the distribution in order to extract the single-line
module summary for the distribution, from the module's NAME section; that is
provided here.  Please see the file "Rosetta::Framework.pod" for the main
Rosetta purpose and design documentation.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

=head2 new(...)

This is a mere convenience function and it does the exact same thing as calling
Rosetta::Engine->new(), which you should actually be using instead.  Please see
the POD in the Rosetta::Engine module for details on its use.

=cut

######################################################################

sub new {
	require Rosetta::Engine;
	return( Rosetta::Engine->new( @_[1..$#_] ) );
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), DBI, DBD::*, Alzabo, SQL::Schema, DBIx::AnyDBD, SQL::Builder,
DBIx::Browse, DBIx::Abstract, DBIx::SearchBuilder, and various other modules.

=cut
