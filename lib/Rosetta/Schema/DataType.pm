=head1 NAME

Rosetta::Schema::DataType - Metadata for atomic or scalar values

=head1 ABSTRACT

See the file Rosetta::Framework for the main Rosetta documentation.

=cut

######################################################################

package Rosetta::Schema::DataType;
require 5.004;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.021';

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

	I<none>

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This Perl 5 object class is a core component of the Rosetta framework, and is
part of the "Rosetta Native Interface" (RNI).  It is a "Schema" class, meaning
its objects are pure containers that can be serialized or stored indefinately
off site for later retrieval and use, such as in a data dictionary.

Each Rosetta::Schema::DataType object describes a simple data type, which
serves as metadata for a single atomic or scalar unit of data, or a column
whose members are all of the same data type, such as in a regular database
table or in row sets read from or to be written to one.  This class would be
used both when manipulating database schema and when manipulating database
data.

Essentially, you can define your own custom data types using this class and
then use those as if they were a native database type; custom types are defined
as being a basic type (see below) with a specific maximum size, and possibly
other attributes.  See the SYNOPSIS for example declarations of common custom
data types.  

These are the recognized basic types:

	'boolean'   # eg: 1, 0
	'int'       # eg: 14, 3, -7, 200000
	'float'     # eg: 3.14159
	'datetime'  # eg: 2003.02.28.16.06.30
	'str'       # eg: 'Hello World'
	'binary'    # eg: '\0x24\0x00\0xF4\0x1A'

It is intended that the Rosetta core and your application would always describe
data types for columns in terms of these objects; the base types were named
after what programmers are used to casting program variables as so they would
be easy to adapt.  This is an alternative to RDBMS specific terms like
"varchar2(40)" or "number(6)" or "text" or "blob(4000)", which you would have
to change for each database; the Rosetta::Driver::* modules are the only ones
that need to know what the database uses internally.  Of course, if you prefer 
the SQL terms, you can easily name your DataType objects after them.

=head1 CLASS PROPERTIES

These are the conceptual properties of a Rosetta::Schema::DataType object:

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

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_NAME = 'name';  # string - user readable unique id for this data type
my $KEY_BATP = 'base_type';  # string - one of: [boolean,int,float,datetime,str,binary]
my $KEY_SIZE = 'size';  # integer - max size in bytes or chars of data being stored
my $KEY_STFX = 'store_fixed';  # boolean - true if value stored in fixed size db field

# These are the allowed base types and their default sizes:
my %BASE_TYPES = (
	'boolean'  =>   0,  # eg: 1, 0
	'int'      =>   4,  # eg: 14, 3, -7, 200000
	'float'    =>   4,  # eg: 3.14159
	'datetime' =>   0,  # eg: 2003.02.28.16.06.30
	'str'      => 250,  # eg: 'Hello World'
	'binary'   => 250,  # eg: '\0x24\0x00\0xF4\0x1A'
);

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

=head2 new([ INITIALIZER ])

This function creates a new Rosetta::Schema::DataType (or subclass) object and
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
it creates.  Calling it yourself will revert all of this object's properties to
their default values, which correspond to a string of maximum 250 characters.
The optional argument, INITIALIZER, is a hash reference (or object) whose
values would be used to set explicit default properties for this object.  The
hash keys which this class will look for are: name, base_type, size,
store_fixed.  These values are passed to the same-named property accessor
methods for evaluation; please see the POD for those methods for an explanation
of what input values are allowed and any side effects of setting them.  If
INITIALIZER is defined and not a hash reference, it will be interpreted as a
scalar value and passed to base_type().  Nothing is returned.

=cut

######################################################################

sub initialize {
	my ($self, $initializer) = @_;

	$self->{$KEY_NAME} = 'No_Name_Data_Type';
	$self->{$KEY_BATP} = 'str';
	$self->{$KEY_SIZE} = 250;
	$self->{$KEY_STFX} = 0;

	if( UNIVERSAL::isa($initializer,'Rosetta::Schema::DataType') or 
			ref($initializer) eq 'HASH' ) {
		$self->name( $initializer->{$KEY_NAME} );
		$self->base_type( $initializer->{$KEY_BATP} );
		$self->size( $initializer->{$KEY_SIZE} );
		$self->store_fixed( $initializer->{$KEY_STFX} );

	} elsif( defined( $initializer ) ) {
		$self->base_type( $initializer );
	}
}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object
properties recognized by Rosetta::Schema::DataType are set in the clone; other
properties are not changed.

=cut

######################################################################

sub clone {
	my ($self, $clone) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );

	$clone->{$KEY_NAME} = $self->{$KEY_NAME};
	$clone->{$KEY_BATP} = $self->{$KEY_BATP};
	$clone->{$KEY_SIZE} = $self->{$KEY_SIZE};
	$clone->{$KEY_STFX} = $self->{$KEY_STFX};

	return( $clone );
}

######################################################################

=head2 get_all_properties()

This method returns a hash reference whose keys and values are the property
names and values of this object: name, base_type, size, store_fixed.  If you
pass this hash reference as an argument to the new() class function, the object
that it creates will be identical to this one.

=cut

######################################################################

sub get_all_properties {
	my ($self) = @_;
	return( {
		$KEY_NAME => $self->{$KEY_NAME}, 
		$KEY_BATP => $self->{$KEY_BATP}, 
		$KEY_SIZE => $self->{$KEY_SIZE}, 
		$KEY_STFX => $self->{$KEY_STFX},
	} );
}

######################################################################

=head2 name([ VALUE ])

This method is an accessor for the string "name" property of this object, which
it returns.  If VALUE is defined, this property is set to it.

=cut

######################################################################

sub name {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_NAME} = $new_value;
	}
	return( $self->{$KEY_NAME} );
}

######################################################################

=head2 base_type([ VALUE ])

This method is an accessor for the string "base_type" property of this object,
which it returns.  If VALUE is defined and matches a valid base type (it gets
lowercased), then this property is set to it; in addition, "size" is reset to a
default value appropriate for the base type, and "store_fixed" is set false; 
you should set those properties after this one if you want them different.

=cut

######################################################################

sub base_type {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$new_value = lc($new_value);
		if( exists( $BASE_TYPES{$new_value} ) ) {
			$self->{$KEY_BATP} = $new_value;
			$self->{$KEY_SIZE} = $BASE_TYPES{$new_value};
			$self->{$KEY_STFX} = 0;
		}
	}
	return( $self->{$KEY_BATP} );
}

######################################################################

=head2 size([ VALUE ])

This method is an accessor for the integer "size" property of this object,
which it returns.  If VALUE is defined, then it is cast as an integer, and this
property is set to it; non-integral numbers will be truncated and other scalar
values will become zero.

=cut

######################################################################

sub size {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_SIZE} = int( $new_value ); # cast as integer
	}
	return( $self->{$KEY_SIZE} );
}

######################################################################

=head2 store_fixed([ VALUE ])

This method is an accessor for the boolean "store_fixed" property of this
object, which it returns.  If VALUE is defined, then it is cast as a 1 or 0
based on Perl's determination of truth, and this property is set to it.

=cut

######################################################################

sub store_fixed {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$KEY_STFX} = ($new_value ? 1 : 0);
	}
	return( $self->{$KEY_STFX} );
}

######################################################################

=head2 valid_types([ TYPE ])

This function returns a hash ref having as keys all of the basic data types
that Rosetta recognizes, any of which is valid input to the base_type() method,
and having as values the default storage size reserved for table columns of
that type, which are valid input to the size() method.  This list contains the
same types listed in the DESCRIPTION.  If the optional string argument, TYPE,
is defined, then this function will instead return a scalar value depending on
whether TYPE is a valid base type or not; if it is, then the returned value is
its default size (which may be zero); if it is not, then the undefined value is
returned.

=cut

######################################################################

sub valid_types {
	my (undef, $type) = @_;
	return( defined($type) ? $BASE_TYPES{$type} : {%BASE_TYPES} );
}

######################################################################

1;
__END__

=head1 SEE ALSO

perl(1), Rosetta::Framework, Rosetta::SimilarModules.

=cut
