#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

# External packages used by packages in this file, that don't export symbols:
use only 'Locale::KeyedText' => '1.72.0-';
use only 'Rosetta' => '0.723.0';

###########################################################################
###########################################################################

# Constant values used by packages in this file:
use only 'Readonly' => '1.03-';
Readonly my $EMPTY_STR => q{};

###########################################################################
###########################################################################

{ package Rosetta::Shell; # module
    use version; our $VERSION = qv('0.1.1');

    # External packages used by the Rosetta::Shell module, that do export symbols:
    # (None Yet)

    # State variables used by the Rosetta::Shell module:
    my $translator;
    my $dbms;

###########################################################################

sub main {
    my ($arg_ref) = @_;
    my $engine_name = $arg_ref->{'engine_name'};
    my $user_lang_prefs_ref
        = exists $arg_ref->{'user_lang_prefs'}
          ? $arg_ref->{'user_lang_prefs'} : ['en'];

    $translator = Locale::KeyedText::Translator->new({
        'set_names'    => [
                'Rosetta::Shell::L::',
                'Rosetta::L::',
                'Rosetta::Model::L::',
                'Locale::KeyedText::L::',
                $engine_name . '::L::',
            ],
        'member_names' => $user_lang_prefs_ref,
    });

    _show_message( Locale::KeyedText::Message->new({
        'msg_key' => 'ROS_S_HELLO' }) );

    eval {
        $dbms = Rosetta::Interface::DBMS->new({
            'engine_name' => $engine_name });
    };
    if ($@) {
        _show_message( Locale::KeyedText::Message->new({
            'msg_key'  => 'ROS_S_DBMS_INIT_FAIL',
            'msg_vars' => {
                'ENGINE_NAME' => $engine_name,
            },
        }) );
    }
    else {
        _show_message( Locale::KeyedText::Message->new({
            'msg_key'  => 'ROS_S_DBMS_INIT_SUCCESS',
            'msg_vars' => {
                'ENGINE_NAME' => $engine_name,
            },
        }) );
        _command_loop();
    }

    _show_message( Locale::KeyedText::Message->new({
        'msg_key' => 'ROS_S_GOODBYE' }) );

    return;
}

###########################################################################

sub _command_loop {
    INPUT_LINE:
    while (1) {
        _show_message( Locale::KeyedText::Message->new({
            'msg_key' => 'ROS_S_PROMPT' }) );

        my $user_input = <STDIN>;
        chomp $user_input;

        # user simply hits return on an empty line to quit the program
        last INPUT_LINE
            if $user_input eq $EMPTY_STR;

        eval {
            _show_message( Locale::KeyedText::Message->new({
                'msg_key' => 'ROS_S_TODO_RESULT' }) );
        };
        _show_message( $@ )
            if $@; # input error, detected by library
    }

    return;
}

###########################################################################

sub _show_message {
    my ($message) = @_;
    my $user_text = $translator->translate_message( $message );
    if (!$user_text) {
        print STDERR "internal error: can't find user text for a message:"
            . "\n$message$translator"; # note: the objects will stringify
        return;
    }
    print STDOUT $user_text . "\n";
    return;
}

###########################################################################

} # module Rosetta::Shell

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Rosetta::Shell -
Interactive command shell for the Rosetta DBMS

=head1 VERSION

This document describes Rosetta::Shell version 0.1.1.

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
