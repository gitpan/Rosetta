#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

# External packages used by packages in this file, that don't export symbols:
use only 'Locale::KeyedText' => '1.72.0-';
use only 'Rosetta' => '0.723.0-';

###########################################################################
###########################################################################

# Constant values used by packages in this file:
use only 'Readonly' => '1.03-';
# (None Yet)

###########################################################################
###########################################################################

{ package Rosetta::Engine::Example; # class
    use version; our $VERSION = qv('0.723.0');

    # External packages used by the Rosetta::Engine::Example class, that do export symbols:
    use only 'Class::Std' => '0.0.8-';
    use only 'Class::Std::Utils' => '0.0.2-';

    # Attributes of every Rosetta::Engine::Example object:
    # (None Yet)

###########################################################################



###########################################################################

} # class Rosetta::Engine::Example

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Rosetta::Engine::Example -
Self-contained reference implementation of a Rosetta Engine

=head1 VERSION

This document describes Rosetta::Engine::Example version 0.723.0.

=head1 SYNOPSIS

I<This documentation is pending.>

=head1 DESCRIPTION

I<This documentation is pending.>

=head1 INTERFACE

I<This documentation is pending; this section may also be split into several.>

=head1 DIAGNOSTICS

I<This documentation is pending.>

=head1 CONFIGURATION AND ENVIRONMENT

I<This documentation is pending.>

=head1 DEPENDENCIES

This file requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl 5 packages L<version> and L<only>, which would
conceptually be built-in to Perl, but aren't, so they are on CPAN instead.

It also requires these Perl 5 packages that are on CPAN:
L<Readonly-(1.03...)|Readonly>.

It also requires these Perl 5 packages that are on CPAN:
L<Class::Std-(0.0.8...)|Class::Std>,
L<Class::Std::Utils-(0.0.2...)|Class::Std::Utils>.

It also requires these Perl 5 classes that are on CPAN:
L<Locale::KeyedText-(1.72.0...)|Locale::KeyedText> (for error messages).

It also requires these Perl 5 classes that are in the current distribution:
L<Rosetta-0.723.0|Rosetta>.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

Go to L<Rosetta> for the majority of distribution-internal references, and
L<Rosetta::SeeAlso> for the majority of distribution-external references.

=head1 BUGS AND LIMITATIONS

I<This documentation is pending.>

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta DBMS framework.

Rosetta is Copyright (c) 2002-2006, Darren R. Duncan.

See the LICENCE AND COPYRIGHT of L<Rosetta> for details.

=head1 ACKNOWLEDGEMENTS

The ACKNOWLEDGEMENTS in L<Rosetta> apply to this file too.

=cut
