=head1 NAME

Rosetta::Schema::Table - Describe a single database table

=head1 ABSTRACT

See the file Rosetta::Framework for the main Rosetta documentation.

=cut

######################################################################

package Rosetta::Schema::Table;
require 5.004;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.011';

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

=cut

######################################################################

use Rosetta::Schema::DataType 0.02;

######################################################################

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This Perl 5 object class is a core component of the Rosetta framework, and is
part of the "Rosetta Native Interface" (RNI).  It is a "Schema" class, meaning
its objects are pure containers that can be serialized or stored indefinately
off site for later retrieval and use, such as in a data dictionary.

Each Rosetta::Schema::Table object describes a single database table, and would
be used for such things as managing schema for the table (eg: create, alter,
destroy), and describing the table's "public interface" so other functionality
like views or various DML operations know how to use the table. In its simplest
sense, a Table object consists of a table name, a list of table columns, a list
of keys, a list of constraints, and a few other implementation details.  This
class does not describe anything that is changed by DML activity, such as a
count of stored records, or the current values of sequences attached to
columns.  This class would be used both when manipulating database schema and
when manipulating database data.

This class can generate Rosetta::Engine::Command objects having types of:
'table_verify', 'table_create', 'table_alter', 'table_destroy'.

=head1 CLASS PROPERTIES

These are the conceptual properties of a Rosetta::Schema::Table object:

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

This function creates a new Rosetta::Schema::Table (or subclass) object and
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
properties recognized by Rosetta::Schema::Table are set in the clone; other
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
