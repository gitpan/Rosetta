=head1 NAME

Rosetta - Framework for RDBMS-generic apps and schemas

=head1 ABSTRACT

See the file Rosetta::Framework for the main Rosetta documentation.

=cut

######################################################################

package Rosetta;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.073';

use Locale::KeyedText 0.02;
use SQL::SyntaxModel 0.11;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Locale::KeyedText 0.02 (for error messages)
	SQL::SyntaxModel 0.11

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

Any versions of Rosetta that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits. 
Rosetta is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GPL for more details.

Linking Rosetta statically or dynamically with other modules is making a
combined work based on Rosetta.  Thus, the terms and conditions of the GPL
cover the whole combination.

As a special exception, the copyright holders of Rosetta give you permission to
link Rosetta with independent modules that are interfaces to or implementations
of databases, regardless of the license terms of these independent modules, and
to copy and distribute the resulting combined work under terms of your choice,
provided that every copy of the combined work is accompanied by a complete copy
of the source code of Rosetta (the version of Rosetta used to produce the
combined work), being distributed under the terms of the GPL plus this
exception.  An independent module is a module which is not derived from or
based on Rosetta, and which is fully useable when not linked to Rosetta in any
form.

Note that people who make modified versions of Rosetta are not obligated to
grant this special exception for their modified versions; it is their choice
whether to do so.  The GPL gives permission to release a modified version
without this exception; this exception also makes it possible to release a
modified version which carries forward this exception.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of 
suggesting improvements to the standard version.

=head1 SYNOPSIS

I<Please see the file lib/Rosetta/Framework.pod for a SYNOPSIS.>

=head1 DESCRIPTION

This module contains the implementations of the Rosetta::Engine::* classes, 
or it will once they are done.  Please see "lib/Rosetta/Framework.pod" for the
main Rosetta purpose and design documentation.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 SEE ALSO

perl(1), Rosetta::Framework, Rosetta::SimilarModules, SQL::SyntaxModel.

=cut
