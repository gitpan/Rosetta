=head1 NAME

Rosetta::Validator - A common comprehensive test suite to run against all Engines

=cut

######################################################################

package Rosetta::Validator;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Locale::KeyedText 0.04;
use SQL::SyntaxModel 0.23;
use Rosetta 0.15;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Locale::KeyedText 0.04 (for error messages)
	SQL::SyntaxModel 0.23
	Rosetta 0.15

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

# Names of properties for objects of the Rosetta::Validator class are declared here:

######################################################################


######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

	use strict; use warnings;
	use Rosetta::Validator;

	...

=head1 DESCRIPTION

The Rosetta::Validator Perl 5 module is a common comprehensive test suite to
run against all Rosetta Engines.  You run it against a Rosetta Engine module to
ensure that the Engine and/or the database behind it implements the parts of
the Rosetta API that your application needs, and that the API is implemented
correctly.  Rosetta::Validator is intended to guarantee a measure of quality
assurance (QA) for Rosetta, so your application can use the database access
framework with confidence of safety.

Alternately, if you are writing a Rosetta Engine module yourself,
Rosetta::Validator saves you the work of having to write your own test suite
for it.  You can also be assured that if your module passes
Rosetta::Validator's approval, then your module can be easily swapped in for
other Engine modules by your users, and that any changes you make between
releases haven't broken something important.

Rosetta::Validator would be used similarly to how Sun has an official
validation suite for Java Virtual Machines to make sure they implement the
official Java specification.

For reference and context, please see the FEATURE SUPPORT VALIDATION
documentation section in the core "Rosetta" module.

Note that, as is the nature of test suites, Rosetta::Validator will be getting
regular updates and additions, so that it anticipates all of the different ways
that people want to use their databases.  This task is unlikely to ever be
finished, given the seemingly infinite size of the task.  You are welcome and
encouraged to submit more tests to be included in this suite at any time, as
holes in coverage are discovered.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

perl(1), Rosetta, SQL::SyntaxModel, Locale::KeyedText, Rosetta::Engine::Generic.

=cut
