=head1 NAME

Rosetta::Schema::View - Describe a single database view or select query

=head1 ABSTRACT

See the file Rosetta::Framework for the main Rosetta documentation.

=cut

######################################################################

package Rosetta::Schema::View;
require 5.004;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.012';

######################################################################

=head1 COPYRIGHT AND LICENSE

This file is part of the Rosetta database abstraction framework.

Rosetta is Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved. 
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
link Rosetta with independent modules that communicate with Rosetta solely
through the "Driver" interface (because they are interfaces to or
implementations of databases), regardless of the license terms of these
independent modules, and to copy and distribute the resulting combined work
under terms of your choice, provided that every copy of the combined work is
accompanied by a complete copy of the source code of Rosetta (the version of
Rosetta used to produce the combined work), being distributed under the terms
of the GPL plus this exception.  An independent module is a module which is not
derived from or based on Rosetta, and which is fully useable when not linked to
Rosetta in any form.

Note that people who make modified versions of Rosetta are not obligated to
grant this special exception for their modified versions; it is their choice
whether to do so.  The GPL gives permission to release a modified version
without this exception; this exception also makes it possible to release a
modified version which carries forward this exception.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of 
suggesting improvements to the standard version.

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	Rosetta::Schema::DataType
	Rosetta::Schema::Table

=cut

######################################################################

use Rosetta::Schema::DataType 0.02;
use Rosetta::Schema::Table 0.01;

######################################################################

=head1 SYNOPSIS

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
						{ 'lhs_column' => 'father_id', 'rhs_column' => 'person_id', },
					],
				},
				{
					'lhs_source' => 'self', 
					'rhs_source' => 'mother',
					'join_type' => 'left',
					'column_list' => [
						{ 'lhs_column' => 'mother_id', 'rhs_column' => 'person_id', },
					],
				},
			],
		},
	);

=head1 DESCRIPTION

This Perl 5 object class is a core component of the Rosetta framework, and is
part of the "Rosetta Native Interface" (RNI).  It is a "Schema" class, meaning
its objects are pure containers that can be serialized or stored indefinately
off site for later retrieval and use, such as in a data dictionary.

Each Rosetta::Schema::View object describes a single database view, which
conceptually looks like a table, but it is used differently.  Tables and views
are similar in that they both represent or store a matrix of data, which has
uniquely identifiable columns, and rows which can be uniquely identifiable but
may not be.  With the way that Rosetta implements views, you can do all of the
same DML operations with them that you can do with tables: select, insert,
update, delete rows; that said, the process for doing any of those with views
is more complicated than with tables, but this complexity is usually internal
to Rosetta so you shouldn't have to code any differently between them.  Tables
and views are different in that tables actually store data in themselves, while
views don't.  A view is actually a custom abstracted interface to one or more
database tables which are related to each other in a specific way; when you
issue DML against a view, you are actually fetching from or modifying the data
stored in one (simplest case) or more tables.

Views are also conceptually just select queries (and with some RDBMS systems,
that is exactly how they are stored), but Rosetta::Schema::View objects have
enough meta-data so that if a program wants to, for example, modify a row
selected through one, Rosetta could calculate which composite table rows to
update (views built in to RDBMS systems are typically read-only by contrast). 
Given that Rosetta views are used mainly just for DML, they do not need to be
stored in a database like a table, and so they do not need to have names like
tables do.  However, if you want to store a view in the database like an RDBMS
native view, for added select performance, this class will let you associate a
name with one.

This class does not describe anything that is changed by DML activity, such as
a count of stored records.  This class can be used both when manipulating
database schema (stored RDBMS native views) and when manipulating database data
(normal use).

This class can generate Rosetta::Engine::Command objects having types of:
'data_select', 'data_insert', 'data_update', 'data_delete', 'data_lock',
'data_unlock', 'view_verify', 'view_create', 'view_alter', 'view_destroy'.

=head1 CLASS PROPERTIES

These are the conceptual properties of a Rosetta::Schema::View object:

=over 4

=item 0

I<This documentation is not written yet.>

=back

=cut

######################################################################

# Names of properties for objects of this class are declared here:
# ... they go here, really ...

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

I<Note: this class is incomplete, and so most of its methods are missing.>

=head2 new([ INITIALIZER ])

This function creates a new Rosetta::Schema::View (or subclass) object and
returns it.  All of the method arguments are passed to initialize() as is; please
see the POD for that method for an explanation of them.

=cut

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->initialize( @_ );
	return( $self );
}

######################################################################

=head2 initialize([ INITIALIZER ])

This method is used by B<new()> to set the initial properties of objects that
it creates.  Nothing is returned.

=cut

######################################################################

sub initialize {
	my ($self, $initializer) = @_;

}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object
properties recognized by Rosetta::Schema::View are set in the clone; other
properties are not changed.

=cut

######################################################################

sub clone {
	my ($self, $clone) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );

	return( $clone );
}

######################################################################

1;
__END__

=head1 SEE ALSO

perl(1), Rosetta::Framework, Rosetta::SimilarModules.

=cut
