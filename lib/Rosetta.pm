=head1 NAME

Rosetta - Framework for RDBMS-generic apps and schemas

=cut

######################################################################

package Rosetta;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.08';

use Locale::KeyedText 0.02;
use SQL::SyntaxModel 0.12;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Locale::KeyedText 0.02 (for error messages)
	SQL::SyntaxModel 0.12

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

=cut

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
Rosetta::_::Shared; # has no properties, only stateless methods of its own

######################################################################

# Names of properties for objects of the Rosetta class are declared here:
my $RPROP_INTERFACE = 'interface'; # holds all the actual Interface properties for this class
	# We use two classes internally where user sees one so that no internal refs point to the 
	# parentmost object, and hence DESTROY() will be called properly when all external refs go away.

# Names of properties for objects of the Rosetta::_::Interface class are declared here:
my $IPROP_INTF_TYPE = 'intf_type'; # str (enum) - what type of Interface this is, no chg once set
	# The Interface Type is the only property which absolutely can not change, and is set when object created.
my $IPROP_PARENT_INTF = 'parent_intf'; # ref to parent Interface, which provides a context 
	# for the current one, unless the current Interface is a root
my $IPROP_CHILD_INTFS = 'child_intfs'; # array - list of refs to child Interfaces that the 
	# current one spawned and provides a context for; this may or may not be useful in practice, 
	# and it does set up a circular ref problem such that all Interfaces in a tree will not be 
	# destroyed until their root Interface is, unless this is done explicitely
my $IPROP_ENGINE = 'engine'; # ref to Engine implementing this Interface if any
	# This Engine object would store its own state internally, which includes such things 
	# as various DBI dbh/sth/rv handles where appropriate, and any generated SQL to be 
	# generated, as well as knowledge of how to translate named bind params to positional ones.
	# The Engine object would never store a reference to the Interface object that it 
	# implements, as said Interface object would pass a reference to itself as an argument 
	# to any Engine methods that it invokes.  Of course, if this Engine implements a 
	# middle-layer and invokes another Interface/Engine tree of its own, then it would store 
	# a reference to that Interface like an application would.
my $IPROP_IS_ERROR = 'is_error'; # boolean - true means Interface obj represents a failure
my $IPROP_ERROR_MSG = 'error_msg'; # object (Locale::KeyedText::_::Message) - details of a 
	# failure, or at least any that might be useful to a generic application error handler
my $IPROP_THROW_ERRORS = 'throw_errors'; # boolean - true means that Interface objects will be 
	# thrown by prepare/execute methods if they are errors, false means return all Interface objs

# Names of properties for objects of the Rosetta::_::Engine class are declared here:
	 # No properties (yet) are declared by this parent class; leaving space free for child classes

# Names of the allowed Interface types go here:
my $INTFTP_ROOT        = 'root'; # What you get when you create an Interface out of any context
my $INTFTP_PREPARATION = 'preparation'; # That which is returned by the 'prepare()' method
my $INTFTP_CONNECTION  = 'connection'; # Result of executing a 'connect' command
my $INTFTP_TRANSACTION = 'transaction'; # Result of asking to start a new transaction
my $INTFTP_CURSOR      = 'cursor'; # Result of executing a query that would return rows to the caller
my $INTFTP_ROW         = 'row'; # Result of executing a query that returns one row
my $INTFTP_LITERAL     = 'literal'; # Result of execution that isn't one of the above, like an IUD
my %ALL_INTFTP_TYPES = ( map { ($_ => 1) } (
	$INTFTP_ROOT, $INTFTP_PREPARATION, 
	$INTFTP_CONNECTION, $INTFTP_TRANSACTION, 
	$INTFTP_CURSOR, $INTFTP_ROW, $INTFTP_LITERAL, 
) );

######################################################################
# These are 'protected' methods; only sub-classes should invoke them.

sub _get_static_const_root_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'Rosetta' );
}

sub _get_static_const_interface_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'Rosetta::_::Interface' );
}

sub _get_static_const_engine_class_name {
	# This function is intended to be overridden by sub-classes.
	# It is intended only to be used when making new objects.
	return( 'Rosetta::_::Engine' );
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	# Throws an exception consisting of an object.
	die Locale::KeyedText->new_message( $error_code, $args );
}

######################################################################

sub new {
	my ($self) = @_;
	my $root = bless( {}, $self->_get_static_const_root_class_name() );
	$root->{$RPROP_INTERFACE} = $self->new_interface();
	return( $root );
}

sub new_interface {
	my ($self, $intf_type) = @_;
	defined( $intf_type ) or $self->_throw_error_message( 'ROS_S_NEW_INTF_NO_ARGS' );

	unless( $ALL_INTFTP_TYPES{$intf_type} ) {
		$self->_throw_error_message( 'ROS_S_NEW_INTF_BAD_TYPE', { 'TYPE' => $intf_type } );
	}

	my $interface = bless( {}, $self->_get_static_const_interface_class_name() );

	$interface->{$IPROP_INTF_TYPE} = $intf_type;
	$interface->{$IPROP_PARENT_INTF} = undef;
	$interface->{$IPROP_CHILD_INTFS} = [];
	$interface->{$IPROP_ENGINE} = undef;
	$interface->{$IPROP_IS_ERROR} = 0;
	$interface->{$IPROP_ERROR_MSG} = undef;
	$interface->{$IPROP_THROW_ERRORS} = 0;

	return( $interface );
}

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
Rosetta;
use base qw( Rosetta::_::Shared );

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
Rosetta::_::Interface;
use base qw( Rosetta::_::Shared );

######################################################################
######################################################################

package # hide this class name from PAUSE indexer
Rosetta::_::Engine;
use base qw( Rosetta::_::Shared );

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<Note: Look at the SQL::SyntaxModel (SSM) documentation for examples of how to
construct the various SQL commands / Node groups used in this SYNOPSIS.>

	use Rosetta; # Module also 'uses' SQL::SyntaxModel and Locale::KeyedText.

	my $schema_model = SQL::SyntaxModel->new(); # global for a simpler illustration, not reality

	main();

	sub main {
		my $interface = Rosetta->new();

		# ... Next create and stuff Nodes in $schema_model that represent the database we want 
		# to use (including what data storage product it is) and how we want to link/connect 
		# to it (including what Rosetta "engine" plug-in and DSN to use).  Then put a 'command' 
		# Node which instructs to open a connection with said database in $open_db_command.

		my $prepared_open_cmd = $interface->prepare( $open_db_command );
		if( $prepared_open_cmd->is_error() ) {
			print "internal error: a command is invalid: ".error_to_string( $prepared_open_cmd );
			return( 0 );
		}

		while( 1 ) {
			# ... Next, assuming they are gotten dynamically such as from the user, gather the db 
			# authentication credentials, username and password, and put them in $user and $pass.

			my $db_conn = $prepared_open_cmd->execute( { 'login_user' => $user, 'login_pass' => $pass } );

			unless( $db_conn->is_error() ) {
				last; # Connection was successful.
			}

			# If we get here, something went wrong when trying to open the database; eg: the requested 
			# engine plug-in doesn't exist, or the DSN doesn't exist, or the user/pass are incorrect.  

			my $error_message = $db_conn->error_message();

			# ... Next examine $error_message (a machine-readable Locale::KeyedText Message 
			# object) to see if the problem is our fault or the user's fault.

			if( ... user is at fault ... ) {
				print "sorry, you entered the wrong user/pass, please try again";
				next;
			}

			print "sorry, problem opening db, we gotta quit: ".error_to_string( $db_conn );
			return( 0 );
		}

		# Now do the work we connected to the db for.  To simplify this example, it is 
		# fully non-interactive, such as with a test script.
		OUTER: {
			do_install( $db_conn ) or last OUTER;
			INNER: {
				do_populate( $db_conn ) or last INNER;
				do_select( $db_conn );
			}
			do_remove( $db_conn );
		}

		# ... Next make a SSM 'command' to close the db and put it in $close_db_command.

		$db_conn->prepare( $close_db_command )->execute(); # ignore the result this time

		return( 1 );
	}

	sub error_to_string {
		my ($interface) = @_;
		my $message = $interface->error_message();
		my $translator = Locale::KeyedText->new_translator( 
			['Rosetta::L::', 'SQL::SyntaxModel::L::'], ['en'] );
		my $user_text = $translator->translate_message( $message );
		unless( $user_text ) {
			return( "internal error: can't find user text for a message: ".
				$message->as_string()." ".$translator->as_string() );
		}
		return( $user_text );
	}

	sub do_install {
		my ($db_conn) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent a table 
		# we want to create in our database; let's pretend it is named 'stoff' and 
		# has 3 columns named 'foo', 'bar', 'baz'.  Then put a 'command' Node which 
		# instructs to create said table in $create_stoff_command.

		my $result = $db_conn->prepare( $create_stoff_command )->execute();
		if( $result->is_error() ) {
			print "sorry, problem making stoff table: ".error_to_string( $result );
			return( 0 );
		}

		# If we get here, the table was made successfully.
		return( 1 );
	}

	sub do_remove {
		my ($db_conn) = @_;

		# ... Next make a SSM 'command' to drop the table and put it in $drop_stoff_command.

		my $result = $db_conn->prepare( $drop_stoff_command )->execute();
		if( $result->is_error() ) {
			print "sorry, problem removing table: ".error_to_string( $result );
			return( 0 );
		}

		# If we get here, the table was removed successfully.
		return( 1 );
	}

	sub do_populate {
		my ($db_conn) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# inserts a row into the 'stoff' table; it takes 3 arguments named 'a_foo', 
		# 'a_bar', 'a_baz'.  Then put this 'routine' Node in $insert_stoff_cmd.

		my $prepared_insert_cmd = $db_conn->prepare( $insert_stoff_cmd );

		my @data = (
			{ 'a_foo' => 'windy', 'a_bar' => 'carrots' , 'a_baz' => 'dirt'  , },
			{ 'a_foo' => 'rainy', 'a_bar' => 'peas'    , 'a_baz' => 'mud'   , },
			{ 'a_foo' => 'snowy', 'a_bar' => 'tomatoes', 'a_baz' => 'cement', },
			{ 'a_foo' => 'sunny', 'a_bar' => 'broccoli', 'a_baz' => 'moss'  , },
			{ 'a_foo' => 'haily', 'a_bar' => 'onions'  , 'a_baz' => 'stones', },
		)

		foreach my $data_item (@data) {
			my $result = $prepared_insert_cmd->execute( $data_item );
			if( $result->is_error() ) {
				print "sorry, problem stuffing stoff: ".error_to_string( $result );
				return( 0 );
			}
		}

		# If we get here, the table was populated successfully.
		return( 1 );
	}

	sub do_select {
		my ($db_conn) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# selects a row from the 'stoff' table, where the column 'foo' matches the sole 
		# routine arg 'a_foo'.  Then put this 'routine' Node in $get_one_stoff_cmd.

		my $get_one_cmd = $db_conn->prepare( $get_one_stoff_cmd );
		if( $get_one_cmd->is_error() ) {
			print "internal error: a command is invalid: ".error_to_string( $get_one_cmd );
			return( 0 );
		}
		my $row = $get_one_cmd->execute( { 'a_foo' => 'snowy' } );
		if( $row->is_error() ) {
			print "sorry, problem getting snowy: ".error_to_string( $result );
			return( 0 );
		}
		my $data = $row->row_data(); # $data is a hash-ref of tbl col name/val pairs.

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# selects all rows from 'stoff'.  Then put this 'routine' Node in $get_all_stoff_cmd.

		my $get_all_cmd = $db_conn->prepare( $get_all_stoff_cmd );
		if( $get_all_cmd->is_error() ) {
			print "internal error: a command is invalid: ".error_to_string( $get_all_cmd );
			return( 0 );
		}
		my $cursor = $get_all_cmd->execute();
		if( $cursor->is_error() ) {
			print "sorry, problem getting all stoff: ".error_to_string( $result );
			return( 0 );
		}
		my @data = ();
		while( $cursor->has_more_rows() ) {
			push( @data, $cursor->fetch_row() );
		}
		$cursor->close();
		# Each @data element is a hash-ref of tbl col name/val pairs.

		# If we get here, the table was fetched from successfully.
		return( 1 );
	}

=head1 DESCRIPTION

The Rosetta Perl 5 object class implements the core of the Rosetta database
abstraction framework.  Rosetta defines a complete API, having a "Command"
design pattern, for applications to query and manipulate databases with; it
handles all common functionality that is representable by SQL or that database
products implement, both data manipulation and schema manipulation.  This
Rosetta core does not implement that interface (or most of it), however; you
use it with your choice of separate "engine" plug-ins that each understand how
to talk to particular data storage products or data link products, and
implement the Rosetta Native Interface (or "RNI") on top of those products.

The level of abstraction that Rosetta provides is similar to a virtual machine,
such that applications written to do their database communications through it
should "just work", without changes, when moved between databases.  This should
happen with applications of nearly any complexity level, including those that
use all (most) manner of advanced database features.  It is as if every
database product out there has full ANSI/ISO SQL-1999 (or 1992 or 2003)
compliance, so you write in standard SQL that just works anywhere.  Supported
advanced features include generation and invocation of database stored
routines, select queries (or views or cursors) of any complexity, [ins,upd,del]
against views, multiple column keys, nesting, multiple schemas, separation of
global from site-specific details, bind variables, unicode, binary data,
triggers, transactions, locking, constraints, data domains, localization,
proxies, and database to database links.  At the same time, Rosetta is designed
to be fast and efficient.  Rosetta is designed to work equally well with both
embedded and client-server databases.

The separately released SQL::SyntaxModel Perl 5 object class is used by Rosetta
as a core part of its API.  Applications pass SQL::SyntaxModel objects in place
of SQL strings when they want to invoke a database, both for DML and DDL
activity, and a Rosetta engine translates those objects into the native SQL (or
non-SQL) dialect of the database.  Similarly, when a database returns a schema
dump of some sort, it is passed to the application as SQL::SyntaxModel objects
in place of either SQL strings or "information schema" rows.  You should look
at SQL::SyntaxModel::Language as a general reference on how to construct
queries or schemas, and also to know what features are or are not supported.

Rosetta is especially suited for data-driven applications, since the composite
scalar values in their data dictionaries can often be copied directly to RNI
structures, saving applications the tedious work of generating SQL themselves.

Depending on what kind of application you are writing, you may be better off to
not use Rosetta directly as a database interface.  The RNI is quite verbose,
and using it directly (especially SQL::SyntaxModel) can be akin to writing
assembly language like IMC for Parrot, at least as far as how much work each
instruction does.  Rosetta is designed this way on purpose so that it can serve
as a foundation for other database interface modules, such as object
persistence solutions, or query generators, or application toolkits, or
emulators, or "simple database interfaces".  Many such modules exist on CPAN
and all suffer from the same "background problem", which is getting them to
work with more than one or three databases; for example, many only work with
MySQL, or just that and PostgreSQL, and a handful do maybe five products. Also,
there is a frequent lack of support for desirable features like multiple column
keys.  I hope that such modules can see value in using Rosetta as they now use
DBI directly; by doing so, they can focus on their added value and not worry
about the database portability aspect of the equation, which for many was only
a secondary concern to begin with.  Correspondingly, application writers that
wish to use Rosetta would be best off having their own set of "summarizing"
wrapper functions to keep your code down to size, or use another CPAN module
such as one of the above that does the wrapping for you.

The Rosetta framework is conceptually similar to the mature and popular Perl
DBI framework spearheaded by Tim Bunce; in fact, many initial Rosetta engines
are each implemented as a value-added wrapper for a DBI DBD module.  But they
have significant differences as well, so Rosetta should not be considered a
mere wrapper of DBI (moreover, on the implementation side, the Rosetta core
does not require DBI at all, and any of its engines can do their work without
it also if they so choose).  I see DBI by itself as a generic communications
pipe between a database and an application, that shuttles mostly opaque boxes
back and forth; it is a courier that does its transport job very well, while it
knows little about what it is carrying.  More specifically, it knows a fair
amount about what it shuttles *from* the database, but considerably less about
what is shuttled *to* the database (opaque SQL strings, save bind variables).
It is up to the application to know and speak the same language as the
database, meaning the SQL dialect that is in the boxes, so that the database
understands what it is given.  I see Rosetta by itself as a communications pipe
that *does* understand the contents of the boxes, and it can translate or
reorganize the contents of the boxes while moving them, such that an
application can always speak in the same language regardless of what database
it is talking to.  Now, you could say that this sounds like Rosetta is a query
generator on top of DBI, and in many respects you are correct; that is its
largest function.  However, it can also translate results coming *from* a
database, such as massaging returned data into a single format for the
application, while different databases may not return in the same format.  One
decision that I made with Rosetta, unlike other query generation type modules,
is that it will never expose any underlying DBI object to the application. 
I<Note that I may have mis-interpreted DBI's capabilities, so this paragraph
stands to be changed as I get better educated.>

Please see the Rosetta::Framework documentation file for more information on 
the Rosetta framework at large.

=head1 STRUCTURE

The Rosetta core module is structured like a simple virtual machine, which can
be conceptually thought of as implementing an embedded SQL database;
alternately, it is a command interpreter.  This module is implemented with 2
main classes that work together, which are "Interface" and "Engine".  To use
Rosetta, you first create a root Interface object (or several; one is normal)
using Rosetta->new(), which provides a context in which you can prepare and
execute commands against a database or three.  One of your first commands is
likely to open a connection to a database, during which you associate a
separately available Engine plug-in of your choice with said connection.  This
Engine plug-in does all the meat of implementing the Rosetta API that the
Interface defines; the Engine class defined inside the Rosetta core module is a
simple common super-class for all Engine plug-in modules.  The Engine
super-class mainly deals with manipulating the Perl references that bind Engine
and Interface objects together, so normal Engine classes don't ever see those.

During the normal course of using Rosetta, you will end up talking to a whole
bunch of Interface objects, which are all related to each other in a tree-like
fashion.  Each time you prepare() or execute() a command against one, another
is typically spawned which represents the results of your command, be it an
error condition or a database connection handle or a transaction context handle
or a select cursor handle or a miscellaneous returned data container.  Each
Interface object has a "type" property which says what kind of thing it
represents and how it behaves.  All Interface types have an "is_error()" method
but only a cursor type, for example, has a "fetch_row()" method.  For
simplicity, all Interface objects are explicitely defined to have all possible
Interface methods (no "autoload" et al is used); however, an inappropriately
called method will throw an exception saying so, so it is as if Perl had a
normal run-time error due to calling a non-existant method.

Each Interface object may also have its own Engine object associated with it 
behind the scenes, with all the Engine objects in a mirroring tree structure; 
but that may not always be true.  One example is right when you start out, or 
if you try to open a database connection using a non-existint Engine module.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 SEE ALSO

perl(1), Rosetta::L::*, Rosetta::Framework, Rosetta::SimilarModules,
SQL::SyntaxModel, Locale::KeyedText, DBI.

=cut
