#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

# External packages used by packages in this file, that don't export symbols:
use only 'Locale::KeyedText' => '1.72.0-';
use only 'Rosetta::Model' => '0.724.0';

###########################################################################
###########################################################################

# Constant values used by packages in this file:
use only 'Readonly' => '1.03-';
# (None Yet)

###########################################################################
###########################################################################

{ package Rosetta; # package
    use version; our $VERSION = qv('0.724.0');
    # Note: This given version applies to all of this file's packages.
} # package Rosetta

###########################################################################
###########################################################################

{ package Rosetta::Interface::DBMS; # class

    # External packages used by the Rosetta::Interface::DBMS class, that do export symbols:
    use only 'Class::Std' => '0.0.8-';
    use only 'Class::Std::Utils' => '0.0.2-';

    # Attributes of every Rosetta::Interface::DBMS object:
    # (None Yet)

###########################################################################

sub BUILD {
    my ($self, $ident, $arg_ref) = @_;
    my $engine_name = $arg_ref->{'engine_name'};

    # This is a quick hack that just tests if the Engine module loads or not.
    # It WILL be replaced.
    eval "require $engine_name;";
    die $@
        if $@;

    return;
}

###########################################################################

} # class Rosetta::Interface::DBMS

###########################################################################
###########################################################################

{ package Rosetta::Interface::Exception; # class

    # External packages used by the Rosetta::Interface::Exception class, that do export symbols:
    use only 'Class::Std' => '0.0.8-';
    use only 'Class::Std::Utils' => '0.0.2-';

    # Attributes of every Rosetta::Interface::Exception object:
    # (None Yet)

###########################################################################



###########################################################################

} # class Rosetta::Interface::Exception

###########################################################################
###########################################################################

{ package Rosetta::Interface::Command; # class

    # External packages used by the Rosetta::Interface::Command class, that do export symbols:
    use only 'Class::Std' => '0.0.8-';
    use only 'Class::Std::Utils' => '0.0.2-';

    # Attributes of every Rosetta::Interface::Command object:
    # (None Yet)

###########################################################################



###########################################################################

} # class Rosetta::Interface::Command

###########################################################################
###########################################################################

{ package Rosetta::Interface::Value; # class

    # External packages used by the Rosetta::Interface::Value class, that do export symbols:
    use only 'Class::Std' => '0.0.8-';
    use only 'Class::Std::Utils' => '0.0.2-';

    # Attributes of every Rosetta::Interface::Value object:
    # (None Yet)

###########################################################################



###########################################################################

} # class Rosetta::Interface::Value

###########################################################################
###########################################################################

{ package Rosetta::Interface::Variable; # class

    # External packages used by the Rosetta::Interface::Variable class, that do export symbols:
    use only 'Class::Std' => '0.0.8-';
    use only 'Class::Std::Utils' => '0.0.2-';

    # Attributes of every Rosetta::Interface::Variable object:
    # (None Yet)

###########################################################################



###########################################################################

} # class Rosetta::Interface::Variable

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Rosetta -
Rigorous database portability

=head1 VERSION

This document describes Rosetta version 0.724.0.

It also describes the same-number versions of Rosetta::Interface::DBMS
("DBMS"), Rosetta::Interface::Exception ("Exception"),
Rosetta::Interface::Command ("Command"), Rosetta::Interface::Value
("Value"), and Rosetta::Interface::Variable ("Variable").

I<Note that the "Rosetta" package serves only as the name-sake
representative for this whole file, which can be referenced as a unit by
documentation or 'use' statements or Perl archive indexes.  Aside from
'use' statements, you should never refer directly to "Rosetta" in your
code; instead refer to other above-named packages in this file.>

=head1 SYNOPSIS

    use Rosetta; # also loads Rosetta::Model and Locale::KeyedText

    # Instantiate a Rosetta DBMS / virtual machine.
    my $dbms = Rosetta::Interface::DBMS->new({
        'engine_name' => 'Rosetta::Engine::Example' });

    # TODO: Create or connect to a repository and work with it.

=head1 OLD SYNOPSIS TO REWRITE

    ### DURING INIT PHASE ###

    use Rosetta; # also loads Rosetta::Model and Locale::KeyedText
    use Scalar::Util qw( blessed );

    # Define how to talk to our database and where it is.
    my %DB_CONFIG = (
        'engine_name' => 'Rosetta::Engine::Example',
        'depot_identity' => {
            'file_name' => 'My Data',
        },
    );

    # Create a Rosetta Interface root, whose attributes will hold all of
    # the other data structures used by the Rosetta framework, as used by
    # the current process/application.
    my $rosetta_root = Rosetta::Interface->new();

    # Load a Rosetta Engine which will implement database access requests.
    my $engine = $rosetta_root->load_engine( $DB_CONFIG{'engine_name'} );

    # Initialize (closed) database connection handle we will work with;
    # this does not talk to the underlying dbms.
    my $conn
        = $engine->new_depot_connection( $DB_CONFIG{'depot_identity'} );

    # Create a Rosetta::Model document in which we store some local
    # command definitions and fragments thereof.
    my $irl_doc = Rosetta::Model::Document->new();

    # Define some data types.
    my $sdtd_person_id = $irl_doc->build_node_tree(
        [ 'scalar_data_type', { 'base_type' => 'NUM_INT',
            'num_precision' => 9 } ]
    );
    my $sdtd_person_name = $irl_doc->build_node_tree(
        [ 'scalar_data_type', { 'base_type' => 'STR_CHAR',
            'max_chars' => 100, 'char_set' => 'UNICODE' } ]
    );
    my $sdtd_person_sex = $irl_doc->build_node_tree(
        [ 'scalar_data_type', { 'base_type' => 'STR_CHAR',
                'max_chars' => 1, 'char_set' => 'UNICODE' }, [
            [ 'scalar_data_type_value', { 'value' => 'M' } ],
            [ 'scalar_data_type_value', { 'value' => 'F' } ],
        ] ]
    );
    my $rdtd_person = $irl_doc->build_node_tree(
        [ 'row_data_type', undef, [
            [ 'row_data_type_field', { 'name' => 'id' }, [
                $sdtd_person_id,
            ] ],
            [ 'row_data_type_field', { 'name' => 'name' }, [
                $sdtd_person_name,
            ] ],
            [ 'row_data_type_field', { 'name' => 'sex' }, [
                $sdtd_person_sex,
            ] ],
        ] ]
    );

    # Define the 'person' table.
    my $tbd_person = $irl_doc->build_node_tree(
        [ 'table', { 'name' => 'person' }, [
            [ 'interface_row', undef, [
                $rdtd_person,
            ] ],
            [ 'table_field_detail', { 'name' => 'id', 'mandatory' => 1 } ],
            [ 'table_field_detail', { 'name' => 'name',
                'mandatory' => 1 } ],
            [ 'table_index', { 'name' => 'primary' ,
                    'index_type' => 'UNIQUE' }, [
                [ 'table_index_field', { 'name' => 'person_id' } ],
            ] ],
        ] ]
    );

    # Define and compile a routine that will validate whether the 'person'
    # table exists (and is correct).
    my $fnd_tb_person_exists = $irl_doc->build_node_tree(
        [ 'function', { 'name' => 'tb_person_exists' }, [
            [ 'routine_arg', { 'name' => 'result',
                    'arg_type' => 'RETURN' }, [
                [ 'scalar_data_type', { 'base_type' => 'BOOLEAN' } ],
            ] ],
            [ 'routine_body', undef, [
                [ 'assignment_stmt', { 'into' => 'result' }, [
                    [ 'expression', {
                            'vf_call_sfunc' => 'DEPOT_OBJECT_EXISTS' }, [
                        $tbd_person,
                    ] ],
                ] ],
            ] ],
        ] ]
    );
    my $fnh_tb_person_exists
        = $conn->compile_routine( $fnd_tb_person_exists );

    # Define and compile a routine that will create the 'person' table.
    # Like: CREATE TABLE person (
    #           id INTEGER(9) NOT NULL,
    #           name VARCHAR(100) NOT NULL,
    #           sex ENUM('M','F'),
    #           PRIMARY KEY (id)
    #       );
    #       COMMIT;
    my $prd_create_tb_person = $irl_doc->build_node_tree(
        [ 'procedure', { 'name' => 'create_tb_person' }, [
            [ 'routine_body', undef, [
                [ 'create_stmt', undef, [
                    $tbd_person,
                ] ],
                [ 'statement', { 'call_sproc' => 'COMMIT' } ],
            ] ],
        ] ]
    );
    my $prh_create_tb_person
        = $conn->compile_routine( $prd_create_tb_person );

    # Define and compile a procedure that will insert a record into the
    # 'person' table, which is populated from its row argument.
    # Like: INSERT INTO person
    #       SET id = :new_person.id,
    #           name = :new_person.name,
    #           sex = :new_person.sex;
    #       COMMIT;
    my $prd_add_person = $irl_doc->build_node_tree(
        [ 'procedure', { 'name' => 'add_person' }, [
            [ 'routine_arg', { 'name' => 'new_person',
                    'arg_type' => 'IN' }, [
                $rdtd_person,
            ] ],
            [ 'routine_body', undef, [
                [ 'insert_stmt', { 'into' => 'person' }, [
                    [ 'expression', { 'vf_routine_arg' => 'new_person' } ],
                ] ],
                [ 'statement', { 'call_sproc' => 'COMMIT' } ],
            ] ],
        ] ]
    );
    my $prh_add_person = $conn->compile_routine( $prd_add_person );

    # Define and compile a function that will select a record from the
    # 'person' table, whose 'id' field matches the functions 'person_id'
    # argument, and returns that as a row.
    # Like: SELECT s.id AS id, s.name AS name, s.sex AS sex
    #       FROM person AS s
    #       WHERE s.id = :person_id;
    my $fnd_get_person = $irl_doc->build_node_tree(
        [ 'function', { 'name' => 'get_person' }, [
            [ 'routine_arg', { 'name' => 'result',
                    'arg_type' => 'RETURN' }, [
                $rdtd_person,
            ] ],
            [ 'routine_arg', { 'name' => 'person_id',
                    'arg_type' => 'IN' }, [
                $sdtd_person_id,
            ] ],
            [ 'routine_body', undef, [
                [ 'select_stmt', { 'into' => 'result' }, [
                    [ 'query', undef, [
                        [ 'interface_row', undef, [
                            $rdtd_person,
                        ] ],
                        [ 'query_source', { 'name' => 's',
                                'match' => 'person' }
                            [ 'query_source_field', { 'name' => 'id' } ],
                        ] ],
                        [ 'query_clause', { 'type' => 'WHERE' }, [
                            [ 'expression', {
                                    'vf_call_sfunc' => 'EQ' }, [
                                [ 'expression', {
                                    'call_sroutine_arg' => 'LHS',
                                    'vf_source_field' => 'id' } ],
                                [ 'expression', {
                                    'call_sroutine_arg' => 'RHS',
                                    'vf_routine_arg' => 'person_id' } ],
                            ] ],
                        ] ],
                    ] ],
                ] ],
            ] ],
        ] ]
    );
    my $fnh_get_person = $conn->compile_routine( $fnd_get_person );

    ### DURING WORK PHASE ###

    # Actually connect to the database / talk to the underlying dbms;
    # if database doesn't exist yet, try to create it.
    try {
        $conn->open();
    };
    if (my $e = $@) {
        if (blessed $e and $e->isa( 'Locale::KeyedText::Message' )
                and $e->get_msg_key eq 'DEPOT_NO_EXIST') {
            $conn->create_target_depot();
            $conn->open();
        }
        else {
            die $@;
        }
    }

    try {
        # Check that the 'person' table exists and create it if not.
        if (!$fnh_tb_person_exists->prepare_and_execute()->get_payload()) {
            $prh_create_tb_person->prepare_and_execute();
        }

        # Prompt user for details of 3 people and add them to the database.
        $prh_add_person->prepare();
        for (1..3) {
            my $new_person = Rosetta::Interface::Row->new({ 'payload' => {
                'id' => ask_user_for_id(),
                'name' => ask_user_for_name(),
                'sex' => ask_user_for_sex(),
            } });
            $prh_add_person->bind_arg( 'new_person', $new_person );
            try {
                $prh_add_person->execute();
            };
            if (my $e = $@) {
                show_error_likely_bad_input( $e );
            }
            else {
                show_add_success_message();
            }
        }

        # Prompt user for id of 3 people and fetch them from the database.
        $fnh_get_person->prepare();
        for (1..3) {
            my $person_id = Rosetta::Interface::Scalar->new({
                'payload' => ask_user_for_id() });
            $fnh_get_person->bind_arg( 'person_id', $person_id );
            my $fetched_person = try {
                $fnh_get_person->execute();
            };
            if (my $e = $@) {
                show_error_likely_bad_input( $e );
            }
            else {
                show_fetched_name( $fetched_person->get_field('name') );
                show_fetched_sex( $fetched_person->get_field('sex') );
            }
        }
    };

    # Close the database connection (it can be reopened later).
    $conn->close();

=head1 DESCRIPTION

The "Rosetta" DBMS framework is a powerful but elegant system, which makes
it easy to create and use relational databases in a very reliable,
portable, and efficient way.  This "Rosetta" file is the core of the
Rosetta framework and defines a common programmatic interface (API), called
the Rosetta Native Interface (RNI), which applications invoke and which
multiple interchangeable "Engine" back-ends (usually provided by third
parties) implement.  This interface is rigorously defined, such that there
should be no ambiguity when trying to invoke or implement it, and so an
application written to it should behave identically no matter which
conforming "Engine" is in use.

Rosetta incorporates a complete and uncompromising implementation of "The
Third Manifesto" (TTM), a formal proposal by Christopher J. Date and Hugh
Darwen for a solid foundation for data and database management systems
(DBMSs); like Edgar F. Codd's original papers, TTM can be seen as an
abstract blueprint for the design of a DBMS and the language interface to
such a DBMS.  The main web site for TTM is
L<http://www.thethirdmanifesto.com/>, and its authors have also written
several books and papers and taught classes on the subject over the last
35+ years, along with Codd himself (some are listed in the
L<Rosetta::SeeAlso> documentation file).  Note that the Rosetta
documentation will be focusing mainly on how Rosetta itself works, and will
not spend much time in providing rationales; you can read TTM itself and
various other external documentation for much of that.

The Rosetta Native Interface is defined mainly in terms of a new high-level
programming language named "Rosetta D", which is computationally complete
(and industrial strength) and has fully integrated database functionality;
this language, which satisfies TTM's definition of a "D" language, is
described fully in the L<Rosetta::Language> documentation file that comes
with this "Rosetta" distribution.

While it is possible that one could write a self-contained application in
Rosetta D and compile that into its own executable, in practice one would
normally just write some components of their application in Rosetta D (as
either named modules or anonymous routines) and write the rest of the
application in their other language(s) of choice.  Assuming the main
application is written in Perl, it is this "Rosetta" file which provides
the glue between your Perl code and your Rosetta D code; "Rosetta"
implements a virtual machine that is embedded in your Perl application and
in which the Rosetta D code runs (it is analagous to the Perl interpreter
itself, which provides a virtual machine in which Perl code runs).

The classes and methods of this "Rosetta" file, together with those of
L<Rosetta::Model>, define the balance of the Rosetta Native Interface.  A
Rosetta::Interface::DBMS object represents a single active Rosetta virtual
machine; it has a spartan DBI-inspired set of methods which you use to
compile/prepare and/or invoke/execute Rosetta D statements and routines
within the virtual machine, input data to it, and output data from it.

You can create more than one DBMS object at a time, and they are
essentially all isolated from each other, even if more than one uses the
same Engine class to implement it; that is, multiple DBMS objects will not
have references to each other at a level visible in the Rosetta Native
Interface, if at all.  To account for situations where multiple DBMS
objects want to use the same external resources, such as a repository file
on disk, it is expected that the Engines will employ appropriate measures
such as system-managed locks so that resource corruption or application
failure is prevented.  I<Also, Rosetta should be thread safe and/or saavy
in the future, but for now it officially is not and you should not share
Rosetta objects between multiple threads, nor have objects in separate
threads try to access the same external resources.>

Rosetta does not use any dialect of SQL in its native API (unlike many
other DBMS products) because SQL is more ambiguous and error-prone to use,
and it is less expressive.  While Rosetta D is very different from SQL, it
is fully capable of modelling anything in the real world accurately, and it
can support a complete SQL emulation layer on top of it, so that your
legacy applications can be migrated to use the Rosetta DBMS with little
trouble.  Likewise, emulation layers for any other programming language can
be supported, such as Tutorial D or XQuery or FoxPro or dBase.

One distinctive feature of a Rosetta DBMS (compared to a typical other
vendor's DBMS) is that data definition statements are structured as
standard data manipulation statements but that the target relation
variables are system catalog relation variables rather than user-defined
relation variables.  In SQL terms, you create or alter tables by adding or
updating their "information schema" records, which in SQL are read-only,
not by using special 'create' or 'alter' statements.

Each Rosetta Engine has the complete freedom to implement the Rosetta DBMS
and Rosetta D however it likes; all Rosetta cares about is that the user
interface and behaviour conform to its preconceptions.

L<Rosetta::Engine::Example> is the self-contained and pure-Perl reference
implementation of an Engine and is included in the "Rosetta" core
distribution to allow the core to be completely testable on its own.  It is
coded intentionally in a simple fashion so that it is easy to maintain and
and easy for developers to study.  As a result, while it performs correctly
and reliably, it also performs quite slowly; you should only use Example
for testing, development, and study; you should not use it in production.

For production use, there should be a wide variety of third party Engine
modules that become available over time.  One plan which I favor is that
the new (under development) enterprise-strength and Perl implemented
database server named L<Genezzo> (see also L<http://www.genezzo.com/>) will
evolve to implement the Rosetta DBMS natively, and be I<the> back-end which
I recommend above all others for production use.

Most of the other (near term) third party Engines will likely just map
Rosetta's rigorously defined API onto a pre-existing (pseudo) relational
database manager (such as SQLite, PostgreSQL, MySQL, Firebird, Teradata,
Oracle, Sybase, SQL Server, Informix, DB2, OpenBase, FrontBase, etc).
Given this fact, Rosetta's most prominant feature is that it provides a
common API for access to those databases, each of which takes a different
SQL or pseudo-SQL dialect.  An application written to it should easily port
to alternative relational database engines with minimal effort.

This might seem strange to somebody who has not tried to port between
databases before, especially given that the Perl DBI purports to provide
"Database Independence".  However, the level of DBI's provided independence
is I<Database Driver Independence>, and not I<Database Language
Independence>.  To further demonstrate the difference, it is useful to
compare the DBI and Rosetta.  See the file L<Rosetta::Overview>
documentation in this distribution for that comparison.

=head1 INTERFACE

The interface of Rosetta is entirely object-oriented; you use it by
creating objects from its member classes, usually invoking C<new()> on the
appropriate class name, and then invoking methods on those objects.  All of
their attributes are private, so you must use accessor methods.  Rosetta
does not declare any subroutines or export such.

The usual way that Rosetta indicates a failure is to throw an exception;
most often this is due to invalid input.  If an invoked routine simply
returns, you can assume that it has succeeded, even if the return value is
undefined.

=head2 The Rosetta::Interface::DBMS Class

I<This documentation is pending.>

=head2 The Rosetta::Interface::Exception Class

I<This documentation is pending.>

=head2 The Rosetta::Interface::Command Class

I<This documentation is pending.>

=head2 The Rosetta::Interface::Value Class

I<This documentation is pending.>

=head2 The Rosetta::Interface::Variable Class

I<This documentation is pending.>

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
L<Rosetta::Model-(0.724.0)|Rosetta::Model>.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

These documentation files are included in the Rosetta distribution:
L<Rosetta::Language>, L<Rosetta::Migration>.

The Perl 5 module L<Rosetta::Validator> is bundled with Rosetta and can be
used to test Rosetta Engine classes.

The Perl 5 package L<Rosetta::Engine::Example> is bundled with Rosetta and
implements a reference implementation of a Rosetta Engine.

The Perl 5 module L<Rosetta::Shell> is bundled with Rosetta and implements
a command shell for the Rosetta DBMS.

Go to the L<Rosetta::SeeAlso> file for the majority of external references.

=head1 BUGS AND LIMITATIONS

I<This documentation is pending.>

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta DBMS framework.

Rosetta is Copyright (c) 2002-2006, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to C<perl@DarrenDuncan.net>,
or visit L<http://www.DarrenDuncan.net/> for more information.

Rosetta is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (L<http://www.fsf.org/>); either version 2 of the
License, or (at your option) any later version.  You should have received a
copy of the GPL as part of the Rosetta distribution, in the file named
"GPL"; if not, write to the Free Software Foundation, Inc., 51 Franklin St,
Fifth Floor, Boston, MA  02110-1301, USA.

Linking Rosetta statically or dynamically with other components is making a
combined work based on Rosetta.  Thus, the terms and conditions of the GPL
cover the whole combination.  As a special exception, the copyright holders
of Rosetta give you permission to link Rosetta with other free software
components, as defined by the Free Software Foundation at
L<http://www.gnu.org/philosophy/free-sw.html>.  You may copy and distribute
such a system following the terms of the GPL for Rosetta and the licenses
of the other components concerned, provided that you include the source
code of the other components when and as the GPL requires distribution of
source code.  However, for an additional fee, the copyright holders of
Rosetta can sell you an alternate, limited license that allows you to link
Rosetta with non-free software components.

Any versions of Rosetta that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits.
Rosetta is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  However, for an additional fee, the copyright
holders of Rosetta can sell you a warranty for it.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of
suggesting improvements to the standard version.

=head1 ACKNOWLEDGEMENTS

None yet.

=cut
