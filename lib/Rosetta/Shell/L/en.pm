#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

# Constant values used by packages in this file:
use only 'Readonly' => '1.03-';
Readonly my %TEXT_STRINGS => (
    'ROS_S_HELLO' => q[Welcome to the Rosetta DBMS!],
    'ROS_S_GOODBYE' => q[Goodbye!],
    'ROS_S_DBMS_INIT_FAIL'
        => q[Initialization of the Engine "<ENGINE_NAME>" has failed.],
    'ROS_S_DBMS_INIT_SUCCESS'
        => q[Initialization of the Engine "<ENGINE_NAME>" is successful.],
    'ROS_S_PROMPT'
        => q[Enter a Rosetta D command to execute (all on one line),]
           . q[ or press ENTER to quit.],
    'ROS_S_TODO_RESULT' => q[TODO: prepare and execute that command.],
);

###########################################################################
###########################################################################

{ package Rosetta::Shell::L::en; # module
    use version; our $VERSION = qv('0.1.1');
    sub get_text_by_key {
        my (undef, $msg_key) = @_;
        return $TEXT_STRINGS{$msg_key};
    }
} # module Rosetta::Shell::L::en

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Rosetta::Shell::L::en -
Localization of Rosetta::Shell for English

=head1 VERSION

This document describes Rosetta::Shell::L::en version 0.1.1.

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
