=head1 NAME

Rosetta - Framework for RDBMS-generic apps and schemas

=head1 ABSTRACT

The Rosetta framework is intended to support complex (or simple) database-using
Perl 5 applications that are easily portable across databases because all
common product-specific details are abstracted away.  Rosetta is designed to
natively handle (interface to or implement) a superset of generic RDBMS product
features, so that you can do any action that you could before, including
standard data manipulation (including complex multi-table selects or updates
with subqueries or stored procedure calls), and schema manipulation (tables,
views, procedures).  At the same time, it is designed to do its work quickly
and efficiently.  The native interface of Rosetta (RNI) is unique to itself and
verbose, being designed to use non-ambiguous structured definitions of all
tasks; all input is multi-dimensional data structures (or objects) having
atomic values, rather than strings to be parsed.  It is intended primarily for
a data-driven application programming model, where an application uses a "data
dictionary" to control what work it is doing (whose composite values map
directly).  For cases where you don't already have a data dictionary, Rosetta
can scan your existing database to create one.  That said, Rosetta also
includes emulators (which sit on RNI) for common existing database interfaces,
so that most Perl applications can simply use Rosetta as a hot-swappable
replacement for them; you do not have to "learn yet another language" or
re-code your application in order for it to just work with more databases. 
Add-on utilities are also available for the likes of copying or backing up a
database, or editing one through a web interface (like PHPMyAdmin but for Perl
and any RDBMS).

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
use vars qw($VERSION);
$VERSION = '0.02';

# Convenience method as if caller wanted Rosetta::Engine->new() instead.
sub new {
	require Rosetta::Engine;
	return( Rosetta::Engine->new( @_[1..$#_] ) );
}

1;
__END__

######################################################################

=head1 PREFACE

The Rosetta class currently has little functionality of its own, but rather
mainly contains the collective POD documentation for how to use the Rosetta::*
modules as an integrated but extensible frameworks.  Any documentation in this
file should be considered to always refer to the aforementioned framework as a
single entity, unless explicitely stated otherwise.  While Rosetta can be
'used' and it does have a new() class method, that simply is a convenient shim
for Rosetta::Engine->new(); do not try to call any other methods or functions
of Rosetta itself, but rather use the other modules as appropriate.  This class
also declares the $VERSION global variable, that variable is only meant to
indicate the version of the whole distribution.

=head1 DEPENDENCIES

=head2 Perl Version

	5.004 (by intent; tested with 5.6)

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	DBI (used by various Rosetta::Driver::* modules; minimum version unknown)
	DBD::* (used by various Rosetta::Driver::* modules; minimum versions unknown)

=head1 SYNOPSIS

=head2 Content of settings file "survey_prefs.pl", used by script below:

	my $rh_prefs = {
		pdbi_connect_args => {
			driver => 'Rosetta::Driver::MySQL-3-23',
			server => 'survey1',
			user => 'joebloe',
			pass => 'fdDF9X0sd7zy',
		},
		question_list => [
			{
				visible_title => "What's your name?",
				type => 'str',
				name => 'name',
				is_required => 1,
			}, {
				visible_title => "What's the combination?",
				type => 'int',
				name => 'words',
			}, {
				visible_title => "What's your favorite colour?",
				type => 'str',
				name => 'color',
			},
		],
	};
	
=head2 Content of a simple CGI script for implementing a web survey:

	#!/usr/bin/perl
	use strict;
	
	&script_main();
	
	sub script_main {
		my $base_url = 'http://'.($ENV{'HTTP_HOST'} || '127.0.0.1').$ENV{'SCRIPT_NAME'};
		my ($curr_mode) = $ENV{'QUERY_STRING'} =~ m/mode=([^&]*)/;
		
		my $form_data_str = '';
		read( STDIN, $form_data_str, $ENV{'CONTENT_LENGTH'} );
		chomp( $form_data_str );
		my %form_values = ();
		foreach my $pair (split( '&', $form_data_str )) {
			my ($key, $value) = split( '=', $pair, 2 );
			next if( $key eq "" );
			$key =~ tr/+/ /;
			$key =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
			$value =~ tr/+/ /;
			$value =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
			$form_values{$key} = $value;
		}
		
		my $fn_prefs = 'survey_prefs.pl';
		
		print
			"Status: 200 OK\n",
			"Content-type: text/html\n\n",
			"<html><head>\n",
			"<title>Simple Web Survey</title>\n",
			"</head><body>\n",
			"<p><a href=\"$base_url?mode=install\">Install Schema</a>\n",
			" | <a href=\"$base_url?mode=remove\">Remove Schema</a>\n",
			" | <a href=\"$base_url?mode=fillin\">Fill In Form</a>\n",
			" | <a href=\"$base_url?mode=report\">See Report</a></p>\n",
			"<hr />\n",
			"<form method=\"POST\" action=\"$base_url?mode=$curr_mode\">\n",
			"<p>\n",
			(&script_make_screen( $fn_prefs, $curr_mode, \%form_values )),
			"</p>\n",
			"<p><input type=\"submit\" name=\"OK\" value=\"Do It Now\" /></p>\n",
			"</form>\n",
			"</body></html>\n";
	}

	sub script_make_screen {
		my ($fn_prefs, $curr_mode, $form_values) = @_;

		my $prefs = do $fn_prefs;
		unless( ref( $prefs ) eq 'HASH' ) {
			return( "Error: can't obtain required preferences hash from '$fn_prefs': ".
				(defined( $prefs ) ? "result not a hash ref, but '$prefs'" : 
				$@ ? "compilation or runtime error of '$@'" : $!) );
		}
		
		eval {
			require Rosetta::Engine; # also compiles ...::* modules
		};
		if( $@ ) {
			return( "Error: can't compile Rosetta::Engine/::* modules: $@" );
		}
		
		my $engine = Rosetta::Engine->new();
		$engine->throw_error( 0 ); # on error, ret result obj, do not throw exception
	
		my $dbh = $engine->execute_command( {
			'type' => 'database_connect',
			'args' => $prefs->{pdbi_connect_args}, # includes what driver to use
		} );
		if( $dbh->is_error() ) {
			return( "Error: can't connect to database: ".$dbh->get_error() );
		}
		
		my $html_output = &script_while_connected( $prefs, $dbh, $curr_mode, $form_values );
		
		my $rv = $dbh->execute_command( {
			'type' => 'database_disconnect',
		} );
		if( $rv->is_error() ) {
			return( "Error: can't disconnect from database: ".$rv->get_error() );
		}
		
		return( $html_output );
	}
	
	sub script_while_connected {
		my ($prefs, $dbh, $curr_mode, $form_values) = @_;

		my $questions = $prefs->{question_list};
		unless( ref( $questions ) eq 'ARRAY' and scalar( @{$questions} ) > 0 ) {
			return( "Error: no survey question list defined in prefs file" );
		}

		my $dd_table = Rosetta::Schema::Table->new( 'survey_data' );
		
		foreach my $question (@{$questions}) {
			unless( ref( $question ) eq 'HASH' and $question->{visible_title} ) {
				return( "Error: invalid question defined in prefs file" );
			}
			$dd_table->add_column( { 
				'name' => $question->{name},
				'data_type' => { 'base_type' => $question->{type}, },
				'is_req' => $question->{is_required},
			} ) or return( "Error: invalid question defined in prefs file" );
		}

		if( $curr_mode eq 'install' ) {
			return( &script_do_install( $dbh, $dd_table, $questions, $form_values ) );
		}
		
		if( $curr_mode eq 'remove' ) {
			return( &script_do_remove( $dbh, $dd_table, $questions, $form_values ) );
		}
		
		if( $curr_mode eq 'fillin' ) {
			return( &script_do_fillin( $dbh, $dd_table, $questions, $form_values ) );
		}
		
		if( $curr_mode eq 'report' ) {
			return( &script_do_report( $dbh, $dd_table, $questions, $form_values ) );
		}
		
		return( "This is a simple demo.  Click on the menu items to do them." );
	}
	
	sub script_to_install {
		my ($dbh, $dd_table, $questions, $form_values) = @_;
		
		unless( $form_values->{OK} ) {  
			# user is seeing screen for first time (did not click 'OK' button)
			return( join( "", 
				"<h1>Install Schema</h1>\n",
				"<p>Do you want to install new schema to store answers for ", 
				"the following questions?</p>\n",
				"<ol>\n",
				(map { "<li>".$_->{visible_title}."</li>\n" } @{$questions}),
				"</ol>\n",
			) );
		}
		
		# user saw screen and clicked the 'OK' button, so try to install;
		# the following makes a Command of type 'table_create' and executes it
		
		my $rv = $dbh->execute_command( $dd_table->new_command_create() );
		if( $rv->is_error() ) {
			return( "Error: can't create survey table: ".$rv->get_error() );
		}
		
		return( "The new schema was successfully created." );
	}
	
	sub script_to_remove {
		my ($dbh, $dd_table, $questions, $form_values) = @_;
		
		unless( $form_values->{OK} ) {  
			# user is seeing screen for first time (did not click 'OK' button)
			return( join( "", 
				"<h1>Remove Schema</h1>\n",
				"<p>Do you want to remove existing schema to store answers for ", 
				"the following questions?</p>\n",
				"<ol>\n",
				(map { "<li>".$_->{visible_title}."</li>\n" } @{$questions}),
				"</ol>\n",
			) );
		}
		
		# user saw screen and clicked the 'OK' button, so try to destroy;
		# the following makes a Command of type 'table_destroy' and executes it
		
		my $rv = $dbh->execute_command( $dd_table->new_command_destroy() );
		if( $rv->is_error() ) {
			return( "Error: can't remove survey table: ".$rv->get_error() );
		}
		
		return( "The new schema was successfully removed." );
	}
	
	sub script_to_fillin {
		my ($dbh, $dd_table, $questions, $form_values) = @_;
	
		unless( $form_values->{OK} ) {  
			# user is seeing screen for first time (did not click 'OK' button)
			return( join( "", 
				"<h1>Fill In Form</h1>\n",
				"<p>Please answer the following questions.  ",
				"Those marked with a '*' are required.</p>\n",
				(map { 
						'<p>'.($_->{is_required} ? '*' : '').$_->{visible_title}.":".
						'<input type="text" name="'.$_->{name}.'" /></p>'."\n"
					} @{$questions}),
			) );
		}
		
		# user saw screen and clicked the 'OK' button, so try to destroy;
		# the following makes a Command of type 'data_insert' and executes it
		my $dd_view = Rosetta::Schema::Table->new( $dd_table );
		my $rv = $dbh->execute_command( $dd_view->new_command_insert( $form_values ) );
		if( $rv->is_error() ) {
			return( "Error: can't save form values in database: ".$rv->get_error() );
		}
		
		return( "Your form submission was saved successfully." );
	}
	
	sub script_to_report {
		my ($dbh, $dd_table, $questions, $form_values) = @_;
		
		# the following makes a Command of type 'data_select' and executes it
		my $dd_view = Rosetta::Schema::Table->new( $dd_table );
		my $cursor = $dbh->execute_command( $dd_view->new_command_select() );
		if( $cursor->is_error() ) {
			return( "Error: can't fetch form values from database: ".$cursor->get_error() );
		}
		my $rowset = $cursor->get_all_rows();

		my @html_output = (
			"<h1>See Report</h1>\n",
			"<p>Here are the answers that previous visitors gave:</p>\n",
			"<table>\n",
			"<tr>\n",
			(map { "<th>".$_->{visible_title}."</th>\n" } @{$questions}),
			"</tr>\n",
		);
		my @question_names = map { $_->{name} } @{$questions};
		foreach my $row (@{$rowset}) {
			push( @html_output, 
				"<tr>\n",
				(map { "<td>".$row->{$_}."</td>\n" } @question_names),
				"</tr>\n",
			);
		}
		push( @html_output, "</table>\n" );
		
		return( join( "", @html_output ) );
	}

	1;

=head1 DESCRIPTION

The Rosetta framework is intended to support complex (or simple)
database-using applications that are easily portable across databases because
common product-specific details are abstracted away.  These include the RDBMS
product and vendor name, what dialect of SQL its scripting or query interface
uses, whether the product uses SQL at all or some other method of querying, how
query results are returned, what features the RDBMS supports, how to manage
connections, how to manage schema, how to manage stored procedures, and perhaps
how to manage users.  The main thing that this framework will not be doing in
the forseeable future is managing the installation and configuration of the
RDBMS itself, which may be on the same machine or a different one.

There are two main types of functionality that the Rosetta framework is
designed to implement; this functionality may be better described in different
groupings.

The first functionality type is the management (creation, modification,
deletion) of the schema in a database, including: tables, keys, constraints,
relations, sequences, views, stored procedures, triggers, and users.  This type
of functionality typically is used infrequently and sets things up for the main
functionality of your database-using application(s). In some cases, typically
with single-user desktop applications, the application may install its own
schema, and/or create new database files, when it starts up or upon the user's
prompting; this can be analogous to the result of a "New..." (or "Save As...")
command in a desktop financial management or file archiving application; the
application would then carry on to use the schema as its personal working
space.  In other cases, typically with multiple-user client-server
applications, one "Installer" or "Manager" type application or process with
exclusive access will be run once to create the schema, and then a separate
application or process will be run to make use of it as a shared working space.

The second functionality type is the management (creation, modification,
deletion) of the data in a database, including such operations as: direct
selects from single or multiple tables or views, direct inserts or updates or
deletes of records, calling stored procedures, using sequences, managing
temporary tables, managing transactions, managing data integrity.  This type of
functionality typically is used frequently and comprises the main functionality
of your database-using application(s).  In some cases, typically with
public-accessible websites or services, all or most users will just be viewing
data and not changing anything; everyone would use the same database user and
they would not be prompted for passwords or other security credentials.  In
other cases, typically with private or restricted-access websites or services,
all or most users will also be changing data; everyone would have their own
real or application-simulated database user, whom they log in as with a
password or other credentials; as the application implements, these users can
have different activity privileges, and their actions can be audited.

The Rosetta framework can be considered a low-level service because it allows a
fine level of granularity or detail for the commands you can make of it and the
results you get back; you get a detailed level of control.  But it is not
low-level in the way that you would be entering any raw SQL, or even small
fragments of raw SQL; that is expressly avoided because it would expose
implementation details that aren't true on all databases.  Rather, this
framework provides the means for you to specify in an RDBMS-generic fashion
exactly what it is you want to happen, and your request is mapped to native or
emulated functionality for the actual RDBMS that is being used, to do the work.
 The implementation or mapping is different for each RDBMS being abstracted
away, and makes maximum use of that database's built-in functionality. 
Thereby, the Rosetta framework achieves the greatest performance possible while
still being 100% RDBMS-generic.

This differs from other database abstraction modules or frameworks that I am
aware of on CPAN, since the others tend to either work towards the
lowest-common-denominator database while emulating more complex functionality,
which is very slow, or more often they provide a much more limited number of
abstracted functions and expect you to do things manually (which is specific to
single databases or non-portable) with any other functionality you need.  With
many modules, even the abstracted functions tend to accept sql fragments as
part of their input, which in the broadest sense makes those non-portable as
well.  With my framework I am attempting the "holy grail" of maximum
portability with maximum features and maximum speed, which to my knowledge none
of the existing solutions on CPAN are doing, or would be able to do short of a
full rewrite.  This is largely why I am starting a new module framework rather 
than trying to help patch an existing solution; I believe a rewrite is needed.

The Rosetta framework is best used through its native interface (RNI), which
accepts and returns only atomic values (or multi-dimensional Perl data
structures containing them); no "parsing" or such analysis is done such as with
SQL statements.  The main reason is that this framework is intended primarily
for a data-driven application programming model, where the applications use a
"data dictionary" to control what work it is doing; the applications can simply
copy the composite scalar values of the data dictionary, without having to
encode them into a single string.  The RNI is designed to allow entry of a
non-ambiguous structured definition of any task that you would want a database
to do.  Rosetta is intended to support a superset of features from all common
generic RDBMS products, so it should have a native way of expressing any task
that you can do now.  For cases where you don't already have a data dictionary, 
Rosetta can scan your existing database to create one.

One would think that, despite all the advantages that Rosetta can bring to a
new application that is designed around RNI (or a simplifying wrapper of it),
it wouldn't be very helpful to an existing older application that is built
around "a different way of doing things".  From the latter perspective, there
looks to be just as much work involved in porting their application to use
Rosetta as there would be to port it to a new database or other interface
framework.  The problem would be the all-too-common having to "learn yet
another language", and then port the application to it (for that matter, it
would be a new language for new app builders as well, although that may not be
the same problem).  Either transition could be a significant cost and the
hurdle can deter upgrades to making apps portable.

But to help with this situation, Rosetta also includes several emulators (each
of which is a higher-level layer that translates its input into RNI calls) for
common existing database interfaces, so that most Perl applications can simply
use Rosetta as a hot-swappable replacement for them; you do not have to "learn
yet another language" or re-code your application in order for it to just work
with more databases.  It should be possible to emulate any existing interface,
and if a new one comes along with features that Rosetta can't handle (interface
to or implement), then this is a reasonable excuse to update the core so that
it is possible.  That said, the success of an emulator depends largely on
whether code that was using the original module is using the original the way
it was designed or not; code that was hacking the internals of a module (as
Perl makes so easy) is less likely to work (sort of like how an app used to
using un-documented APIs on an operating sytem, or doing direct OS data
structure access on a non-memory-protected OS, would break if the
implementation of that OS changed).

Included in the Rosetta distribution will be several applications which serve
as examples of Rosetta in use, but in some cases are useful themselves.  One
example will be a utility for copying one database to another, such as for
backup or restore, or just migration.  Another example will be a web app that
works sort of like "PHPMyAdmin" (letting users manually edit schema and data)
except that it is written in Perl, and it works with many RDBMS products.  Some
code porting utilities could also be available, to help makers of old
applications migrate to RNI, for better control and performance than an
emulator would provide.

=head1 SCHEDULE FOR DEVELOPMENT

In an effort to keep things simpler for development, the first few releases of
this distribution will contain some of the intended features, while others will
be left out for now, but be dealt with later at an appropriate time.  

This is the approximate order that I plan to support particular features:

=over 4

=item 0

Connect to (or open) an existing database as a registered or anonymous user,
which establishes a current working context for doing anything else, and close
it; multiple simultaneous connections should be supported; the database and
users must already exist.

=item 0

Create tables (including temporary) within the default schema context that you
connected to (eg: an Oracle "user/schema" in an "instance"), with nullability
or unique key (including primary key) or foreign key constraints or indexes
that are not constraints or default column values, and alter or remove or
validate them, assuming the connected user has said privileges; the same
operations will also be supported against neighbouring contexts (if any) for
which said user is permitted; note that Rosetta will not enforce any
constraints on tables as that is up to the RDBMS product, although it may try
to enforce some constraints in a far-away release for RDBMS products that don't
do it themselves, but that would be slower and less reliable.

=item 0

Start a transaction, which is an operating context within which all table data
changes must succeed or none will be saved, and end it either with a commit
(keep changes) or rollback (discard changes); this type of data integrity will
not work unless the RDBMS product being used supports transactions; far-off
releases of Rosetta may implement transactional data integrity at the Perl
level for non-supporting RDBMS products, but using a supporting RDBMS is
better; multiple simultaneous transactions within a single database connection
should be supported.

=item 0

Select data from single or related multiple tables, including the use of equal
or left outer joins, full and unique unions (similar to full outer joins),
derived tables (in sql-from), sub-selects (in sql-where), hierarchical queries
(eg: an Oracle start-with and connect-by), and including the use of
calculations or formulas (including logicals like choose-when) in the returned
column list or in the row filter or grouping conditions; the select results can
be accessed either with row cursors (memory efficient) or all at once with an
array (for small result sets only); also, insert or update or delete against
single tables.

=item 0

Obtain locks on table data for when you want atomic selects and updates, and
release them; the same caveats that apply to transaction support in the RDBMS
product being used also applies here.

=item 0

Create or alter or remove sequences within the default schema context, and use
them in table definitions or data modifying operations.

=item 0

Scan an existing database and create a data dictionary (as Perl objects) that
describes its tables and sequences, including any constraints that the database
knows about.

=item 0

Utilities for backing up or restoring the tables in a database, both schema and
data, either with another database or a set of text files.

=item 0

Create views, which are select queries whose definitions are stored in a
database for convenience and pre-processing speed, within the default schema
context that you connected to, and alter or remove them; validating views 
will at first only be possible if the same version of Rosetta created them, 
because it is done by a simple string compare for databases that store 
views as sql statements, so that the sql won't have to be parsed.

=item 0

Insert or update or delete against multiple related related tables at once, as
if they were a single table; the Rosetta objects that define the multiple table
selection will be used to know how to map said data changes against the correct
tables; it may not be possible for Rosetta to issue changes against some
selects, since some required mapping information may be lacking; in that case, 
the application logic will have to handle it against single tables.

=item 0

Create stored procedures and functions within the default schema context that
you connected to, and alter or remove them, and invoke them directly; initially
this feature will require you to define a separate version of a stored
procedure or function for each RDBMS product you are going to use, because it
is too difficult to implement an abstracted definition and generation of such
things for earlier Rosetta releases; there are two ways to do this, one of
which involves writing the functionality in pure Perl (which can be done once
for all RDBMS products, particularly those that don't support stored procedures
at all, but is slower), and the other way involves a hand-crafted SQL string
implementing the procedure plus a shim Perl function that calls it; your main
application is still RDBMS generic because any multiplicity of stored procedure
implementations will be keyed to a Rosetta driver, so the right one is used at
the right time; in any event, the standard RNI means of calling a stored
procedure is calling something that looks externally like a Perl function,
which won't change, so you will still have to make at least the interface in
Perl; also modify or delete them, or validate those added through Rosetta.

=item 0

Call stored functions within select queries and so forth; this would likely
only work when the stored item is actually in the database, and is not a pure 
Perl implementation.

=item 0

Create stored triggers, with the same caveats as stored procedures and
functions regarding multiplicity of implementations, or update or remove them,
or validate those added through Rosetta; initially this feature will not work
at all unless the underlying RDBMS supports triggers, since early Rosetta
releases will not interrupt or scan data UID operations to implement triggers
in Perl.

=item 0

Create or alter or remove "public synonyms" in Oracle or other RDBMS that 
support the concept of this convenient aliasing system.

=item 0

Create new users in the current database or remove them or alter their
privileges or validate any settings for user existence or privileges; note 
that Rosetta will not enforce user privileges or lacks of them for any 
RDBMS products that don't do this internally.

=item 0

Create new database instances or remove them, if that can be done easily.

=item 0

Also scan the views in an existing database and parse their definition sql so
that generated data dictionaries can describe both tables, views, and seqs.

=item 0

Also extract the stored procedures and functions and triggers and so forth 
in their raw form, unparsed, for backup or restore to the same kind of 
RDBMS that they came from.

=item 0

Emulate other database interfaces (like DBI or ODBC or OCI or whatever) on top
of Rosetta; this would require being able to parse SQL like for data selection
or modification, or table and view creation, and so forth, as well as pass
through unparsed the creation sql of stored procedures and functions and
triggers for use as is (latter not portable).

=item 0

Get around to parsing or generating sql for stored procedures or functions or 
triggers, and representing them abstractly for a data dictionary.

=item 0

Whatever else is needed.

=back

On databases that don't support sub-selects (eg: MySQL before 4.1.x) or unions
(eg: MySQL before 4.0.x) natively, Rosetta::Driver::* will try to
emulate complex select commands by creating temporary tables in the database to
hold results of inner selects.  This would keep all the implementation work
inside the RDBMS product where it should be, with only the final resulting
row-set being returned to the Perl application.  However, it is possible that
this will only work if the database user being connected as has the privileges
to create tables, which isn't always the case for DML-only users; on the other
hand, temporary tables may not require said permissions.  There may also be
problems with reliability of the results if someone else is modifying the
inputs for the temporary tables before they are all built; this may change
later when proper read locks are used.

=head1 SYNTAX

These classes do not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting any class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 STRUCTURE

The modules composing the Rosetta framework are grouped into several main
categories, which can be called: "Schema", "Engine", "Driver", "Parser",
"Emulator", and others.

The "Schema" and "Engine" modules are collectively referred to as the "Rosetta
Native Interface" or "RNI", and they are the "Core" of the Rosetta framework to
which all else is attached.  The distinction between the two is that Schema
modules are purely container objects which hold descriptions of "things" (such
as data types or tables or views), while Engine modules typically are not
containers and represent "actions" (such as connections or cursors).  Schema
objects are complete on their own and can be serialized or stored indefinately
off site for later retrieval and use, such as with a "data dictionary"
describing a table or view.  Engine objects only make sense within the context
where they were created and often contain time-sensitive data; it wouldn't make
sense to store them except during the short term, such as with a pool of active
and reusable database connections.  It is common for Engine objects to hold
Schema objects as properties, to help them know how to do their actions, such
as how to create a table or select from it.

The "Driver" and "Parser" and "Emulator" modules are each different kinds of
"Extensions" to Rosetta; each module in one of these groups is typically
specific to an RDBMS product, so you likely won't use more than a few at once.

The Driver modules are the most important since they are what handle (interface
to or implement) all the details of using a specific RDBMS product; you need at
least one for each unique RDBMS product you plan to run your application on;
they are "action" modules.  They take Engine/Schema objects as input and
convert them into the actual SQL or other method calls that the RDBMS products
use, then they invoke the generated, and then interpret the results into other
Engine/Schema objects to return as output.  The Driver modules also deal with
extracting any existing schema stored in an RDBMS so they can generate an RNI
data dictionary from it when desired.  Nothing talks to an RDBMS product except
a Driver module, and nothing talks to a driver module except the Engine
modules.  

The Parser modules are self-contained and serve to convert SQL statements from
known dialects into Engine/Schema objects; they may be used by Driver modules
when generating data dictionaries, but they definately are used by some
Emulator modules (those which take SQL input).

The Emulator modules are purely optional for use, and they are intended to
facilitate rapid adaption (hot-swapping) of Rosetta into an existing
application that is already built around a different database interface (such
as DBI or ODBC or OCI).  Each Emulator module is a higher-level layer which
translates its input into pure RNI calls and translates the output
correspondingly; each should have an identical public interface to what it
emulates.  So applications often won't need to be changed to use Rosetta, but
they still just become more portable.

This briefly (incompletely) illustrates the relationship of the module groups:

	        RDBMS
	          |
	          |
	          |
	        Driver
	called by | 
	          |
	  invokes | 
	        Engine--------------Schema
	called by |   uses   used by
	          |
	  invokes | 
	        Emulator------------Parser
	          |   uses   used by
	          |
	          |
	        APPLICATION

Note that "APPLICATION" would often be connected to "Engine" directly if an
Emulator isn't being used, or some other module may be between them.  Note that
"Schema" is often connected to everything else.  Other things were missing.

=head1 BRIEF MODULE LIST

Note that the exact module names and descriptions listed within each grouping
are an older draft and are subject to near-future revisions or rewrites,
including addition of more modules or removal of some existing ones.

	Rosetta (holds main framework documentation, for now)

	Rosetta::Schema (represents one database schema; owned by one database user)
	Rosetta::Schema::DataType (metadata for individual atomic or scalar values)
	Rosetta::Schema::Table (details of table columns are part of this class)
	Rosetta::Schema::DataSet (independent but used by View; a parsed select)
	Rosetta::Schema::View (not only stored views, but regular selects and other DML)
	Rosetta::Schema::Procedure (or Function)
	Rosetta::Schema::* ... like User, Trigger, Sequence, Package, whatever

	Rosetta::Engine (base class to provide 'execute' function; calls Drivers)
	Rosetta::Engine::Command (describes an action to do)
	Rosetta::Engine::Result (result of action including errors)
	Rosetta::Engine::Connection (represents a connection)
	Rosetta::Engine::Transaction (represents context within connection)
	Rosetta::Engine::Cursor (result of a selection command)
	Rosetta::Engine::* ... like DriverEngineGlobals or whatever

	Rosetta::Driver (base class to provide common public interface)
	Rosetta::Driver::ANSI-SQL-99 (base class for common implementation, uses DBI/DBD::*)
	Rosetta::Driver::MySQL-3-23 (generate and run SQL for MySQL 3.23.x)
	Rosetta::Driver::MySQL-4-0 (generate and run SQL for MySQL 4.0.x)
	Rosetta::Driver::MySQL-4-1 (generate and run SQL for MySQL 4.1.x)
	Rosetta::Driver::Oracle-8 (generate and run SQL for Oracle 8)
	Rosetta::Driver::Oracle-9 (generate and run SQL for Oracle 9)
	Rosetta::Driver::* ... like Sybase, DB2, PostgreSQL, SQLServer, Informix, more

	Rosetta::Parser::ANSI (base class for common implementation, uses ?)
	Rosetta::Parser::MySQL (parse SQL for MySQL into Schema/Engine objects)
	Rosetta::Parser::Oracle (parse SQL for Oracle into Schema/Engine objects)
	Rosetta::Parser::* ... like above database list and more
	
	Rosetta::Emulator::DBI (emulates DBI/DBD::*, but result is more portable)
	Rosetta::Emulator::ODBC (emulates an ODBC module, result more portable)
	Rosetta::Emulator::OCI (emulates an OCI module, result more portable)
	Rosetta::Emulator::* ... like some of the other abstraction modules
	Rosetta::Emulator::*::* (helpers for emulated frameworks of several modules)

	Rosetta::* ... who knows ...

	Rosetta::Util::* ... higher level functionality like: Backup, Restore, Copy, ...
	
	Rosetta::Adapter::* ... I like the name so it might be used for something
	
	RosettaX::* ... unofficial extensions or wrappers to Rosetta are allowed here ...

=head1 EXPANDED MODULE LIST

Note that the exact module names and descriptions listed within each grouping
are an older draft and are subject to near-future revisions or rewrites,
including addition of more modules or removal of some existing ones.

Note also that a bunch of summary documentation was dropped between release
0.01 and 0.02, since it was at least partly redundant with other additions in
0.02; the remaining parts should be brought back soon.

=head2 SCHEMA MODULES

=over 4

=item 0

B<Rosetta::Schema::DataType> - This Schema class describes a simple
data type, which serves as meta-data for a single scalar unit of data, or a
column whose members are all of the same data type, such as is in a regular
database table or in row-sets read from or to be written to one.  This class
would be used both when manipulating database schema and when manipulating
database data.

=item 0

B<Rosetta::Schema::Table> - This Schema class describes a single
database table, and would be used for such things as managing schema for the
table (eg: create, alter, destroy), and describing the table's "public
interface" so other functionality like views or various DML operations know how
to use the table. In its simplest sense, a Table object consists of a table
name, a list of table columns, a list of keys, a list of constraints, and a few
other implementation details.  This class does not describe anything that is
changed by DML activity, such as a count of stored records, or the current
values of sequences attached to columns.  This class can generate Command
objects having types of: 'table_verify', 'table_create', 'table_alter',
'table_destroy'.

=item 0

B<Rosetta::Schema::DataSet> - This Schema class is meta-data from which
DML command templates can be generated.  Conceptually, a DataSet looks like a
Table, since both represent or store a matrix of data, which has uniquely
identifiable columns, and rows which can be uniquely identifiable but may not
be.  But unlike a Table, a DataSet does not have a name.  In its simplest use,
a DataSet is an interface to a single database table, and its public interface
is identical to that of said table; this interface can be used to fetch or
modify data stored in the table.  This class can generate Command objects
having types of: 'data_select', 'data_insert', 'data_update', 'data_delete',
'data_lock', 'data_unlock'.  I<Note: this paragraph was a rough draft.>

=item 0

B<Rosetta::Schema::View> - This Schema class describes a single
database view, and would be used for such things as managing schema for the
view (eg: create, alter, destroy), and describing the view's "public interface"
(it looks like a table, with columns and rows) so other functionality like
various DML operations or other views know how to use the view.  Conceptually
speaking, a database view is an abstracted interface to one or more database
tables which are related to each other in a specific way; a view has its own
name and can generally be used like a table.  A View object has only two
properties, which are a name and a DataSet object; put another way, a View
object simply associates a name with a DataSet object.  This class does not
describe anything that is changed by DML activity, such as a count of stored
records, or the current values of sequences attached to columns.  This class
can generate Command objects having types of: 'view_verify', 'view_create',
'view_alter', 'view_destroy'.

=back

=head2 ENGINE MODULES

=over 4

=item 0

B<Rosetta::Engine> - This Engine class is inherited by all other Engine
Engine classes, and it provides functionality to talk to or manage Driver modules.
Its main task is to define the execute_command() method, which takes a Command
object saying what should be done next and returns or throws a Result object
saying what actually was done (or what errors there were).  For some command
types, execute_command() may only start the process that needs doing (eg: get a
select cursor), and invoking execute_command() again on the Result object
(which is a subclass) will continue or finish the process (eg: fetch a row). 
Instantiated by itself, this class stores globals that are shared by all
drivers or connections.  Subclasses include: Result, Connection.

=item 0

B<Rosetta::Engine::Command> - This Schema class describes an action
that needs to be done against a database; the action may include several steps,
and all of them must be done when executing the Command.  A Command object has
one mandatory string property named 'type' (eg: 'database_connect',
'table_create', 'data_insert'), which sets the context for all of its other
properties, which are in a hash property named 'args'.  Elements of 'args' 
often include other Engine class objects like 'Table' or 'DataType'.

=item 0

B<Rosetta::Engine::Result> - This Engine class is inherited by all Engine
classes that would be returned from or thrown by an execute_command() method,
and it contains the return values or errors of a Command.  Its main task is to
implement the is_error() and get_error() methods, which say whether the Command
failed or not, and if so then why.  Some commands (eg: 'database_disconnect')
have no other meta-data or data to return, while others do (eg: 'data_select').  
Subclasses include: Connection.

=item 0

B<Rosetta::Engine::Connection> - This Engine class represents a connection
to a database instance, and the simplest database applications use only one.
You instantiate a Connection object by executing a Command of type
'database_connect'; that command usually takes 4 arguments, the first of which
is mandatory: 'driver' is a string having the name of the Driver module to use,
which also defines what RDBMS product is being used; 'server' is the name of
the specific database instance to use; 'user' is the username to authenticate
yourself against a multi-user database as; 'pass' is the associated password.

=item 0

B<Rosetta::Engine::Cursor> - This Engine class represents a cursor over a
rowset that is being selected from a database.  You instantiate a Cursor object
by executing a command of type 'data_select'; that command usually takes 1
argument, which is mandatory: 'view' is a View object that describes the select
statement being run, including what columns it has and their datatypes, what
the source tables are, how they are joined, what the row filters are, sort
order, and row limiting or paging.  

=back

=head2 DRIVER MODULES

=over 4

=item 0

B<Rosetta::Driver> - This class defines the specific public API that all
Driver classes must have, which is what the appropriate Engine classes will call
them with; it is an error condition if you pass a module as a driver and that
module doesn't subclass this one; also, do not instantiate this class directly,
as it doesn't implement the methods it declares.

=item 0

B<Rosetta::Driver::ANSI-SQL-99> - This class implements most Driver methods using
SQL that is compliant to the ANSI SQL standard.  It is not intended to be used
by itself, but rather subclassed by another Driver module for a specific RDBMS
product.  This class assumes that DBI and DBD::* modules will be used for
implementation, so it uses DBI objects and methods internally.  It currently
does not implement the 'database_connect' command because subclasses should be
choosing which DBD::* module to use internally.

=item 0

B<Rosetta::Driver::MySQL-3-23> - This class implements a driver for
talking to MySQL 3.23.x databases.  This version of MySQL does not support most
kinds of sub-selects and unions, so this driver emulates that functionality by
creating temporary tables; you can only use those features if you connect as a
user with privileges to make temporary tables.  Note that 3.23.54 is the latest
release and is considered production-quality (stable) since 2001.01.22.

=item 0

B<Rosetta::Driver::MySQL-4-0> - This class implements a driver for talking
to MySQL 4.0.x databases.  This version of MySQL does not support most kinds of
sub-selects, so this driver emulates that functionality by creating temporary
tables; you can only use those features if you connect as a user with
privileges to make temporary tables.  Note that 4.0.7 is the latest release and
is considered gamma-quality (soon to be stable?).

=item 0

B<Rosetta::Driver::MySQL-4-1> - This class implements a driver for talking
to MySQL 4.1.x databases.  This version of MySQL does support most kinds of
sub-selects and unions, so this driver does not need to emulate them, and you
can use these features even when you connect as a user that can not create
temporary tables.  Note that 4.1.0 is the latest release and is considered
alpha-quality (perhaps stable in a year?).

=item 0

B<Rosetta::Driver::Oracle-8> - This class implements a driver for talking
to Oracle 8.x databases.

=item 0

B<Rosetta::Driver::Oracle-9> - This class implements a driver for talking
to Oracle 9.x databases.  Note that Oracle 9 is the first version of the Oracle 
database that runs under Mac OS X (10.2 and later).

=back

All other databases in common use should be supported as well; the ones in the
above module list are vendors that I have used personally; I need to research
others to know what versions exist or are stable or are in common use.  Other
RDBMS products include: Sybase, PostgreSQL, DB2, SQL-Server, OpenBase,
FrontBase, Valentina, Informix, ODBC, and others.

=head2 MISCELLANEOUS MODULES FROM AFAR

In this context, "Wrapper" is a type of Rosetta extension that sits between 
the application and the RNI, such as Emulators.  But Wrappers take many forms, 
most of which will not be included with this distribution.

One form of Wrapper is a value-added extension, possibly more
application-specific, such as an interpreter for data dictionaries.  For
example, a data dictionary could say that an application is composed of screens
or forms that are related in a certain way; each screen would contain several
controls of various types, and some controls may correspond to specific columns
in database tables. The module in question would determine from the data
dictionary what needs to be retrieved from the database to support a particular
screen, and ask the Engine modules to go get it.  Similarly, if the application
user edits data on the screens that should then be saved back to the database,
the Wrapper module would ask the Engine modules to save it. On the other side of
things, it is quite possible that the data dictionary for the application is
itself stored in the database, and so the Engine modules can be asked to fetch
portions of it as the Wrapper module requires.

Another form of Wrapper is an interface customizer or simplifier.  if you know
that certain details of your commands to Engine will always be the same, or you
just like to express your needs in a different way, you can take care of the
default values in a wrapper module, so that the rest of your application simply
has to provide inputs that aren't always the same.

Another form of Wrapper is a data parser or serializer.  For example, to convert
database output to XML or convert XML to a database command (although, certain
kinds of XML processing may be better implemented in the Engine/Driver layers for
performance reasons, but if so it would still be an extension).

Another form of Wrapper is a command parser for various SQL dialects.  For
example, if you want to quickly port an application, which already includes SQL
statements that are tailored to a specific database product, to a different
database for which it is incompatible, a Wrapper module could parse that statement
into the object representation that Engine uses.  This is effectively an
SQL-to-SQL translator.  I would expect that, citing reasons of performance or
application code simplicity, one wouldn't want to use this functionality
long-term, but replace the SQL with Engine object definitions later.

Finally, one could also make Wrappers which emulate other database abstraction
solutions for similar reasons to the above, which is a different type of quick
porting.  Since the intended feature set of Rosetta should be a superset
of existing solutions' feature sets, it should be possible to emulate them with
it.  

=head1 ROSETTA NATIVE DATA DICTIONARY STRUCTURE

All concepts in the Rosetta Core, mainly those represented by the Schema
modules, but to a lesser extent the Engine modules, can be represented by a
data dictionary; such a data dictionary can be a linked in-memory set of
objects (or serialized version thereof), or they can be represented by records
in database tables having specific columns and constraints.  This documentation
will attempt to explain the components of a Rosetta data dictionary and how
they relate; it is hierarchical-relational in design, and each component is
expressed in terms of other components or atomic values like strings or
numbers.  For simplicity of syntax, this documentation will pretend to describe
command or expression strings that are loosely similar to SQL, even if what
they represent is not intended to be used in a serialized form.

Here is a brief legend of syntax used here; it isn't perfect:

	:= - means name on left is defined by expression on the right
	TEXT - represents literal text (literal in serialized form anyway)
	<text> - represents a named component that is defined near-by
	() - represents a grouping or boundary of portions used together
	| - an exclusive-or meaning to use either portion on left or on right
	{n,n} - means allowed number of repetitions of on left (delimited by commas)
	[] - represents an optional portion
	# - start of a line comment
	... definition is described by comment rather than given normally

Here are the component definitions, not quite complete:

	<database> := DATABASE 
		HAS (<namespace>{0,})
	
	<namespace> := NAMESPACE 
		ID (<entity-id>) 
		HIERARCHY (<entity-id>{0,2})  # eg: Oracle user/schema name, db instance name
		HAS (<schema-object>{0,})
	
	<entity-id> := ...  # scalar value: either an alphanumeric string or an integer
	
	<schema-object> := (<table>|<view>|<sequence>|<procedure>|<trigger>)
	
	<table> := TABLE 
		ID (<table-id>)
		INTERFACE (<column-declaration>{1,})
		CONSTRAINT (<column-constraint>{0,})  # refers to columns in same table only
		DEFAULT (<column-default>{0,})  # refers to columns in same table only

	<table-id> := <entity-id>

	<column-declaration> := COLUMN 
		ID (<column-id>) 
		TYPE (<data-type>)
	
	<column-id> := <entity-id>

	<data-type> := 
		[NAME (<entity-id>)]
		BASE (<base-type>)
		[SIZE (<data-size>)]

	<base-type> := (boolean|int|float|datetime|str|binary)

	<data-size> := ...  # an integer; if not given, has default val based on <base-type>

	<column-constraint> := (<is-req>|<unique-key>|<foreign-key>)
	
	<is-req> := REQUIRED (<column-id>)  # results in NOT NULL if set; NULL if not
	
	<unique-key> := UNIQUE 
		ID (<entity-name>)
		HAS (<column-id>{1,})
	
	<foreign-key> := FOREIGN 
		ID (<entity-name>)
		HAS (<column-id>{1,})
		SOURCE TABLE (<table-name>)
		SOURCE COLS (<column-id>{1,})
	
	<column-default> := ((LITERAL (<literal-value>))|(SEQUENCE (<sequence-value>)))
	
	<literal-value> :=  # any string or numerical value
	
	<sequence-value> := ...  # not defined yet
	
	<view> := VIEW
		ID (<entity-id>)
		IS (<select>)
	
	<select> := SELECT
		INTERFACE (<column-declaration>{1,})
		FROM (<select-from>)
	
	<select-from> := (<literal-row>|<source-union>|<source-table>|<source-join>)
	
	<literal-row> := LITERAL ((<column-id> IS <literal-value>){1,})
	
	<source-union> := UNION (<select-from>{1,})  # members are selects with same interface
	
	<source-table> := TABLE 
		ID (<table-id>)
		IMPLEMENTATION ((<column-declaration> IS <fomula-node>){1,})
		[WHERE (<formula-node>)]  # formula-node must return a boolean value
		[GROUP (<column-declaration>{1,})]  # to expand with formulas
		[ORDER (<column-declaration>{1,})]  # to expand with formulas
	
	<formula-node> := ((LITERAL <literal-value>)|(COLUMN <column-declaration>)|<formula>)
		
	<formula> :=
		TYPE (<formula-type>)
		[ARGS (<formula-node>{1,})]  # required when arg-count is greater than zero

	<formula-type> := 
		NAME (<formula-name>) 
		RETURNS (<data-type>)
		[ARG COUNT (<arg-count>)]

	<formula-name> := (if|switch|and|or|add|mult|concat|substr|to_date|to_str|...)

	<arg-count> := ...  # an integer; if not given, has default of infinity

	<source-join> := JOIN
		SOURCE ((<alias-id> IS <table-id>){1,})  # to expand with sub-selects
		RELATION (<join-relation>{0,})  # refers to alias-id in SOURCE
		IMPLEMENTATION ((<column-declaration> IS <fomula-node>){1,})  # col ids are for aliases
		[WHERE (<formula-node>)]  # formula-node must return a boolean value
		[GROUP (<column-declaration>{1,})]  # to expand with formulas
		[ORDER (<column-declaration>{1,})]  # to expand with formulas
	
	<alias-id> := <entity-id>
	
	<join-relation> := RELATION
		TYPE (equal|left)
		LHS TABLE (<alias-id>)
		LHS COLUMN (<column-id>)  # to adjust to work with alias-specific column-ids
		LHS TABLE (<alias-id>)
		LHS COLUMN (<column-id>)  # to adjust to work with alias-specific column-ids
	
	<sequence> := ...  # not defined yet
	
	<procedure> := ...  # not defined yet

	<trigger> := ...  # not defined yet

=head1 A BASIC TABLE STRUCTURE FOR STORING ROSETTA SCHEMAS

This stuff is an older draft of the previous section, in a way.

	data_type
		data_type (string)
		base_type (eg: boolean, int, float, datetime, str, binary)
		size (in bytes for most types, in chars for strs)
		store_fixed (boolean, true like 'char', false like 'varchar')

	calc_type (used in both select column definitions and where clauses)
		calc_type (means 'function name'; eg: sum, concat, and, or, ifnull, switch/choose/decode)
		data_type -> data_type (for function output)
		arg_count (int; number of function inputs; null means open-ended, like for 'concat')
	
	matrix (interface)
		matrix_id
		is_table (means 'is named', 'is stored in rdbms', 'has constraints', 'is not select or view')
		is_view (means 'is named', 'is actually or conceptually stored in rdbms','is join or union')
		is_union (means 'each column from one or more sources', 'each row from exactly one source')
		is_hierarchy (like a union, rows exactly one source, related by n-levels of self-relations)
		is_join (means 'each column from exactly one source', 'each row from one or more sources')
		is_unique (means 'is distinct' or 'group by all cols' or 'no two rows ident for every col')
		seq_num (if necessary)
	
	matrix_col (interface)
		matrix_col_id
		matrix_id -> matrix
		col_name
		data_type -> data_type
		default_val (null by default, stored on unspec insert, ret in view when col not 'impemented')
		seq_num (if necessary)
	schema
		schema_name
	
	matrix_stored (used when 'is table' or 'is view')
		matrix_id -> matrix
		schema_name -> schema
		matrix_name (either table name or view name or some temporary unique thing)
		
	matrix_stored_col (used when 'is table')
		matrix_col_id -> matrix_col
		is_req (means 'is not null')
	
	matrix_union (used when 'is union')
		matrix_id -> matrix (output/parent)
		source_id -> matrix (input/child)
		seq_num (if necessary)
	
	matrix_hierarchy (used when 'is hierarchy'; may need split if multi cols in relation)
		matrix_id -> matrix (output/parent)
		self_col_id -> matrix_col (eg: the primary key)
		parent_col_id -> matrix_col (eg: the primary key of the parent record)
	
	matrix_join_src (used when 'is join')
		matrix_id -> matrix (output/parent)
		source_alias (name to use in 'from matrix_name as alias_name'
		source_id -> matrix (input/child)
		seq_num (if necessary)
	
	matrix_join_rel (used when 'is join' and more than one matrix_join_src)
		matrix_id -> matrix (output/parent)
		is_equal_join (means 'is not left join' and 'is not outer join')
		is_left_join (means 'is not equal join' or 'is outer join?')
		lhs_src_alias -> matrix_join_src (all rows are returned on left join)
		rhs_src_alias -> matrix_join_src (rows may be missing on left join)
	
	matrix_calc_node (used when not 'is table')
		calc_id
		matrix_id -> matrix (used by node tree that is in)
		calc_type -> calc_type (says ret data type, leaf or not, or function vs col vs literal)
		parent_calc_id -> matrix_calc_node (null if self is a root node, set if self is arg)
		source_alias_name -> matrix_join_src (set if leaf, retval from col and not literal)
		source_col_id -> matrix_col (set if leaf, retval from col and not literal)
		literal_value (set if leaf, retval is literal and not col)
	
	matrix_view_col (used when not 'is table')
		matrix_col_id -> matrix_col (used in)
		matrix_calc -> matrix_calc_node (root node of column calculation tree)
	
	matrix_where (used when not 'is table')
		matrix_id -> matrix (used in)
		matrix_calc -> matrix_calc_node (root node of where-clause calc tree; must return boolean)

=head1 ANOTHER WAY OF SAYING THAT

This stuff is an older draft of the previous section, in a way.

	schema
		cols
			schema_name - type=entitynm; req=1; ukey=primary
	
	table
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			table_name - type=entitynm; req=1; ukey=primary
		fkeys
			fk_schema - table=schema; cols=schema_name
	
	table_col
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			table_name - type=entitynm; req=1; ukey=primary
			table_col - type=entitynm; req=1; ukey=primary
			data_type - type=entitynm; req=1
			is_req - type=boolean
			default_val - type=generic
			auto_inc - type=boolean
		fkeys
			fk_table - table=table; cols=schema_name,table_name
			fk_data_type - table=data_type; cols=data_type 
	
	table_ukey
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			table_name - type=entitynm; req=1; ukey=primary
			ukey_name - type=entitynm; req=1; ukey=primary
		fkeys
			fk_table - table=table; cols=schema_name,table_name
	
	table_ukey_col
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			table_name - type=entitynm; req=1; ukey=primary
			ukey_name - type=entitynm; req=1; ukey=primary
			table_col - type=entitynm; req=1; ukey=primary
		fkeys
			fk_table_ukey - table=table_ukey; cols=schema_name,table_name,ukey_name
			fk_table_col - table=table_col; cols=schema_name,table_name,table_col
	
	table_fkey
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			table_name - type=entitynm; req=1; ukey=primary
			fkey_name - type=entitynm; req=1; ukey=primary
			f_schema_name - type=entitynm; req=1
			f_table_name - type=entitynm; req=1
		fkeys
			fk_table - table=table; cols=schema_name,table_name
			fk_f_table - table=table; cols=f_schema_name(schema_name),f_table_name(table_name)
	
	table_fkey_col
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			table_name - type=entitynm; req=1; ukey=primary
			fkey_name - type=entitynm; req=1; ukey=primary
			table_col - type=entitynm; req=1; ukey=primary
			f_schema_name - type=entitynm; req=1
			f_table_name - type=entitynm; req=1
			f_table_col - type=entitynm; req=1
		fkeys
			fk_table_fkey - table=table_fkey; cols=schema_name,table_name,fkey_name
			fk_table_col - table=table_col; cols=schema_name,table_name,table_col
			fk_f_table_col - table=table_col; cols=f_schema_name(schema_name),f_table_name(table_name),f_table_col(table_col)

	view - represents one select statement (main or sub) or stored view
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			view_name - type=entitynm; req=1; ukey=primary
			join_type - type=boolean
			union_type - type=boolean
		fkeys
			fk_schema - table=schema; cols=schema_name
			fk_join_type - table=join_type; cols=join_type
			fk_union_type - table=union_type; cols=union_type
	
	view_col - desc column set of result; in case of unions, describes output of all source subselects or tables
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			view_name - type=entitynm; req=1; ukey=primary
			view_col - type=entitynm; req=1; ukey=primary
		fkeys
			fk_view - table=view; cols=schema_name,view_name
	
	view_src - for subselects or tables in joins or unions or where_condition
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			view_name - type=entitynm; req=1; ukey=primary
			src_name - type=entitynm; req=1; ukey=primary
			s_schema_name - type=entitynm
			s_table_name - type=entitynm
			s_view_name - type=entitynm
		fkeys
			fk_view - table=view; cols=schema_name,view_name
			fk_s_table - table=table; cols=s_schema_name(schema_name),s_table_name(table_name)
			fk_s_view - table=view; cols=s_schema_name(schema_name),s_view_name(view_name)
	
	view_src_col - for subselects or tables in joins or unions or where_condition
		cols
			schema_name - type=entitynm; req=1; ukey=primary
			view_name - type=entitynm; req=1; ukey=primary
			src_name - type=entitynm; req=1; ukey=primary
			view_col - type=entitynm; req=1; ukey=primary
			s_schema_name - type=entitynm
			s_table_name - type=entitynm
			s_table_col - type=entitynm
			s_view_name - type=entitynm
			s_view_col - type=entitynm
		fkeys
			fk_view_src - table=view_src; cols=schema_name,view_name,src_name
			fk_view_col - table=view_col; cols=schema_name,view_name,view_col
			fk_s_table_col - table=table_col; cols=s_schema_name(schema_name),s_table_name(table_name),s_table_col(table_col)
			fk_s_view_col - table=view_col; cols=s_schema_name(schema_name),s_view_name(view_name),s_view_col(view_col)

	view_col_def
		cols
			col_def_id - type=int; req=1; ukey=primary; default=1; auto_inc=1
			calc_type - type=entitynm; req=1 - eg: am scalar value or am view column or am func with args; data_type of output
			parent_col_def_id - type=int - set if am arg for another view_col_def which is a func; am not root
			def_schema_name - type=entitynm - set if am not an arg for a view_col_def; am root
			def_view_name - type=entitynm - set if am not an arg for a view_col_def; am root
			def_view_col - type=entitynm - set if am not an arg for a view_col_def; am root
			col_schema_name - type=entitynm - opt 1 for here-value
			col_view_name - type=entitynm - opt 1 for here-value
			col_src_name - type=entitynm - opt 1 for here-value
			literal_value - type=generic - opt 2 for here-value
		fkeys
			fk_calc_type - table=calc_type; cols=calc_type
			fk_parent - table=view_col_def; cols=parent_col_def_id(col_def_id)
			fk_def_view_col - table=view_col; cols=def_schema_name(schema_name),def_view_name(view_name),def_view_col(view_col)
			fk_def_view_col - table=view_src_col; cols=col_schema_name(schema_name),col_view_name(view_name),col_src_name(src_name)
	
	view_join_def - not needed for unions; used with joins

	view_filter_def - not needed for unions (subquery does it); used with joins

	view_grouping_def - not needed for unions (subquery does it); used with joins

	view_ordering_def - not needed for unions (subquery does it if necessary); used with joins
	
	... um ... stuff ...

=head1 MODULE DETAILS

Below is some more detailed documentation for a few classes, as they have been 
written.  These are by no means complete and are subject to change.

=head2 Rosetta::Schema::DataType

This Schema module is a Schema class that describes a simple data type, which
serves as meta-data for a single scalar unit of data, or a column whose members
are all of the same data type, such as is in a regular database table or in
row-sets read from or to be written to one.  This class would be used both when
manipulating database schema and when manipulating database data.  

Here is some sample code for defining common data types with this class:

	my %data_types = map { 
			( $_->{name}, Rosetta::Schema::DataType->new( $_ ) ) 
			} (
		{ 'name' => 'boolean', 'base_type' => 'boolean', },
		{ 'name' => 'byte' , 'base_type' => 'int', 'size' => 1, }, #  3 digits
		{ 'name' => 'short', 'base_type' => 'int', 'size' => 2, }, #  5 digits
		{ 'name' => 'int'  , 'base_type' => 'int', 'size' => 4, }, # 10 digits
		{ 'name' => 'long' , 'base_type' => 'int', 'size' => 8, }, # 19 digits
		{ 'name' => 'float' , 'base_type' => 'float', 'size' => 4, },
		{ 'name' => 'double', 'base_type' => 'float', 'size' => 8, },
		{ 'name' => 'datetime', 'base_type' => 'datetime', },
		{ 'name' => 'str4' , 'base_type' => 'str', 'size' =>  4, 'store_fixed' => 1, },
		{ 'name' => 'str10', 'base_type' => 'str', 'size' => 10, 'store_fixed' => 1, },
		{ 'name' => 'str30', 'base_type' => 'str', 'size' =>    30, },
		{ 'name' => 'str2k', 'base_type' => 'str', 'size' => 2_000, },
		{ 'name' => 'bin1k' , 'base_type' => 'binary', 'size' =>  1_000, },
		{ 'name' => 'bin32k', 'base_type' => 'binary', 'size' => 32_000, },
	);

These are the main class properties:

=over 4

=item 0

B<name> - This mandatory string property is a convenience for calling code or
users to easily know when multiple pieces of data are of the same type.  Its
main programatic use is for hashing DataType objects.  That is, if the same
data type is used in many places, and those places don't want to have their own
DataType objects or share references to one, they can store the 'name' string
instead, and separately have a single DataType object in a hash to lookup when
the string is encountered in processing.  Only the other class properties are
what the Driver modules actually use when mapping the Schema data types to native
RDBMS product data types.  This property is case-sensitive.

=item 0

B<base_type> - This mandatory string property is the starting point for Driver
modules to map this data type to a native RDBMS product data type.  It is
limited to a pre-defined set of values which are what any Rosetta
modules should know about: 'boolean', 'int', 'float', 'datetime', 'str',
'binary'.  More base types could be added later, but it should be possible to
define what you want by setting other appropriate class properties along with
one of the above base types.  This property is set case-insensitive but it is
stored and returned in lower-case.

=item 0

B<size> - This integer property is recommended for use with all base_type
values except 'boolean' and 'datetime', for which it has no effect.  With the
base types of 'int' and 'float', it is the fixed size in bytes used to store a
numerical data, which also determines the maximum storable number.  With the
'binary' base_type, it is the maximum size in bytes that can be stored, but the
actual size is only as large as the binary data being stored.  With the 'str'
base_type, it is the maximum size in characters that can be stored, but the
actual size is only as large as the string data being stored; however, if the
boolean property 'store_fixed' is true then a fixed size of characters is
always allocated even if it isn't filled, where possible.  If 'size' is not
defined then it will default to 4 for 'int' and 'float', and to 250 for 'str'
and 'binary'.  This behaviour may be changed to default to the largest value
possible for the base data type in question, but that wasn't done because the
maximum varies based on the implementing RDBMS product, and maximum may not be 
what is usually desired.

=item 0

B<store_fixed> - This boolean property is optional for use with the 'str'
base_type, and it has no effect for the other base types.  While string data is
by default stored in a flexible and space-saving format (like 'varchar'), if
this property is true, then the Driver modules will attempt to map to a fixed
size type instead (like 'char') for storage.  With most database products,
fixed-size storage is only applicable to fields with smaller size limits, such
as 255 or less.  Setting this property won't necessarily change what value is
stored or retrieved, but with some products the returned values may be padded
with spaces.

=back

Other class properties may be added in the future where appropriate.  Some such
properties can describe constraints that would apply to all data of this type,
such as that it must match the format of a telephone number or postal code or
ip address, or it has to be one of a specific set of pre-defined (not looked up
in an external list) values; however, this functionality may be too advanced to
do until later, or would be implemented elsewhere.  Other possible properties
might be 'hints' for certain Drivers to use an esoteric native data type for
greater efficiency or compatability. This class would be used both when
manipulating database schema and when manipulating database data.
	
=head2 Rosetta::Schema::Table

This Schema module is a Schema class that describes a single database table,
and would be used for such things as managing schema for the table (eg: create,
alter, destroy), and describing the table's "public interface" so other
functionality like views or various DML operations know how to use the table.
In its simplest sense, a Table object consists of a table name, a list of table
columns, a list of keys, a list of constraints, and a few other implementation
details.  This class does not describe anything that is changed by DML
activity, such as a count of stored records, or the current values of sequences
attached to columns.  This class can generate Command objects having types of: 
'table_verify', 'table_create', 'table_alter', 'table_destroy'.

Here is sample code for defining a few tables with this class:

	my %table_info = map { 
			( $_->{name}, Rosetta::Schema::Table->new( $_ ) ) 
			} (
		{
			'name' => 'user_auth',
			'column_list' => [
				{
					'name' => 'user_id', 'data_type' => 'int', 'is_req' => 1,
					'default_val' => 1, 'auto_inc' => 1,
				},
				{ 'name' => 'login_name'   , 'data_type' => 'str20'  , 'is_req' => 1, },
				{ 'name' => 'login_pass'   , 'data_type' => 'str20'  , 'is_req' => 1, },
				{ 'name' => 'private_name' , 'data_type' => 'str100' , 'is_req' => 1, },
				{ 'name' => 'private_email', 'data_type' => 'str100' , 'is_req' => 1, },
				{ 'name' => 'may_login'    , 'data_type' => 'boolean', 'is_req' => 1, },
				{ 
					'name' => 'max_sessions', 'data_type' => 'byte', 'is_req' => 1, 
					'default_val' => 3, 
				},
			],
			'unique_key_list' => [
				{ 'name' => 'PRIMARY'         , 'column_list' => [ 'user_id'      , ], },
				{ 'name' => 'sk_login_name'   , 'column_list' => [ 'login_name'   , ], },
				{ 'name' => 'sk_private_email', 'column_list' => [ 'private_email', ], },
			],
			'primary_key' => 'PRIMARY', # from unique keys list, others are surrogate
		},
		{
			'name' => 'user_profile',
			'column_list' => [
				{ 'name' => 'user_id'     , 'data_type' => 'int'   , 'is_req' => 1, },
				{ 'name' => 'public_name' , 'data_type' => 'str250', 'is_req' => 1, },
				{ 'name' => 'public_email', 'data_type' => 'str250', 'is_req' => 0, },
				{ 'name' => 'web_url'     , 'data_type' => 'str250', 'is_req' => 0, },
				{ 'name' => 'contact_net' , 'data_type' => 'str250', 'is_req' => 0, },
				{ 'name' => 'contact_phy' , 'data_type' => 'str250', 'is_req' => 0, },
				{ 'name' => 'bio'         , 'data_type' => 'str250', 'is_req' => 0, },
				{ 'name' => 'plan'        , 'data_type' => 'str250', 'is_req' => 0, },
				{ 'name' => 'comments'    , 'data_type' => 'str250', 'is_req' => 0, },
			],
			'unique_key_list' => [
				{ 'name' => 'PRIMARY'       , 'column_list' => [ 'user_id'    , ], },
				{ 'name' => 'sk_public_name', 'column_list' => [ 'public_name', ], },
			],
			'primary_key' => 'PRIMARY', # from unique keys list, others are surrogate
			'foreign_key_list => [
				{ 
					'name' => 'fk_user',
					'foreign_table' => 'user_auth',
					'column_list' => [ 
						{ 'name' => 'user_id', 'foreign_column' => 'user_id' },
					], 
				},
			],
		},
		{
			'name' => 'user_pref',
			'column_list' => [
				{ 'name' => 'user_id'   , 'data_type' => 'int'     , 'is_req' => 1, },
				{ 'name' => 'pref_name' , 'data_type' => 'entitynm', 'is_req' => 1, },
				{ 'name' => 'pref_value', 'data_type' => 'generic' , 'is_req' => 0, },
			],
			'unique_key_list' => [
				{ 'name' => 'PRIMARY', 'column_list' => [ 'user_id', 'pref_name', ], },
			],
			'primary_key' => 'PRIMARY', # from unique keys list, others are surrogate
			'foreign_key_list => [
				{ 
					'name' => 'fk_user',
					'foreign_table' => 'user_auth',
					'column_list' => [ 
						{ 'name' => 'user_id', 'foreign_column' => 'user_id' },
					], 
				},
			],
		},
		{
			'name' => 'person',
			'column_list' => [
				{
					'name' => 'person_id', 'data_type' => 'int', 'is_req' => 1,
					'default_val' => 1, 'auto_inc' => 1,
				},
				{ 'name' => 'alternate_id', 'data_type' => 'str20' , 'is_req' => 0, },
				{ 'name' => 'name'        , 'data_type' => 'str100', 'is_req' => 1, },
				{ 'name' => 'sex'         , 'data_type' => 'str1'  , 'is_req' => 0, },
				{ 'name' => 'father_id'   , 'data_type' => 'int'   , 'is_req' => 0, },
				{ 'name' => 'mother_id'   , 'data_type' => 'int'   , 'is_req' => 0, },
			],
			'unique_key_list' => [
				{ 'name' => 'PRIMARY'        , 'column_list' => [ 'person_id'   , ], },
				{ 'name' => 'sk_alternate_id', 'column_list' => [ 'alternate_id', ], },
			],
			'primary_key' => 'PRIMARY', # from unique keys list, others are surrogate
			'foreign_key_list => [
				{ 
					'name' => 'fk_father',
					'foreign_table' => 'person',
					'column_list' => [ 
						{ 'name' => 'father_id', 'foreign_column' => 'person_id' },
					], 
				},
				{ 
					'name' => 'fk_mother',
					'foreign_table' => 'person',
					'column_list' => [ 
						{ 'name' => 'mother_id', 'foreign_column' => 'person_id' },
					], 
				},
			],
		},
	);

These are the main class properties:

=over 4

=item 0

B<name> - This mandatory string property is a unique identifier for this table 
within a single database, or within a single schema in a multiple-schema 
database.  This property is case-sensitive so it works with database products 
that have case-sensitive schema (eg: MySQL), but it is still a good idea to 
never name your tables such that they would conflict if case-insensitive, so 
that the right thing can happen with a case-insensitive database product 
(eg: Oracle in standard usage).

=item 0

B<column_list> - This mandatory array property is a list of the column
definitions that constitute this table.  Each array element is a hash (or
pseudo-object) having these properties:

=over 4

=item 0

B<name> - This mandatory string property is a unique identifier for this column
within the table currently being defined.  It has the same case-sensitivity
rules governing the table name itself.

=item 0

B<data_type> - This mandatory property is either a DataType object or a string
having the name of a DataType object, which can be used to lookup said object
that was defined somewhere else but near-by.  It is case-sensitive.

=item 0

B<is_req> - This boolean property is optional but recommended; if not
explicitely set, it will default to false, unless the column has been marked as
part of a unique key, in which case it will default to true.  If this property
is true, then the column will require a value, and any DML operations that try
to set the column to null will fail.  (A true value is like 'not null' and a
false value is like 'null'.)

=item 0

B<default_val> - This scalar property is optional and if set its value must be
something that is valid for the data type of this column.  The current
behaviour for what would happen if it isn't is undefined.

=item 0

B<auto_inc> - This boolean property is optional for use when the base_type of
this column's data type is 'int', and it has no effect for the other base types
(but support for other base types may be added).  If this property is true,
then the Driver modules will attempt to mark this column as auto-incrementing;
its value will be set from a special table-specific numerical sequence that
increments by 1.  This property may be replaced with a different feature.

=back

=item 0

B<unique_key_list> - This array property is a list of the unique keys (or keys
or unique constraints) that apply to this table.  Each array element is a hash
(or pseudo-object) for describing a single key and has these properties:
'name', 'column_list'.  The 'name' property is a mandatory string and is a
unique identifier for this key within the table; it has the same
case-sensitivity rules governing table and column names.  The 'column_list'
property is an array with at least one element; each element is a string that
must match the name of a column declared in this table.  A key can be composed 
of one or more columns, and more than one key may use the same column.

=item 0

B<primary_key> - This string property is optional and if it is set then it must
match the 'name' of an 'unique_key_list' element in the current table.  This
property is for identifying the primary key of the table; any other elements of
'unique_key_list' that exist will become surrogate (alternate) keys. 
Additionally, any columns used in a primary key must have their 'is_req'
properties set to true (as required by either ANSI SQL or some databases).

=item 0

B<foreign_key_list> - This array property is a list of the foreign key
constraints that are on column sets.  Given that foreign keys define a
relationship between two tables where values must be present in table A in
order to be stored in table B, this class is defined to describe a relationship
between said two tables in the object representing table B.  Each array element
is a hash (or pseudo-object) for describing a single constraint and has these
properties: 'name', 'foreign_table', 'column_list'.  The 'name' property is a
mandatory string and is a unique identifier for this constraint within the
table; it has the same case-sensitivity rules governing table and column names.
The 'foreign_table' property is a mandatory string which must match the 'name'
of a previously defined table.  The 'column_list' property is an array with at
least one element; each element is a hash having two values; the 'name' value
is a mandatory string that must match the name of a column declared in this
table; the 'foreign_column' value is a mandatory string that must match the
name of a column declared in the table whose name is in 'foreign_table'.  A
foreign key constraint can be composed of one or more columns, and more than
one constraint may use the same column; for each column used in this table, a
separate column must be matched in the other table, and the other column needs
to have the same data type.

=item 0

B<index_list> - This array property has the same format as 'unique_key_list'
but it is not for creating unique constraints; rather, it is for indicating
that we will often be doing DML operations that lookup records by values in
specific column-sets, and we want to index those columns for better fetch
performance (but slower modify performance).  Note that indexing already
happens with column-sets used for unique or presumably foreign keys, so 
specifying them here as well is probably redundant.

=back

=head2 Rosetta::Schema::DataSet

This Schema module is a Schema class that is meta-data from which DML command
templates can be generated.  Conceptually, a DataSet looks like a Table, since
both represent or store a matrix of data, which has uniquely identifiable
columns, and rows which can be uniquely identifiable but may not be.  But
unlike a Table, a DataSet does not have a name.  In its simplest use, a DataSet
is an interface to a single database table, and its public interface is
identical to that of said table; this interface can be used to fetch or modify
data stored in the table.  This class can generate Command objects having types
of: 'data_select', 'data_insert', 'data_update', 'data_delete', 'data_lock',
'data_unlock'.  I<Note: this paragraph was a rough draft.>

=head2 Rosetta::Schema::View

This Schema module is a Schema class that describes a single database view,
and would be used for such things as managing schema for the view (eg: create,
alter, destroy), and describing the view's "public interface" (it looks like a
table, with columns and rows) so other functionality like various DML
operations or other views know how to use the view.  Conceptually speaking, a
database view is an abstracted interface to one or more database tables which
are related to each other in a specific way; a view has its own name and can
generally be used like a table.  A View object has only two properties, which
are a name and a DataSet object; put another way, a View object simply
associates a name with a DataSet object.  This class does not describe anything
that is changed by DML activity, such as a count of stored records, or the
current values of sequences attached to columns.  This class can generate
Command objects having types of: 'view_verify', 'view_create', 'view_alter',
'view_destroy'.

Here is sample code for defining a few views with this class (rough draft):

	my %view_info = map { 
			( $_->{name}, Rosetta::Schema::View->new( $_ ) ) 
			} (
		{
			'name' => 'user',
			'source_list' => [
				{ 'name' => 'user_auth', 'source' => $table_info{user_auth}, },
				{ 'name' => 'user_profile', 'source' => $table_info{user_profile}, },
			],
			'column_list' => [
				{ 'name' => 'user_id'      , 'source' => 'user_auth'   , },
				{ 'name' => 'login_name'   , 'source' => 'user_auth'   , },
				{ 'name' => 'login_pass'   , 'source' => 'user_auth'   , },
				{ 'name' => 'private_name' , 'source' => 'user_auth'   , },
				{ 'name' => 'private_email', 'source' => 'user_auth'   , },
				{ 'name' => 'may_login'    , 'source' => 'user_auth'   , },
				{ 'name' => 'max_sessions' , 'source' => 'user_auth'   , },
				{ 'name' => 'public_name'  , 'source' => 'user_profile', },
				{ 'name' => 'public_email' , 'source' => 'user_profile', },
				{ 'name' => 'web_url'      , 'source' => 'user_profile', },
				{ 'name' => 'contact_net'  , 'source' => 'user_profile', },
				{ 'name' => 'contact_phy'  , 'source' => 'user_profile', },
				{ 'name' => 'bio'          , 'source' => 'user_profile', },
				{ 'name' => 'plan'         , 'source' => 'user_profile', },
				{ 'name' => 'comments'     , 'source' => 'user_profile', },
			],
			'join_list' => [
				{
					'lhs_source' => 'user_auth', 
					'rhs_source' => 'user_profile',
					'join_type' => 'left',
					'column_list' => [
						{ 'lhs_column' => 'user_id', 'rhs_column' => 'user_id', },
					],
				},
			],
		},
		{
			'name' => 'person_with_parents',
			'source_list' => [
				{ 'name' => 'self', 'source' => $table_info{person}, },
				{ 'name' => 'father', 'source' => $table_info{person}, },
				{ 'name' => 'mother', 'source' => $table_info{person}, },
			],
			'column_list' => [
				{ 'name' => 'self_id'    , 'source' => 'self'  , 'column' => 'person_id', },
				{ 'name' => 'self_name'  , 'source' => 'self'  , 'column' => 'name'     , },
				{ 'name' => 'father_id'  , 'source' => 'father', 'column' => 'person_id', },
				{ 'name' => 'father_name', 'source' => 'father', 'column' => 'name'     , },
				{ 'name' => 'mother_id'  , 'source' => 'mother', 'column' => 'person_id', },
				{ 'name' => 'mother_name', 'source' => 'mother', 'column' => 'name'     , },
			],
			'join_list => [
				{
					'lhs_source' => 'self', 
					'rhs_source' => 'father',
					'join_type' => 'left',
					'column_list' => [
						{ 'lhs_column' => 'person_id', 'rhs_column' => 'person_id', },
					],
				},
				{
					'lhs_source' => 'self', 
					'rhs_source' => 'mother',
					'join_type' => 'left',
					'column_list' => [
						{ 'lhs_column' => 'person_id', 'rhs_column' => 'person_id', },
					],
				},
			],
		},
	);

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
