=head1 NAME

SQL::ObjectModel - Unserialized SQL objects, use like XML DOM

=head1 PREFACE

Most of this module's code or structure isn't yet directly documented in POD,
so you should view the source of this file to better understand what it can do
and how to use it.  That said, many details are indirectly documented in the
DataDictionary.pod file, so looking at that may help you understand this code.

Please note that this module is currently in pre-alpha development status,
meaning that everything in it is highly likely to change in the future, and
that it hasn't been tested much yet.  Moreover, there isn't a lot of input
checking yet, and the module currently assumes you will provide correct input
when calling its methods; this lack currently makes the code a lot simpler and
easier to understand.

=head1 COPYRIGHT AND LICENSE

This file is part of the SQL::ObjectModel library (libSOM).

SQL::ObjectModel is Copyright (c) 1999-2003, Darren R. Duncan.  All rights
reserved.  Address comments, suggestions, and bug reports to
B<perl@DarrenDuncan.net>, or visit "http://www.DarrenDuncan.net" for more
information.

SQL::ObjectModel is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License (GPL) version 2 as published
by the Free Software Foundation (http://www.fsf.org/).  You should have
received a copy of the GPL as part of the SQL::ObjectModel distribution, in the
file named "LICENSE"; if not, write to the Free Software Foundation, Inc., 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA.

Any versions of SQL::ObjectModel that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits. SQL::ObjectModel is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GPL for more details.

Linking SQL::ObjectModel statically or dynamically with other modules is making
a combined work based on SQL::ObjectModel.  Thus, the terms and conditions of
the GPL cover the whole combination.

As a special exception, the copyright holders of SQL::ObjectModel give you
permission to link SQL::ObjectModel with independent modules that are
interfaces to or implementations of databases, regardless of the license terms
of these independent modules, and to copy and distribute the resulting combined
work under terms of your choice, provided that every copy of the combined work
is accompanied by a complete copy of the source code of SQL::ObjectModel (the
version of SQL::ObjectModel used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on SQL::ObjectModel, and
which is fully useable when not linked to SQL::ObjectModel in any form.

Note that people who make modified versions of SQL::ObjectModel are not
obligated to grant this special exception for their modified versions; it is
their choice whether to do so.  The GPL gives permission to release a modified
version without this exception; this exception also makes it possible to
release a modified version which carries forward this exception.

While it is by no means required, the copyright holders of SQL::ObjectModel
would appreciate being informed any time you create a modified version of
SQL::ObjectModel that you are willing to distribute, because that is a
practical way of suggesting improvements to the standard version.

=head1 DEPENDENCIES

Perl Version:

	5.004

Standard Modules:

I<none>

Nonstandard Modules:

I<none>

=cut

######################################################################
######################################################################
# General file-level pragma or module dependencies are specified here.

require 5.004;
use strict;
use warnings;

# This is the logical organization of the classes in this module:
# 
# 	+-objectmodel
# 	   +-datatype
# 	   +-database
# 	   |  +-namespace
# 	   |  |  +-table
# 	   |  |  |  +-trigger
# 	   |  |  |     +-block
# 	   |  |  +-view
# 	   |  |  |  +-view
# 	   |  |  +-sequence    
# 	   |  |  +-block
# 	   |  |     +-block
# 	   |  +-user
# 	   +-command
# 	      +-view
# 	      +-block

######################################################################
######################################################################
# Any named constant values that are used by any of the classes in this 
# file are declared here, including the names of any class properties 
# or sub-properties or named method arguments.

# Names of SQL::ObjectModel class properties are declared here:
my $PROP_SOM_DATATYPE_LIST = 'datatype_list';
my $PROP_SOM_DATABASE_LIST = 'database_list';
# No list of commands will be stored here since they are not part of a schema.
# However, an application specific class using this one may implement one.

# Names of SQL::ObjectModel::_::Node class properties are declared here:
my $PROP_NODE_CONTAINER = 'som_node_container';  # ref to SOM containing node
my $PROP_NODE_PARENT    = 'som_node_parent';  # ref to parent node of this node

######################################################################
# Names of SQL::ObjectModel::_::DataType class properties are declared here:
my $PROP_DATP_NAME   = 'name';
my $PROP_DATP_BATP   = 'basic_type';
my $PROP_DATP_SIBY   = 'size_in_bytes';
my $PROP_DATP_SICH   = 'size_in_chars';
my $PROP_DATP_SIDI   = 'size_in_digits';
my $PROP_DATP_STFX   = 'store_fixed';
my $PROP_DATP_S_ENC  = 'str_encoding';
my $PROP_DATP_S_TRWH = 'str_trim_white';
my $PROP_DATP_S_LTCS = 'str_latin_case';
my $PROP_DATP_S_PDCH = 'str_pad_char';
my $PROP_DATP_S_TRPD = 'str_trim_pad';
my $PROP_DATP_N_UNSG = 'num_unsigned';
my $PROP_DATP_N_PREC = 'num_precision';
my $PROP_DATP_D_CAL  = 'datetime_calendar';

# Names of the allowed basic data types are declared here:
# ... NOT SURE IF THIS WILL BE USED ...
my $DATP_BINARY   = 'bin';
my $DATP_STRING   = 'str';
my $DATP_NUMBER   = 'num';
my $DATP_BOOLEAN  = 'bool';
my $DATP_DATETIME = 'datetime';
my %DATP_BASIC_TYPES = (
	$DATP_BINARY   => 250,  # eg: '\0x24\0x00\0xF4\0x1A'
	$DATP_STRING   => 250,  # eg: 'Hello World'
	$DATP_NUMBER   =>   4,  # eg: 14, 3, -7, 200000, 3.14159
	$DATP_BOOLEAN  =>   0,  # eg: 1, 0
	$DATP_DATETIME =>   0,  # eg: 2003.02.28.16.06.30
);

######################################################################
# Names of SQL::ObjectModel::_::Database class properties are declared here:
my $PROP_DB_DATABASE_ID    = 'database_id';
my $PROP_DB_DATABASE_NAME  = 'database_name';

my $PROP_DB_NAMESPACE_LIST = 'namespace_list';
my $PROP_DB_USER_LIST      = 'user_list';

# Names of SQL::ObjectModel::_::Namespace class properties are declared here:
my $PROP_NS_NAMESPACE_ID   = 'namespace_id';
my $PROP_NS_DATABASE_ID    = 'database_id';
my $PROP_NS_NAMESPACE_NAME = 'namespace_name';

my $PROP_NS_TABLE_LIST    = 'table_list';
my $PROP_NS_VIEW_LIST     = 'view_list';
my $PROP_NS_SEQUENCE_LIST = 'sequence_list';
my $PROP_NS_BLOCK_LIST    = 'block_list';

######################################################################
# Names of SQL::ObjectModel::_::Table class properties are declared here:
my $PROP_TB_TRIGGER_LIST = 'trigger_list';

# Names of SQL::ObjectModel::_::Trigger class properties are declared here:
my $PROP_TG_BLOCK = 'block';

######################################################################
# Names of SQL::ObjectModel::_::View class properties are declared here:

######################################################################
# Names of SQL::ObjectModel::_::Sequence class properties are declared here:

######################################################################
# Names of SQL::ObjectModel::_::Block class properties are declared here:

######################################################################
# Names of SQL::ObjectModel::_::User class properties are declared here:

######################################################################
# Names of SQL::ObjectModel::_::Command class properties are declared here:
my $PROP_CMD_ID   = 'id';  # not sure if this will be needed
my $PROP_CMD_TYPE = 'type';
# ...

# Names of the allowed command types are declared here:
my $CMD_DB_LIST   = 'db_list';
my $CMD_DB_INFO   = 'db_info';
my $CMD_DB_VERIFY = 'db_verify';
my $CMD_DB_OPEN   = 'db_open';
my $CMD_DB_CLOSE  = 'db_close';
my $CMD_DB_PING   = 'db_ping';
my $CMD_DB_CREATE = 'db_create';
my $CMD_DB_DELETE = 'db_delete';
my $CMD_DB_CLONE  = 'db_clone';
my $CMD_DB_MOVE   = 'db_move';
my $CMD_US_LIST   = 'user_list';
my $CMD_US_INFO   = 'user_info';
my $CMD_US_VERIFY = 'user_verify';
my $CMD_US_CREATE = 'user_create';
my $CMD_US_DELETE = 'user_delete';
my $CMD_US_CLONE  = 'user_clone';
my $CMD_US_UPDATE = 'user_update';
my $CMD_US_GRANT  = 'user_grant';
my $CMD_US_REVOKE = 'user_revoke';
my $CMD_TB_LIST   = 'table_list';
my $CMD_TB_INFO   = 'table_info';
my $CMD_TB_VERIFY = 'table_verify';
my $CMD_TB_CREATE = 'table_create';
my $CMD_TB_DELETE = 'table_delete';
my $CMD_TB_CLONE  = 'table_clone';
my $CMD_TB_UPDATE = 'table_update';  # means 'alter'
my $CMD_VW_LIST   = 'view_list';
my $CMD_VW_INFO   = 'view_info';
my $CMD_VW_VERIFY = 'view_verify';
my $CMD_VW_CREATE = 'view_create';
my $CMD_VW_DELETE = 'view_delete';
my $CMD_VW_CLONE  = 'view_clone';
my $CMD_VW_UPDATE = 'view_update';
my $CMD_BL_LIST   = 'block_list';
my $CMD_BL_INFO   = 'block_info';
my $CMD_BL_VERIFY = 'block_verify';
my $CMD_BL_CREATE = 'block_create';
my $CMD_BL_DELETE = 'block_delete';
my $CMD_BL_CLONE  = 'block_clone';
my $CMD_BL_UPDATE = 'block_update';
my $CMD_RC_FETCH  = 'rec_fetch';  # means 'select'
my $CMD_RC_VERIFY = 'rec_verify';
my $CMD_RC_INSERT = 'rec_insert';
my $CMD_RC_UPDATE = 'rec_update';
my $CMD_RC_DELETE = 'rec_delete';
my $CMD_RC_REPLAC = 'rec_replace';
my $CMD_RC_CLONE  = 'rec_clone';
my $CMD_RC_LOCK   = 'rec_lock';
my $CMD_RC_UNLOCK = 'rec_unlock';
my $CMD_TR_START  = 'tra_start';
my $CMD_TR_COMMIT = 'tra_commit';
my $CMD_TR_RLLBCK = 'tra_rollback';
my $CMD_CA_PROC   = 'call_proc';
my $CMD_CA_FUNC   = 'call_func';

######################################################################
######################################################################
# Some file-scope convenience functions are declared here.
# They are intended to be temporary, and exist only to help with rapid 
# prototyping of this module.  They are not class or object methods.

sub util_get {
	# Takes an array ref of hash refs and looks for a hash ref having 
	# a certain element value; it returns the hash ref that matches.
	# Hash refs may be objects.  An index may be used later instead.
	my ($node_list, $prop_name, $prop_value) = @_;
	foreach my $node (@{$node_list}) {
		if( $node->{$prop_name} eq $prop_value ) {
			return( $node );
		}
	}
	return( undef );
}

sub util_pos {
	# Takes an array ref of hash refs and looks for a hash ref having 
	# a certain value; returns array index of the hash that matches.
	# Hash refs may be objects.  An index may be used later instead.
	my ($node_list, $prop_name, $prop_value) = @_;
	foreach my $i (0..$#{$node_list}) {
		if( $node_list->[$i]->{$prop_name} eq $prop_value ) {
			return( $i );
		}
	}
	return( undef );
}

######################################################################
######################################################################
# The class SQL::ObjectModel is declared here, with version number.

package SQL::ObjectModel;
use vars qw($VERSION);
$VERSION = '0.02';

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->_initialize( @_ );
	return( $self );
}

sub initialize {
	my $self = shift( @_ );
	%{$self} = ();
	$self->_initialize( @_ );
}

sub clone {
	my ($self, $clone) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );
	$clone->_initialize( $self );
	return( $clone );
}

######################################################################

sub _initialize {
	my ($self, $initializer) = @_;

	$self->{$PROP_SOM_DATATYPE_LIST} = [];
	$self->{$PROP_SOM_DATABASE_LIST} = [];

	if( ref($initializer) eq ref($self) ) {
		# We were given another SQL::ObjectModel whose properties we 
		# need to copy into ourself; we may be a clone of that object.

		# ... TASK STILL TO DO ...
	}
}

######################################################################
# Create objects which are subclasses of SQL::ObjectModel::_::Node; 
# all of these "belong" to a SQL::ObjectModel (like an XML NODE to an 
# XML DOM); the code in the Node sub/class is responsible for its 
# global circular reference attachments to a Model.  When creating a 
# new Node, the ObjectModel ref is passed as the first argument.

sub new_command {
	return( SQL::ObjectModel::_::Command->new( @_ ) );
}

sub new_data_type {
	return( SQL::ObjectModel::_::DataType->new( @_ ) );
}

sub new_database {
	return( SQL::ObjectModel::_::Database->new( @_ ) );
}






######################################################################

sub DESTROY {
	# This is supposed to make sure that any circular references don't 
	# prevent timely object destruction, by dropping refs to Nodes.
	%{$_[0]} = ();
}

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Node is declared here.
# It is a parent class for all SQL::ObjectModel inner classes.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Node;

######################################################################
# Note: For now, the SQL::ObjectModel object that a Node belongs to is 
# set when the Node is first created, and may not be changed later, such 
# as with initialize().

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	unless( UNIVERSAL::isa($_[0],'SQL::ObjectModel') ) {
		die "fatal source code error: no ObjectModel to put new Node in";
	}
	$self->{$PROP_NODE_CONTAINER} = shift( @_ );
	$self->_initialize( @_ );
	return( $self );
}

sub initialize {
	my $self = shift( @_ );
	%{$self} = ($PROP_NODE_CONTAINER => $self->{$PROP_NODE_CONTAINER});
	$self->_initialize( @_ );
}

sub clone {
	my ($self, $clone) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );
	$clone->{$PROP_NODE_CONTAINER} = $self->{$PROP_NODE_CONTAINER};
	$clone->_initialize( $self );
	return( $clone );
}

######################################################################

sub _initialize {} # placeholder for subclass to override

######################################################################

sub get_containing_object_model {
	# Returns reference to ObjectModel that contains this Node.
	return( $_[0]->{$PROP_NODE_CONTAINER} );
}

######################################################################

sub DESTROY {
	# This is supposed to remove circular references, although it may 
	# never be called; the complement refs may need removing instead.
	$_[0]->{$PROP_NODE_CONTAINER} = undef;
}

######################################################################
######################################################################
# The class SQL::ObjectModel::_::DataType is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::DataType;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################

sub _initialize {
	my ($self, $initializer) = @_;

	if( ref($initializer) eq ref($self) or ref($initializer) eq 'HASH' ) {
		$self->{$PROP_DATP_NAME}   = $initializer->{$PROP_DATP_NAME} || 'No_Name_Data_Type';
		$self->{$PROP_DATP_BATP}   = $initializer->{$PROP_DATP_BATP} || $DATP_STRING;
		$self->{$PROP_DATP_SIBY}   = $initializer->{$PROP_DATP_SIBY};
		$self->{$PROP_DATP_SICH}   = $initializer->{$PROP_DATP_SICH};
		$self->{$PROP_DATP_SIDI}   = $initializer->{$PROP_DATP_SIDI};
		$self->{$PROP_DATP_STFX}   = $initializer->{$PROP_DATP_STFX};
		$self->{$PROP_DATP_S_ENC}  = $initializer->{$PROP_DATP_S_ENC};
		$self->{$PROP_DATP_S_TRWH} = $initializer->{$PROP_DATP_S_TRWH};
		$self->{$PROP_DATP_S_LTCS} = $initializer->{$PROP_DATP_S_LTCS};
		$self->{$PROP_DATP_S_PDCH} = $initializer->{$PROP_DATP_S_PDCH};
		$self->{$PROP_DATP_S_TRPD} = $initializer->{$PROP_DATP_S_TRPD};
		$self->{$PROP_DATP_N_UNSG} = $initializer->{$PROP_DATP_N_UNSG};
		$self->{$PROP_DATP_N_PREC} = $initializer->{$PROP_DATP_N_PREC};
		$self->{$PROP_DATP_D_CAL}  = $initializer->{$PROP_DATP_D_CAL};

	} else {
		$self->{$PROP_DATP_NAME} = 'No_Name_Data_Type';
		$self->{$PROP_DATP_BATP} = $initializer || $DATP_STRING;
		$self->{$PROP_DATP_SIBY} = 250;
	}

	unless( $self->{$PROP_DATP_SIBY} or $self->{$PROP_DATP_SICH} or $self->{$PROP_DATP_SIDI} ) {
		my $basic_type = $self->{$PROP_DATP_BATP};
		$basic_type eq $DATP_BINARY and $self->{$PROP_DATP_SIBY} = 250;
		$basic_type eq $DATP_STRING and $self->{$PROP_DATP_SICH} = 250;
		$basic_type eq $DATP_NUMBER and $self->{$PROP_DATP_SIBY} = 4;
	}
}

######################################################################

sub get_all_properties {
	my ($self) = @_;
	return( {
		$PROP_DATP_NAME   => $self->{$PROP_DATP_NAME},
		$PROP_DATP_BATP   => $self->{$PROP_DATP_BATP},
		$PROP_DATP_SIBY   => $self->{$PROP_DATP_SIBY},
		$PROP_DATP_SICH   => $self->{$PROP_DATP_SICH},
		$PROP_DATP_SIDI   => $self->{$PROP_DATP_SIDI},
		$PROP_DATP_STFX   => $self->{$PROP_DATP_STFX},
		$PROP_DATP_S_ENC  => $self->{$PROP_DATP_S_ENC},
		$PROP_DATP_S_TRWH => $self->{$PROP_DATP_S_TRWH},
		$PROP_DATP_S_LTCS => $self->{$PROP_DATP_S_LTCS},
		$PROP_DATP_S_PDCH => $self->{$PROP_DATP_S_PDCH},
		$PROP_DATP_S_TRPD => $self->{$PROP_DATP_S_TRPD},
		$PROP_DATP_N_UNSG => $self->{$PROP_DATP_N_UNSG},
		$PROP_DATP_N_PREC => $self->{$PROP_DATP_N_PREC},
		$PROP_DATP_D_CAL  => $self->{$PROP_DATP_D_CAL},
	} );
}

######################################################################

sub name {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_NAME} = $new_value;
	}
	return( $self->{$PROP_DATP_NAME} );
}

######################################################################

sub basic_type {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_BATP} = $new_value;
	}
	return( $self->{$PROP_DATP_BATP} );
}

######################################################################

sub size_in_bytes {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_SIBY} = int( $new_value );
	}
	return( $self->{$PROP_DATP_SIBY} );
}

sub size_in_chars {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_SICH} = int( $new_value );
	}
	return( $self->{$PROP_DATP_SICH} );
}

sub size_in_digits {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_SIDI} = int( $new_value );
	}
	return( $self->{$PROP_DATP_SIDI} );
}

######################################################################

sub store_fixed {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_STFX} = ($new_value ? 1 : 0);
	}
	return( $self->{$PROP_DATP_STFX} );
}

######################################################################

sub str_encoding {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_S_ENC} = $new_value;
	}
	return( $self->{$PROP_DATP_S_ENC} );
}

sub str_trim_white {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_S_TRWH} = ($new_value ? 1 : 0);
	}
	return( $self->{$PROP_DATP_S_TRWH} );
}

sub str_latin_case {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_S_LTCS} = $new_value;
	}
	return( $self->{$PROP_DATP_S_LTCS} );
}

sub str_pad_char {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_S_PDCH} = $new_value;
	}
	return( $self->{$PROP_DATP_S_PDCH} );
}

sub str_trim_pad {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_S_TRPD} = ($new_value ? 1 : 0);
	}
	return( $self->{$PROP_DATP_S_TRPD} );
}

######################################################################

sub num_unsigned {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_N_UNSG} = ($new_value ? 1 : 0);
	}
	return( $self->{$PROP_DATP_N_UNSG} );
}

sub num_precision {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_N_PREC} = int( $new_value );
	}
	return( $self->{$PROP_DATP_N_PREC} );
}

######################################################################

sub datetime_calendar {
	my ($self, $new_value) = @_;
	if( defined( $new_value ) ) {
		$self->{$PROP_DATP_D_CAL} = $new_value;
	}
	return( $self->{$PROP_DATP_D_CAL} );
}

######################################################################

sub valid_basic_types {
	my (undef, $type) = @_;
	return( defined($type) ? $DATP_BASIC_TYPES{$type} : {%DATP_BASIC_TYPES} );
}

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Database is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Database;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################

sub new_namespace {
	return( SQL::ObjectModel::_::Namespace->new( @_ ) );
}

sub new_user {
	return( SQL::ObjectModel::_::User->new( @_ ) );
}

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Command is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Command;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Namespace is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Namespace;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################

sub new_table {
	return( SQL::ObjectModel::_::Table->new( @_ ) );
}

sub new_view {
	return( SQL::ObjectModel::_::View->new( @_ ) );
}

sub new_sequence {
	return( SQL::ObjectModel::_::Sequence->new( @_ ) );
}

sub new_block {
	return( SQL::ObjectModel::_::Block->new( @_ ) );
}

######################################################################
######################################################################
# The class SQL::ObjectModel::_::User is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::User;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Table is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Table;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################

sub new_trigger {
	return( SQL::ObjectModel::_::Trigger->new( @_ ) );
}

######################################################################
######################################################################
# The class SQL::ObjectModel::_::View is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::View;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Sequence is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Sequence;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Block is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Block;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################
######################################################################
# The class SQL::ObjectModel::_::Trigger is declared here.

package  # Break line so PAUSE doesn't index this inner class.
	SQL::ObjectModel::_::Trigger;
use vars qw(@ISA);
@ISA = qw( SQL::ObjectModel::_::Node );

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

This class has a number of inner classes that do most of the work.  Here are
some examples of their use.

=head2 SQL::ObjectModel::DataType - Metadata for atomic or scalar values

	my %data_types = map { 
			( $_->{name}, SQL::ObjectModel::DataType->new( $_ ) ) 
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

=head2 SQL::ObjectModel::Table - Describe a single database table

	my %table_info = map { 
			( $_->{name}, SQL::ObjectModel::Table->new( $_ ) ) 
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

=head2 SQL::ObjectModel::View - Describe a single database view or select query

	my %view_info = map { 
			( $_->{name}, SQL::ObjectModel::View->new( $_ ) ) 
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

This Perl 5 object class contains a number of inner classes which do most of
its work.  All objects of these classes are pure containers that can be
serialized or stored indefinately off site for later retrieval and use, such as
in a data dictionary.  See the file lib/SQL/ObjectModel/DataDictionary.pod for 
an example of doing this.

This is the logical organization of the classes in this module:

	+-objectmodel
	   +-datatype
	   +-database
	   |  +-namespace
	   |  |  +-table
	   |  |  |  +-trigger
	   |  |  |     +-block
	   |  |  +-view
	   |  |  |  +-view
	   |  |  +-sequence    
	   |  |  +-block
	   |  |     +-block
	   |  +-user
	   +-command
	      +-view
	      +-block

=head1 SYNTAX

These classes do not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 DEPRECATED POD: INNER CLASSES

=head2 SQL::ObjectModel::DataType

Each SQL::ObjectModel::DataType object describes a simple data type, which
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

It is intended that the SQL::ObjectModel and your application would always
describe data types for columns in terms of these objects; the base types were
named after what programmers are used to casting program variables as so they
would be easy to adapt.  This is an alternative to RDBMS specific terms like
"varchar2(40)" or "number(6)" or "text" or "blob(4000)", which you would have
to change for each database; the Rosetta::Driver::* modules (or other modules
of your choice) are the only ones that need to know what the database uses
internally.  Of course, if you prefer the SQL terms, you can easily name your
DataType objects after them.

=head2 SQL::ObjectModel::Table

Each SQL::ObjectModel::Table object describes a single database table, and would
be used for such things as managing schema for the table (eg: create, alter,
destroy), and describing the table's "public interface" so other functionality
like views or various DML operations know how to use the table. In its simplest
sense, a Table object consists of a table name, a list of table columns, a list
of keys, a list of constraints, and a few other implementation details.  This
class does not describe anything that is changed by DML activity, such as a
count of stored records, or the current values of sequences attached to
columns.  This class would be used both when manipulating database schema and
when manipulating database data.

This class can generate SQL::ObjectModel::Command objects having types of:
'table_verify', 'table_create', 'table_alter', 'table_destroy'.

=head2 SQL::ObjectModel::View

Each SQL::ObjectModel::View object describes a single database view, which
conceptually looks like a table, but it is used differently.  Tables and views
are similar in that they both represent or store a matrix of data, which has
uniquely identifiable columns, and rows which can be uniquely identifiable but
may not be.  With the way that SQL::ObjectModel implements views, you can do all of the
same DML operations with them that you can do with tables: select, insert,
update, delete rows; that said, the process for doing any of those with views
is more complicated than with tables, but this complexity is usually internal
to SQL::ObjectModel so you shouldn't have to code any differently between them.  Tables
and views are different in that tables actually store data in themselves, while
views don't.  A view is actually a custom abstracted interface to one or more
database tables which are related to each other in a specific way; when you
issue DML against a view, you are actually fetching from or modifying the data
stored in one (simplest case) or more tables.

Views are also conceptually just select queries (and with some RDBMS systems,
that is exactly how they are stored), but SQL::ObjectModel::View objects have
enough meta-data so that if a program wants to, for example, modify a row
selected through one, SQL::ObjectModel could calculate which composite table rows to
update (views built in to RDBMS systems are typically read-only by contrast). 
Given that SQL::ObjectModel views are used mainly just for DML, they do not need to be
stored in a database like a table, and so they do not need to have names like
tables do.  However, if you want to store a view in the database like an RDBMS
native view, for added select performance, this class will let you associate a
name with one.

This class does not describe anything that is changed by DML activity, such as
a count of stored records.  This class can be used both when manipulating
database schema (stored RDBMS native views) and when manipulating database data
(normal use).

This class can generate SQL::ObjectModel::Command objects having types of:
'data_select', 'data_insert', 'data_update', 'data_delete', 'data_lock',
'data_unlock', 'view_verify', 'view_create', 'view_alter', 'view_destroy'.

=head1 DEPRECATED POD: CLASS PROPERTIES

=head2 SQL::ObjectModel::DataType

These are the conceptual properties of a SQL::ObjectModel::DataType object:

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
limited to a pre-defined set of values which are what any SQL::ObjectModel
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

=head2 SQL::ObjectModel::Table

These are the conceptual properties of a SQL::ObjectModel::Table object:

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

=head2 SQL::ObjectModel::View

These are the conceptual properties of a SQL::ObjectModel::View object:

=over 4

=item 0

I<This documentation is not written yet.>

=back

=head1 SEE ALSO

perl(1), SQL::ObjectModel::DataDictionary, SQL::ObjectModel::API_C, 
Rosetta, Rosetta::Framework, DBI.

=cut
