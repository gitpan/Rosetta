=head1 NAME

Rosetta - Framework for RDBMS-generic apps and schemas

=cut

######################################################################

package Rosetta;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.10';

use Locale::KeyedText 0.03;
use SQL::SyntaxModel 0.13;

######################################################################

=head1 DEPENDENCIES

Perl Version: 5.006

Standard Modules: I<none>

Nonstandard Modules: 

	Locale::KeyedText 0.03 (for error messages)
	SQL::SyntaxModel 0.13

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

Linking Rosetta statically or dynamically with other modules is making a
combined work based on Rosetta.  Thus, the terms and conditions of the GPL
cover the whole combination.  As a special exception, the copyright holders of
Rosetta give you permission to link Rosetta with independent modules,
regardless of the license terms of these independent modules, and to copy and
distribute the resulting combined work under terms of your choice, provided
that every copy of the combined work is accompanied by a complete copy of the
source code of Rosetta (the version of Rosetta used to produce the combined
work), being distributed under the terms of the GPL plus this exception.  An
independent module is a module which is not derived from or based on Rosetta,
and which is fully useable when not linked to Rosetta in any form.

Any versions of Rosetta that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits.
Rosetta is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of
suggesting improvements to the standard version.

=cut

######################################################################
######################################################################

# Names of properties for objects of the Rosetta::Interface class are declared here:
my $IPROP_INTF_TYPE = 'intf_type'; # str (enum) - what type of Interface this is, no chg once set
	# The Interface Type is the only property which absolutely can not change, and is set when object created.
my $IPROP_ERROR_MSG = 'error_msg'; # object (Locale::KeyedText::Message) - details of a 
	# failure, or at least any that might be useful to a generic application error handler; 
	# if there was no error condition, then this is undefined/null
	# This property is mandatory for Error Interfaces, and optional for other Interfaces
my $IPROP_PARENT_INTF = 'parent_intf'; # ref to parent Interface, which provides a context 
	# for the current one, unless the current Interface is a root
my $IPROP_CHILD_INTFS = 'child_intfs'; # array - list of refs to child Interfaces that the 
	# current one spawned and provides a context for; this may or may not be useful in practice, 
	# and it does set up a circular ref problem such that all Interfaces in a tree will not be 
	# destroyed until their root Interface is, unless this is done explicitly
my $IPROP_ENGINE = 'engine'; # ref to Engine implementing this Interface if any
	# This Engine object would store its own state internally, which includes such things 
	# as various DBI dbh/sth/rv handles where appropriate, and any generated SQL to be 
	# generated, as well as knowledge of how to translate named bind params to positional ones.
	# The Engine object would never store a reference to the Interface object that it 
	# implements, as said Interface object would pass a reference to itself as an argument 
	# to any Engine methods that it invokes.  Of course, if this Engine implements a 
	# middle-layer and invokes another Interface/Engine tree of its own, then it would store 
	# a reference to that Interface like an application would.
my $IPROP_SSM_NODE = 'ssm_node'; # ref to SQL::SyntaxModel Node providing context for this Intf
	# If we are an 'application' Interface, this would be an 'application_instance' Node.
	# If we are a 'preparation' Interface, this would be a 'command' or 'routine' Node.
	# If we are any other kind of interface, this is a second ref to same SSM the parent 'prep' has.
my $IPROP_THROW_ERRORS = 'throw_errors'; # boolean - true means that Interface objects will be 
	# thrown by prepare/execute methods if they are errors, false means return all Interface objs

# Names of properties for objects of the Rosetta::Engine class are declared here:
	 # No properties (yet) are declared by this parent class; leaving space free for child classes

# Names of the allowed Interface types go here:
my $INTFTP_ERROR       = 'error'; # What is returned if an error happens, in place of another Intf type
my $INTFTP_APPLICATION = 'application'; # What you get when you create an Interface out of any context
	# This type is the root of an Interface tree; when you create one, you provide an 
	# "application_instance" SQL::SyntaxModel Node; that provides the necessary context for 
	# subsequent "command" or "routine" Nodes you pass to any child Intf's "prepare" method.
my $INTFTP_PREPARATION = 'preparation'; # That which is returned by the 'prepare()' method
my $INTFTP_ENVIRONMENT = 'environment'; # Parent to all CONNECTION INTFs impl by same engine
my $INTFTP_CONNECTION  = 'connection'; # Result of executing a 'connect' command
my $INTFTP_TRANSACTION = 'transaction'; # Result of asking to start a new transaction
my $INTFTP_CURSOR      = 'cursor'; # Result of executing a query that would return rows to the caller
my $INTFTP_ROW         = 'row'; # Result of executing a query that returns one row
my $INTFTP_LITERAL     = 'literal'; # Result of execution that isn't one of the above, like an IUD
my %ALL_INTFTP = ( map { ($_ => 1) } (
	$INTFTP_ERROR, $INTFTP_APPLICATION, $INTFTP_PREPARATION, 
	$INTFTP_ENVIRONMENT, $INTFTP_CONNECTION, $INTFTP_TRANSACTION, 
	$INTFTP_CURSOR, $INTFTP_ROW, $INTFTP_LITERAL, 
) );

# Names of SQL::SyntaxModel-recognized enumerated values such as Node types go here:
my $SSNNTP_APPINST = 'application_instance';
my $SSNNTP_COMMAND = 'command';
my $SSNNTP_ROUTINE = 'routine';

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	# Throws an exception consisting of an object.
	die Locale::KeyedText->new_message( $error_code, $args );
}

######################################################################
# This is a convenience wrapper method; its sole argument is a SSM Node.

sub new_application {
	return( Rosetta::Interface->new( $INTFTP_APPLICATION, undef, undef, undef, $_[1] ) );
}

######################################################################
######################################################################

package Rosetta::Interface;
use base qw( Rosetta );

######################################################################

sub new {
	# Make a new Interface with basically all props set now and not changed later.
	my ($class, $intf_type, $err_msg, $parent_intf, $engine, $ssm_node) = @_;
	my $interface = bless( {}, ref($class) || $class );

	$interface->_validate_properties_to_be( $intf_type, $err_msg, $parent_intf, $engine, $ssm_node );

	unless( $intf_type eq $INTFTP_ERROR ) {
		# If type was Application or Preparation, $ssm_node would already be set.
		# Anything else except Error has a parent.
		$ssm_node ||= $parent_intf->{$IPROP_SSM_NODE}; # Copy from parent Preparation if applicable.
	}
	$interface->{$IPROP_INTF_TYPE} = $intf_type;
	$interface->{$IPROP_ERROR_MSG} = $err_msg;
	$interface->{$IPROP_PARENT_INTF} = $parent_intf;
	$interface->{$IPROP_CHILD_INTFS} = [];
	$interface->{$IPROP_ENGINE} = $engine;
	$interface->{$IPROP_SSM_NODE} = $ssm_node;
	$interface->{$IPROP_THROW_ERRORS} = $parent_intf ? $parent_intf->{$IPROP_THROW_ERRORS} : 0;
	$parent_intf and push( @{$parent_intf->{$IPROP_CHILD_INTFS}}, $interface );

	return( $interface );
}

sub _validate_properties_to_be {
	my ($interface, $intf_type, $err_msg, $parent_intf, $engine, $ssm_node) = @_;

	# Check $intf_type, which is mandatory.
	defined( $intf_type ) or $interface->_throw_error_message( 'ROS_I_NEW_INTF_NO_TYPE' );
	unless( $ALL_INTFTP{$intf_type} ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_TYPE', { 'TYPE' => $intf_type } );
	}

	# Check $err_msg, which is not mandatory except when type is Error.
	if( defined( $err_msg ) ) {
		unless( UNIVERSAL::isa( $err_msg, 'Locale::KeyedText::Message' ) ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_ERR', { 'ERR' => $err_msg } );
		}
	} else {
		$intf_type eq $INTFTP_ERROR and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_NO_ERR', { 'TYPE' => $intf_type } );
	}

	# Check $parent_intf, which must not be set when type is Error/Application, must be set otherwise.
	if( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_APPLICATION ) {
		defined( $parent_intf ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_PARENT', { 'TYPE' => $intf_type } );
	} else {
		$interface->_validate_parent_intf( $intf_type, $parent_intf );
	}

	# Check $engine, which must not be set when type is Error/Application, must be set otherwise.
	if( $intf_type eq $INTFTP_ERROR or $intf_type eq $INTFTP_APPLICATION ) {
		defined( $engine ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_ENG', { 'TYPE' => $intf_type } );
	} else {
		defined( $engine ) or $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_NO_ENG', { 'TYPE' => $intf_type } );
		unless( UNIVERSAL::isa( $engine, 'Rosetta::Engine' ) ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_ENG', { 'ENG' => $engine } );
		}
	}

	# Check $ssm_node, must be given for Application or Preparation, must not be given otherwise (incl Error).
	# $ssm_node is always set to its parent Preparation when arg must not be given, except when Error.
	if( $intf_type eq $INTFTP_APPLICATION ) {
		$interface->_validate_ssm_node( $ssm_node, $intf_type );
		my $node_type = $ssm_node->get_node_type();
		unless( $node_type eq $SSNNTP_APPINST ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_NODE_TYPE_NOT_SUPP', 
				{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type } );
		}
	} elsif( $intf_type eq $INTFTP_PREPARATION ) {
		$interface->_validate_ssm_node( $ssm_node, $intf_type, $parent_intf );
		my $node_type = $ssm_node->get_node_type();
		unless( $node_type eq $SSNNTP_COMMAND or $node_type eq $SSNNTP_ROUTINE ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_NODE_TYPE_NOT_SUPP', 
				{ 'NTYPE' => $node_type, 'ITYPE' => $intf_type } );
		}
	} else {
		defined( $ssm_node ) and $interface->_throw_error_message( 
			'ROS_I_NEW_INTF_YES_NODE', { 'TYPE' => $intf_type } );
	}

	# All properties to be seem to check out fine.
}

sub _validate_parent_intf {
	my ($interface, $intf_type, $parent_intf) = @_;

	# First check that the given $parent_intf is an Interface at all.
	defined( $parent_intf ) or $interface->_throw_error_message( 
		'ROS_I_NEW_INTF_NO_PARENT', { 'TYPE' => $intf_type } );
	unless( UNIVERSAL::isa( $parent_intf, 'Rosetta::Interface' ) ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_PARENT', { 'PAR' => $parent_intf } );
	}
	my $p_intf_type = $parent_intf->{$IPROP_INTF_TYPE};

	# Now check that we may be a child of the given $parent_intf.
	if( $intf_type eq $INTFTP_PREPARATION ) {
		unless( $p_intf_type eq $INTFTP_APPLICATION or $p_intf_type eq $INTFTP_ENVIRONMENT or 
				$p_intf_type eq $INTFTP_CONNECTION or $p_intf_type eq $INTFTP_TRANSACTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_P_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type } );
		}
		return( 1 ); # Skip the other tests
	}
	unless( $p_intf_type eq $INTFTP_PREPARATION ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_P_INCOMP', 
			{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type } );
	}

	# If we get here then at the very least we have an 'application' and 'preparation' above us.
	# Now check that we may be a grand-child of the parent of the given $parent_intf.
	my $pp_intf_type = $parent_intf->{$IPROP_PARENT_INTF}->{$IPROP_INTF_TYPE};
	if( $intf_type eq $INTFTP_ENVIRONMENT ) {
		unless( $pp_intf_type eq $INTFTP_APPLICATION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} elsif( $intf_type eq $INTFTP_CONNECTION ) {
		unless( $pp_intf_type eq $INTFTP_ENVIRONMENT ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} elsif( $intf_type eq $INTFTP_TRANSACTION ) {
		unless( $pp_intf_type eq $INTFTP_CONNECTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	} else {
		unless( $pp_intf_type eq $INTFTP_TRANSACTION ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_PP_INCOMP', 
				{ 'TYPE' => $intf_type, 'PTYPE' => $p_intf_type, 'PPTYPE' => $pp_intf_type } );
		}
	}

	# $parent_intf seems to check out fine.
}

sub _validate_ssm_node {
	my ($interface, $ssm_node, $intf_type, $parent_intf) = @_;
	defined( $ssm_node ) or $interface->_throw_error_message( 
		'ROS_I_NEW_INTF_NO_NODE', { 'TYPE' => $intf_type } );
	unless( UNIVERSAL::isa( $ssm_node, 'SQL::SyntaxModel::Node' ) ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_BAD_NODE', { 'SSM' => $ssm_node } );
	}
	my $given_container = $ssm_node->get_container();
	unless( $given_container ) {
		$interface->_throw_error_message( 'ROS_I_NEW_INTF_NODE_NOT_IN_CONT' );
	}
	if( $parent_intf ) {
		my $expected_container = $parent_intf->{$IPROP_SSM_NODE}->get_container();
		# Above line assumes parent Intf's Node not taken from Container since put in parent.
		if( $given_container ne $expected_container ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_NODE_NOT_SAME_CONT' );
		}
	}
	# $ssm_node seems to check out fine.
}

######################################################################

sub destroy {
	# Since we probably have circular refs, we must explicitly be destroyed.
	my ($interface) = @_;

	# For simplicity, require that caller destroys our children first.
	if( @{$interface->{$IPROP_CHILD_INTFS}} > 0 ) {
		$interface->_throw_error_message( 'ROS_I_DESTROY_HAS_CHILD' );
	}

	# First destroy Engine implementing ourself, if we have one and it is willing.
	if( $interface->{$IPROP_ENGINE} ) {
		$interface->{$IPROP_ENGINE}->destroy(); # may throw exception of its own
	}

	# Now break link from our parent Interface to ourself, if we have a parent.
	if( $interface->{$IPROP_PARENT_INTF} ) {
		my $siblings = $interface->{$IPROP_PARENT_INTF};
		@{$siblings} = grep { $_ ne $interface } @{$siblings}; # should only be one; break all
	}

	# Now break any links from ourself to other things, and destroy ourself.
	%{$interface} = ();

	# Finally, once any external refs to us are gone, we get garbage collected.
}

######################################################################

sub get_interface_type {
	return( $_[0]->{$IPROP_INTF_TYPE} );
}

######################################################################

sub get_error_message {
	# This method returns the Message object by reference.
	return( $_[0]->{$IPROP_ERROR_MSG} );
}

######################################################################

sub get_parent_interface {
	# This method returns the Interface object by reference.
	return( $_[0]->{$IPROP_PARENT_INTF} );
}

######################################################################

sub get_child_interfaces {
	# This method returns each Interface object by reference.
	return( [@{$_[0]->{$IPROP_CHILD_INTFS}}] );
}

######################################################################
# We may not keep this method

sub get_engine {
	return( $_[0]->{$IPROP_ENGINE} );
}

######################################################################

sub get_ssm_node {
	# This method returns the Node object by reference.
	return( $_[0]->{$IPROP_SSM_NODE} );
}

######################################################################

sub throw_errors {
	my ($interface, $new_value) = @_;
	if( defined( $new_value ) ) {
		unless( $new_value eq '0' or $new_value eq '1' ) {
			$interface->_throw_error_message( 'ROS_I_THROW_ERR_BAD_ARG', { 'ARG' => $new_value } );
		}
		$interface->{$IPROP_THROW_ERRORS} = $new_value;
	}
	return( $interface->{$IPROP_THROW_ERRORS} );
}

######################################################################

sub prepare {
	my ($interface, $command) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $interface->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_APPLICATION or $intf_type eq $INTFTP_ENVIRONMENT or 
			$intf_type eq $INTFTP_CONNECTION or $intf_type eq $INTFTP_TRANSACTION ) {
		$interface->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'prepare', 'TYPE' => $intf_type } );
	}
	# From this point onward, an Interface object will be made, and any errors will go in it.
	my $preparation = undef;
	eval {
		# This test of our SSM Node argument is a bootstrap of sorts; the Interface->new() 
		# method will do the same tests when it is called later; return same errors it would have.
		$interface->_validate_ssm_node( $command, $intf_type, $interface );
		my $node_type = $command->get_node_type();
		unless( $node_type eq $SSNNTP_COMMAND or $node_type eq $SSNNTP_ROUTINE ) {
			$interface->_throw_error_message( 'ROS_I_NEW_INTF_NODE_TYPE_NOT_SUPP', { 'TYPE' => $node_type } );
		}
		# Now we get to doing the real work we were called for.
		if( $intf_type eq $INTFTP_APPLICATION ) {
			$preparation = $interface->_prepare_with_no_engine( $command );
		} else {
			$preparation = $interface->{$IPROP_ENGINE}->prepare( $command );
		}
	};
	if( my $exception = $@ ) {
		if( UNIVERSAL::isa( $exception, 'Rosetta::Interface' ) ) {
			# The called code threw a Rosetta::Interface object.
			$preparation = $exception;
		} elsif( UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			# The called code threw a Locale::KeyedText Message object.
			$preparation = $interface->new( $INTFTP_ERROR, $exception );
		} else {
			# The called code died in some other way (means coding error, not user error).
			$preparation = $interface->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_PREPARE_MISC_EXCEPTION', { 'VALUE' => $exception, 'ITYPE' => $intf_type } ) );
		}
	} else {
		unless( UNIVERSAL::isa( $preparation, 'Rosetta::Interface' ) ) {
			# The called code didn't die, but didn't return a Rosetta::Interface object either.
			$preparation = $interface->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_PREPARE_BAD_RESULT', { 'VALUE' => $preparation, 'ITYPE' => $intf_type } ) );
		}
	}
	if( $preparation->get_error_message() and $interface->{$IPROP_THROW_ERRORS} ) {
		die $preparation;
	}
	return( $preparation );
}

sub _prepare_with_no_engine {
	my ($application, $command) = @_;
	my $preparation = undef;

	# ... Here we first analyse $command to figure out which Rosetta Engine 
	# modules we should load and create "Environment" Interfaces for; 
	# eg: a "database open" command will require just one, while 
	# a "database list" command will require all available Engines 
	# indicated in the SSM Model's "tools" section.

	# ... Each "Environment" Interface object and corresponding Engine object 
	# will be created by the newly required Engine module.

	# ... If we called "database list" then invoke each Engine with that same 
	# command and then collate the results into one set of SSM nodes, or something.

	# ... If we called "database open" then invoke one Engine to create a 
	# Connection Interface/Engine etcetera.

	return( $preparation );
}

######################################################################

sub execute {
	my ($preparation, $bind_vars) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $preparation->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_PREPARATION ) {
		$preparation->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'execute', 'TYPE' => $intf_type } );
	}
	# From this point onward, an Interface object will be made, and any errors will go in it.
	my $result = undef;
	eval {
		# Now we get to doing the real work we were called for.
		$result = $preparation->{$IPROP_ENGINE}->execute( $bind_vars );
	};
	if( my $exception = $@ ) {
		if( UNIVERSAL::isa( $exception, 'Rosetta::Interface' ) ) {
			# The called code threw a Rosetta::Interface object.
			$result = $exception;
		} elsif( UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			# The called code threw a Locale::KeyedText Message object.
			$result = $preparation->new( $INTFTP_ERROR, $exception );
		} else {
			# The called code died in some other way (means coding error, not user error).
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_MISC_EXCEPTION', { 'VALUE' => $exception, 'ITYPE' => $intf_type } ) );
		}
	} else {
		unless( UNIVERSAL::isa( $result, 'Rosetta::Interface' ) ) {
			# The called code didn't die, but didn't return a Rosetta::Interface object either.
			$result = $preparation->new( $INTFTP_ERROR, Locale::KeyedText->new_message( 
				'ROS_I_EXECUTE_BAD_RESULT', { 'VALUE' => $result, 'ITYPE' => $intf_type } ) );
		}
	}
	if( $result->get_error_message() and $preparation->{$IPROP_THROW_ERRORS} ) {
		die $result;
	}
	return( $result );
}

######################################################################

sub finalize {
	my ($cursor) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $cursor->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$cursor->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'finalize', 'TYPE' => $intf_type } );
	}
	# do the equivalent of CURSOR_CLOSE here
}

######################################################################

sub has_more_rows {
	my ($cursor) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $cursor->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$cursor->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'has_more_rows', 'TYPE' => $intf_type } );
	}
	# do the equivalent of CURSOR_FETCH here
	# returns undef if there are no more rows or on error
}

######################################################################

sub fetch_row {
	my ($cursor) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $cursor->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$cursor->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'fetch_row', 'TYPE' => $intf_type } );
	}
	# do the equivalent of CURSOR_FETCH here
	# returns undef if there are no more rows or on error
}

######################################################################

sub fetch_all_rows {
	my ($cursor) = @_;
	# First check that this method may be called on an Interface of this type.
	my $intf_type = $cursor->{$IPROP_INTF_TYPE};
	unless( $intf_type eq $INTFTP_CURSOR ) {
		$cursor->_throw_error_message( 'ROS_I_METH_NOT_SUPP', 
			{ 'METH' => 'fetch_all_rows', 'TYPE' => $intf_type } );
	}
	my $array_of_hashes = ();
	# now stuff it with a whole bunch of CURSOR_FETCH
	# then finalize()
	return( $array_of_hashes ); # empty array if no more rows, or undef on error
}

######################################################################
######################################################################

package Rosetta::Engine;
use base qw( Rosetta );

######################################################################
# These methods must be overridden by sub-classes; they simply die otherwise.

sub new {
	my ($class) = @_;
	$class->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'new', 'CLASS' => ref($class) || $class } );
	# Among other things, this is possibly where we bind to the Interface we implement.
}

sub destroy {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'destroy', 'CLASS' => ref($engine) } );
}

sub prepare {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'prepare', 'CLASS' => ref($engine) } );
}

sub execute {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'execute', 'CLASS' => ref($engine) } );
}

sub finalize {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'finalize', 'CLASS' => ref($engine) } );
}

sub has_more_rows {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'has_more_rows', 'CLASS' => ref($engine) } );
}

sub fetch_row {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'fetch_row', 'CLASS' => ref($engine) } );
}

sub fetch_all_rows {
	my ($engine, $interface) = @_;
	$engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', 
		{ 'METH' => 'fetch_all_rows', 'CLASS' => ref($engine) } );
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<Note: Look at the SQL::SyntaxModel (SSM) documentation for examples of how to
construct the various SQL commands / Node groups used in this SYNOPSIS.>

	use Rosetta; # Module also 'uses' SQL::SyntaxModel and Locale::KeyedText.

	my $schema_model = SQL::SyntaxModel->new_container(); # global for a simpler illustration, not reality

	main();

	$schema_model->destroy(); # so we don't leak memory

	sub main {
		# ... Next create and stuff Nodes in $schema_model that represent the application 
		# blueprint and instance thereof that we are.  Then put a 'application_instance' 
		# Node for said instance in $application_instance.

		my $application = Rosetta->new_application( $application_instance );

		do_connection( $application );

		$application->destroy(); # so we don't leak memory
	}

	sub do_connection {
		my ($application) = @_;

		# ... Next create and stuff Nodes in $schema_model that represent the database we want 
		# to use (including what data storage product it is) and how we want to link/connect 
		# to it (including what Rosetta "engine" plug-in and DSN to use).  Then put a 'command' 
		# Node which instructs to open a connection with said database in $open_db_command.

		my $prepared_open_cmd = $application->prepare( $open_db_command );
		if( $prepared_open_cmd->get_error_message() ) {
			print "internal error: a command is invalid: ".error_to_string( $prepared_open_cmd );
			return( 0 );
		}

		while( 1 ) {
			# ... Next, assuming they are gotten dynamically such as from the user, gather the db 
			# authentication credentials, username and password, and put them in $user and $pass.

			my $db_conn = $prepared_open_cmd->execute( { 'login_user' => $user, 'login_pass' => $pass } );

			unless( $db_conn->get_error_message() ) {
				last; # Connection was successful.
			}

			# If we get here, something went wrong when trying to open the database; eg: the requested 
			# engine plug-in doesn't exist, or the DSN doesn't exist, or the user/pass are incorrect.  

			my $error_message = $db_conn->get_error_message();

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
		my $message = $interface->get_error_message();
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
		if( $result->get_error_message() ) {
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
		if( $result->get_error_message() ) {
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
			if( $result->get_error_message() ) {
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
		if( $get_one_cmd->get_error_message() ) {
			print "internal error: a command is invalid: ".error_to_string( $get_one_cmd );
			return( 0 );
		}
		my $row = $get_one_cmd->execute( { 'a_foo' => 'snowy' } );
		if( $row->get_error_message() ) {
			print "sorry, problem getting snowy: ".error_to_string( $result );
			return( 0 );
		}
		my $data = $row->row_data(); # $data is a hash-ref of tbl col name/val pairs.

		# ... Next create and stuff Nodes in $schema_model that represent a routine which 
		# selects all rows from 'stoff'.  Then put this 'routine' Node in $get_all_stoff_cmd.

		my $get_all_cmd = $db_conn->prepare( $get_all_stoff_cmd );
		if( $get_all_cmd->get_error_message() ) {
			print "internal error: a command is invalid: ".error_to_string( $get_all_cmd );
			return( 0 );
		}
		my $cursor = $get_all_cmd->execute();
		if( $cursor->get_error_message() ) {
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

The Rosetta Perl 5 module implements the core of the Rosetta database
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

The separately released SQL::SyntaxModel Perl 5 module is used by Rosetta
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
DBI framework created by Tim Bunce; in fact, many initial Rosetta engines
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

=head1 CLASSES IN THIS MODULE

This module is implemented by several object-oriented Perl 5 packages, each of
which is referred to as a class.  They are: B<Rosetta> (the module's name-sake), 
B<Rosetta::Interface> (aka B<Interface>), and B<Rosetta::Engine> (aka B<Engine>).

I<While all 3 of the above classes are implemented in one module for
convenience, you should consider all 3 names as being "in use"; do not create
any modules or packages yourself that have the same names.>

The Interface class does most of the work and is what you mainly use.  The
name-sake class mainly exists to guide CPAN in indexing the whole module, but
it also provides a set of stateless utility methods and constants that the
other two classes inherit, and it provides a wrapper function over the
Interface class for your convenience; you never instantiate an object of
Rosetta itself.  The Engine class is only invoked indirectly, via the Interface
class; moreover, you need to choose an external class which subclasses Engine
(and implements all of its methods) to use via the Interface class.

=head1 STRUCTURE

The Rosetta core module is structured like a simple virtual machine, which can
be conceptually thought of as implementing an embedded SQL database;
alternately, it is a command interpreter.  This module is implemented with 2
main classes that work together, which are "Interface" and "Engine".  To use
Rosetta, you first create a root Interface object (or several; one is normal)
using Rosetta->new_interface(), which provides a context in which you can
prepare and execute commands against a database or three.  One of your first
commands is likely to open a connection to a database, during which you
associate a separately available Engine plug-in of your choice with said
connection.  This Engine plug-in does all the meat of implementing the Rosetta
API that the Interface defines; the Engine class defined inside the Rosetta
core module is a simple common super-class for all Engine plug-in modules.

Note that each distinct Rosetta Engine class is represented by a distinct
SQL::SyntaxModel "data_link_product" Node that you create; you put the name of
the Rosetta Engine Class, such as "Rosetta::Engine::foo", in that Node's
"product_code" attribute.  The SQL::SyntaxModel documentation refers to that
attribute as being just for recognition by an external "mediation layer"; when
you use Rosetta, then Rosetta *is* said "mediation layer".

During the normal course of using Rosetta, you will end up talking to a whole
bunch of Interface objects, which are all related to each other in a tree-like
fashion.  Each time you prepare() or execute() a command against one, another
is typically spawned which represents the results of your command, be it an
error condition or a database connection handle or a transaction context handle
or a select cursor handle or a miscellaneous returned data container.  Each
Interface object has a "type" property which says what kind of thing it
represents and how it behaves.  All Interface types have a "get_error_message()" method
but only a cursor type, for example, has a "fetch_row()" method.  For
simplicity, all Interface objects are explicitly defined to have all possible
Interface methods (no "autoload" et al is used); however, an inappropriately
called method will throw an exception saying so, so it is as if Perl had a
normal run-time error due to calling a non-existent method.

Each Interface object may also have its own Engine object associated with it 
behind the scenes, with all the Engine objects in a mirroring tree structure; 
but that may not always be true.  One example is right when you start out, or 
if you try to open a database connection using a non-existent Engine module.

This diagram shows all of the Interface types and how they are allowed to 
relate to each other parent-child wise in an Interface tree:

	1	Application
	2	  Preparation
	3	    Environment
	4	      Preparation
	5	        Connection
	6	          Preparation
	7	            Transaction
	8	              Preparation
	9	                Cursor
	10	              Preparation
	11	                Row
	12	              Preparation
	13	                Literal
	14	Error

The "Application" (1) at the top is created using "Rosetta->new()", and you
normally have just one of those in your program.  A "Preparation"
(2,4,6,8,10,12) is created when you invoke "prepare()" off of an Interface
object of one of these types: "Application" (1), "Environment" (3), "Connection"
(5), "Transaction" (7).  Every type of Interface except "Application" and
"Preparation" is created by invoking "execute()" of of an appropriate
"Preparation" method.  The "prepare()" and "execute()" methods always create a
new Interface having the result of the call, and this is usually a child of the
one you invoked it from.  

An "Error" (14) Interface can be returned potentially by any method and it is
self-contained; it has no parent Interfaces or children.  Note that any other
kind of Interface can also store an error condition in addition to keeping its
normal properties.

For convenience, what often happens is that the Rosetta Engine will create
multiple Interface generations for you as appropriate when you say "prepare()".
For example, if you give a "open this database" command to an "Application" (1)
Interface, you would be given back a great-grand-child "Preparation" (4)
Interface.  Or, if you give a "select these rows" command to a "Connection"
Interface, you will be given back a great-grand-child "Preparation" (8)
Interface (which would re-use the last "Transaction" if one exists).  Be aware
of this if you ever request that an Interface you hold give you its parent.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 CONSTRUCTOR WRAPPER FUNCTIONS

These functions are stateless and can be invoked off of either the module name,
or any package name in this module, or any object created by this module; they
are thin wrappers over other methods and exist strictly for convenience.

=head2 new_application( SSM_NODE )

	my $app = SQL::SyntaxModel->new_application( $my_app_inst );
	my $app2 = SQL::SyntaxModel::Interface->new_application( $my_app_inst );
	my $app3 = $app->new_application( $my_app_inst );

This function wraps Rosetta::Interface->new( 'application', undef, undef,
undef, SSM_NODE ).  It can only create 'application' Interfaces, and its sole
SSM_NODE argument must be an 'application_instance' SQL::SyntaxModel::Node.

=head1 INTERFACE CONSTRUCTOR FUNCTIONS AND METHODS

This function/method is stateless and can be invoked off of either the Interface
class name or an existing Interface object, with the same result.

=head2 new( INTF_TYPE[, ERR_MSG][, PARENT_INTF][, ENGINE][, SSM_NODE] )

	my $app = Rosetta::Interface->new( 'application', undef, undef, undef, $my_app_inst );
	my $conn_prep = $app->new( 'preparation', undef, $app, undef, $conn_command );

This "getter" function/method will create and return a single
Rosetta::Interface (or subclass) object whose Interface Type is given in the
INTF_TYPE (enum) argument; all of the other properties will be set from the
remaining arguments depending on what the Interface Type is.  All of an
Interface's properties must be set on instantiation and can not be changed
afterwards, except when said Interface is destroyed (the Throw Errors property
is the lone exception).  The class works this way since each Interface object
is typically the result of invoking a method off another Interface object; the
new object contains the "result" of calling the method.  The ERR_MSG argument
holds a Locale::KeyedText::Message object; you set this when the new Interface
represents an error condition.  The PARENT_INTF argument holds another
Interface object which is to be the parent of the new one; typically it is the
Interface whose method was invoked to indirectly create the current one; every
Interface must have a parent unless it is an 'application', which must not have
one.  The ENGINE argument is an Engine object that will implement the new
Interface.  The SSM_NODE argument is a SQL::SyntaxModel::Node argument that
provides a context or instruction for how the new Interface is created; eg, it
contains the "command" which the new Interface mediates the result of.  This 
function will throw exceptions if any arguments are inappropriate in context.  
Typically this function is only invoked directly by the Engine object behind 
its parent-to-be Interface when said Interface is called with prepare/execute.  
The Throw Errors property defaults from the parent Interface, or to false.

=head1 INTERFACE OBJECT METHODS

These methods are stateful and may only be invoked off of Interface objects.

=head2 destroy()

	$interface->destroy();

This "setter" method will destroy the Interface object that it is invoked from,
and it will also destroy the Engine associated with the Interface, if any. 
This method will fail if the current Interface object has child Interfaces; you
have to destroy each of them first.

=head2 get_interface_type()

	my $type = $interface->get_interface_type();

This "getter" method returns the Interface Type scalar (enum) property of this
Interface.

=head2 get_error_message()

	my $message = $interface->get_error_message();

This "getter" method returns by reference the Error Message
Locale::KeyedText::Message object property of this Interface, if it has one.

=head2 get_parent_interface()

	my $parent = $interface->get_parent_interface();

This "getter" method returns by reference the parent Interface of this
Interface, if it has one.

=head2 get_child_interfaces()

	my $children = $interface->get_child_interfaces();

This "getter" method returns a new array ref having references to all of this
Interface's child Interfaces, or an empty array ref if there are no children.

=head2 get_engine()

	my $engine = $interface->get_engine();

This "getter" method returns by reference the Engine that implements this
Interface, if it has one.  I<This method may be removed later.>

=head2 get_ssm_node()

	my $node = $interface->get_ssm_node();

This "getter" method returns by reference the SQL::SyntaxModel::Node object
property of this Interface, if it has one.

=head2 throw_errors([ NEW_VALUE ])

This "getter"/"setter" method returns the Throw Errors scalar (boolean)
property of this object; if NEW_VALUE is defined and correct, then that
property will be set from it.  This property defaults to false, or to the same
value as this Interface's parent when it is created.  If it is true, then any
time you invoke prepare() or execute() off of it and they produce an
error-representing Interface, that error will be thrown as an exception rather
than be returned normally.

=head2 prepare( COMMAND )

This "getter"/"setter" method takes a SQL::SyntaxModel::Node object
representing either a "command" or a "routine" in its COMMAND argument, then
"compiles" it into a new "preparation" Interface (returned) which is ready to
execute the specified action.  This method may only be invoked off of
Interfaces having one of these types: "application", "environment",
"connection", "transaction"; it will throw an exception if you invoke it on
anything else.  Most of the time, this method just passes the buck to the
Engine module that actually does its work, after doing some basic input
checking, or it will instantiate an Engine object.  Any calls to Engine objects
are wrapped in an eval block so that miscellaneous exceptions generated there
don't kill the program.

=head2 execute([ BIND_VARS ])

This "getter"/"setter" method can only be invoked off of a "preparation"
Interface and will actually perform the action that the Interface is created
for.  The optional hash ref argument BIND_VARS provides run-time arguments 
for the previously "compiled" routine/command, if it takes any.  As with 
prepare(), most of the time this method just does basic input checking,  
calls an Engine module to do the actual work, wrapped in an eval block.

=head2 finalize()

This "setter" method can only be invoked off of a "cursor" Interface.  It will
close the cursor, indicating that you want no more data from it.  I<This method
may be removed in favor of destroy() accomplishing the task.  Or maybe not, as
we probably want a return value to indicate success.  Or maybe destroy can.>

=head2 has_more_rows()

This "getter" method can only be invoked off of a "cursor" Interface.  It will
return a boolean value where true means you can read more rows from the cursor, 
and false means that all the rows have been read.

=head2 fetch_row()

This "getter"/"setter" method can only be invoked off of a "cursor" Interface. 
It will fetch one more row from the cursor, if it can, and return that as a
hash ref where the hash keys are the column names and the values are the data;
the cursor will be advanced so repeated calls to fetch_row() will return
subsequent rows.

=head2 fetch_all_rows()

This "getter"/"setter" method can only be invoked off of a "cursor" Interface.
It will fetch all of the remaining rows from the cursor, returning them in an
array ref where each element is a row held in a hash-ref.  This method will
also finalize() the cursor, so you don't have to call that separately.

=head1 ENGINE OBJECT FUNCTIONS AND METHODS

Rosetta::Engine defines shims for all of the required Engine methods, each of
which will throw an exception if the sub-classing Engine module doesn't
override them.  These methods all have the same names and functions as
Interface methods, which just turn around and call them.  Every Engine method
takes as its first argument a reference to the Interface object that it is
implementing (the Interface shim provides it); otherwise, each method's
argument list is the same as its same-named Interface method.  These are the
methods: destroy(), prepare(), execute(), finalize(), has_more_rows(),
fetch_row(), fetch_all_rows().  Every Engine must also implement a new() method
which will be called in the form [class-name-or-object-ref]->new() and must
instantiate the Engine object; typically this is called by the parent Engine,
which also makes the Interface for the new Engine.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways.

=head1 SEE ALSO

perl(1), Rosetta::L::*, Rosetta::Framework, Rosetta::SimilarModules,
SQL::SyntaxModel, Locale::KeyedText, DBI.

=cut
