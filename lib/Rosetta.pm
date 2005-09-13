#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta;
use version; our $VERSION = qv('0.48.1');

use Scalar::Util;
use only 'Locale::KeyedText' => '1.6.0-';
use only 'SQL::Routine' => '0.70.0-';

######################################################################
######################################################################

# Names of properties for objects of the Rosetta::Interface (I) class are declared here:
my $IPROP_ROOT_INTF = 'root_intf'; # ref to Application Intf that is the root of this Intf's tree
    # This is a convenience property only, redundant with a chain of PARENT_BYCRE_INTF, used for speed.
    # This property is set for every Intf type; it refs self if self is an Application Interface.
    # This Perl ref is a weak when self is an Application, so Perl's auto-destruct is not hindered.
my $IPROP_PARENT_BYCRE_INTF = 'parent_bycre_intf'; # ref to parent-by-creation Interface
    # This property is set for all Intf types except Application.  For Environment Intfs, this property 
    # refs an Application, either directly or indirectly.  For Preparation Intfs, this property refs 
    # the non-Preparation Intf whose prepare() invocation created the Preparation; for non-Preparation 
    # Intfs, it usually refs the Preparation Intf whose execute() created the non-Preparation.
my $IPROP_CHILD_BYCRE_INTFS = 'child_bycre_intfs'; # array - list of refs to child-by-creation Intfs
    # This property is set for all Intf types except Error and Success.
    # Each list item is a reciprocation for the child Intf's PARENT_BYCRE_INTF link to this Intf.
    # Each of these Perl refs is a weak ref so to ensure that child Intfs are always 
    # auto-destructed prior to their parent Intfs, allowing for a proper clean-up sequence.
my $IPROP_PARENT_BYCXT_INTF = 'parent_bycxt_intf'; # ref to parent-by-context Interface
    # This property is set only for these Intf types: Env, Conn, Curs; it refs 
    # just Intfs of these types, respectively: App, Env, Conn.  This property refs 
    # the Intf that provides an operating context for the current Intf.
my $IPROP_CHILD_BYCXT_INTFS = 'child_bycxt_intfs'; # array - list of refs to child-by-context Intfs
    # Each list item is a reciprocation for the child Intf's PARENT_BYCXT_INTF link to this Intf.
    # Each of these Perl refs is a weak ref so to ensure that child Intfs are always 
    # auto-destructed prior to their parent Intfs, allowing for a proper clean-up sequence.
my $IPROP_ENGINE = 'engine'; # ref to Engine obj implementing this Interface obj if any
    # This property is set only for these Intf types: App, Env, Conn, Curs, Lit, Prep.
    # This Engine object would store its own state internally, which includes such things 
    # as various DBI dbh/sth/rv handles where appropriate, and any generated SQL to be 
    # executed, as well as knowledge of how to translate named host variables to positional ones.
    # The Engine object would never store a reference to the Interface object that it 
    # implements, as said Interface object would pass a reference to itself as an argument 
    # to any Engine methods that it invokes.  Of course, if this Engine implements a 
    # middle-layer and invokes another Interface/Engine tree of its own, then it would store 
    # a reference to that Interface like an application would.

# Names of properties for objects of the Rosetta::Interface::Application (IA) class are declared here:
    # An Application Intf exists to be the root context in which all other Intfs 
    # operate, that form an Intf tree beneath it.  An Application Intf represents 
    # a 'application_instance' SQL::Routine Node, which represents a complete set 
    # of database schemas and client-side routines used by the current Rosetta-using 
    # application program in conjunction with specific database instances.
my $IAPROP_SRT_CONT = 'srt_cont'; # ref to SQL::Routine Container this Intf's tree is associated with
    # We must ref the Container explicitly, or it can easily be garbage collected from under us.
    # This property can be accessed through methods on any Intf in this tree.
my $IAPROP_APP_INST_NODE = 'app_inst_node'; # ref to SRT 'application_instance' Node in the Container
my $IAPROP_TRACE_FH = 'trace_fh'; # ref to writeable Perl file handle
    # This property is set after Intf creation and can be cleared or set at any time.
    # When set, details of what Rosetta is doing will be written to the file handle; 
    # to turn off the tracing, just clear the property.
    # This property can be accessed through methods on any Intf in this tree.

# Names of properties for objects of the Rosetta::Interface::Environment (IN) class are declared here:
    # An Environment Intf represents a 'data_link_product' SQL::Routine Node, 
    # which represents a single Rosetta Engine class that will implement parts of 
    # the Rosetta Interface for this app, and is the parent for Connection Intfs using the Engine.
my $INPROP_LINK_PROD_NODE = 'link_prod_node'; # ref to SRT 'data_link_product' Node in the Container

# Names of properties for objects of the Rosetta::Interface::Connection (IC) class are declared here:
    # A Connection Intf represents a (usually context) var having SRT container_type of 'CONN' and 
    # that links indirectly to an app-specific 'catalog_link' SQL::Routine Node describing it.
my $ICPROP_CAT_LINK_NODE = 'cat_link_node'; # ref to SRT 'catalog_link' Node in the Container
    # Note: a SQL::Routine constraint ensures that only one catalog_link_instance Node exists 
    # per distinct catalog_link beneath each application_instance.

# Names of properties for objects of the Rosetta::Interface::Cursor (IU) class are declared here:
    # A Connection Intf represents a (usually context) var having SRT container_type of 'CURSOR' and 
    # that links to a 'external_cursor' SQL::Routine Node that indirectly defines it.
my $IUPROP_EXTERN_CURS_NODE = 'extern_curs_node'; # ref to SRT 'external_cursor' Node in the Container

# Names of properties for objects of the Rosetta::Interface::Literal (IL) class are declared here:
    # A Literal Intf represents anything that isn't conceptually an object (IA,IE,IS,IN,IC,IU) 
    # and simply stores (indirectly) a literal value as its payload.  Currently this includes:
    #   1. SCALAR (a Perl scalar) literals like single booleans or character strings or numbers
    #      - Eg, routines that simply do a yes/no test, such as *_VERIFY, or CATALOG_PING ret boolean
    #   2. composite literals: ROW (Perl Hash), SC_ARY (Perl Array), RW_ARY (Perl Array of Hashes)
    #      - Eg, queries that respectively return one table row, one table column, a full row set
    #   3. a reference to a single or list of SQL::Routine Nodes, usually created by an Engine
    #      - Eg, built-in routines such as *_LIST or *_INFO or *_CLONE ret ref to newly created Nodes
    #   4. some other kind of Perl data structure holding a result or group of results
    #      - Eg, IUD commands that return a set/hash of operation results, such as "last insert id"
    # This object type doesn't have any of its own properties yet since the payload is stored 
    # and/or retrieved-on-demand by the Literal Engine; this is done to best support LOBs.

# Names of properties for objects of the Rosetta::Interface::Success (IS) class are declared here:
    # A Success Intf is returned if a 'procedure' succeeds / does not throw an Error.
    # This object type doesn't have any of its own properties yet since its existence is all that matters.

# Names of properties for objects of the Rosetta::Interface::Preparation (IP) class are declared here:
    # A Preparation Intf represents a 'routine' SQL::Routine Node, which represents 
    # a procedure or function to be executed.
my $IPPROP_RTN_NODE = 'rtn_node'; # ref to SRT 'routine' Node in the Container

# Names of properties for objects of the Rosetta::Interface::Error (IE) class are declared here:
    # An Error Intf is returned if an error happens in an Engine, in place of another Intf type.
    # Note that Error Intfs are always thrown as exceptions to the main application by 
    # Rosetta itself, regardless of whether the Engine does likewise or just 'returns' them.
my $IEPROP_ERROR_MSG = 'error_msg'; # object (Locale::KeyedText::Message) - details of a failure

# Names of properties for objects of the Rosetta::Engine (E) class are declared here:
     # No properties (yet) are declared by this parent class; leaving space free for child classes

# Names of properties for objects of the Rosetta::Dispatcher (D) class are declared here:
my $DPROP_LIT_PAYLOAD = 'lit_payload'; # If Eng fronts a Literal Intf, put payload it represents here.
my $DPROP_PREP_RTN = 'prep_rtn'; # ref to a Perl anonymous subroutine
    # This Perl closure is generated, by prepare(), from the SRT Node tree that 
    # RTN_NODE refers to; the resulting Preparation's execute() will simply invoke the closure.

# Names of all possible features that a Rosetta Engine can claim to support, 
# and that Rosetta::Validator will individually test for.
# This list may resemble SQL::Routine's "standard_routine" enumerated list in part, 
# but it is a lot more broad than that.
my %POSSIBLE_FEATURES = map { ($_ => 1) } qw(
    CATALOG_LIST CATALOG_INFO 

    CONN_BASIC 
    CONN_MULTI_SAME CONN_MULTI_DIFF 
    CONN_PING 
    TRAN_BASIC 
    TRAN_ROLLBACK_ON_DEATH 
    TRAN_MULTI_SIB TRAN_MULTI_CHILD 

    USER_LIST USER_INFO
    SCHEMA_LIST SCHEMA_INFO

    DOMAIN_LIST DOMAIN_INFO DOMAIN_DEFN_VERIFY 
    DOMAIN_DEFN_BASIC

    TABLE_LIST TABLE_INFO TABLE_DEFN_VERIFY
    TABLE_DEFN_BASIC
    TABLE_UKEY_BASIC TABLE_UKEY_MULTI
    TABLE_FKEY_BASIC TABLE_FKEY_MULTI

    QUERY_BASIC
    QUERY_SCHEMA_VIEW
    QUERY_RETURN_SPEC_COLS QUERY_RETURN_COL_EXPRS
    QUERY_WHERE
    QUERY_COMPARE_PRED QUERY_BOOLEAN_EXPR
    QUERY_NUMERIC_EXPR QUERY_STRING_EXPR QUERY_LIKE_PRED
    QUERY_JOIN_BASIC QUERY_JOIN_OUTER_LEFT QUERY_JOIN_ALL
    QUERY_GROUP_BY_NONE QUERY_GROUP_BY_SOME
    QUERY_AGG_CONCAT QUERY_AGG_EXIST
    QUERY_OLAP
    QUERY_HAVING
    QUERY_WINDOW_ORDER QUERY_WINDOW_LIMIT
    QUERY_COMPOUND
    QUERY_SUBQUERY
);

######################################################################
# These are 'protected' methods; only sub-classes should invoke them.

sub _throw_error_message {
    my ($self, $msg_key, $msg_vars) = @_;
    # Throws an exception consisting of an object.
    ref($msg_vars) eq 'HASH' or $msg_vars = {};
    $msg_vars->{'CLASS'} ||= ref($self) || $self;
    foreach my $var_key (keys %{$msg_vars}) {
        if( ref($msg_vars->{$var_key}) eq 'ARRAY' ) {
            $msg_vars->{$var_key} = 'PERL_ARRAY:['.join(',',map {$_||''} @{$msg_vars->{$var_key}}).']';
        }
    }
    die Locale::KeyedText->new_message( $msg_key, $msg_vars );
}

sub _assert_arg_obj_type {
    my ($self, $meth_name, $arg_name, $exp_obj_types, $arg_value) = @_;
    unless( defined( $arg_value ) ) {
        $self->_throw_error_message( 'ROS_CLASS_METH_ARG_UNDEF', 
            { 'METH' => $meth_name, 'ARGNM' => $arg_name } );
    }
    unless( ref($arg_value) ) {
        $self->_throw_error_message( 'ROS_CLASS_METH_ARG_NO_OBJ', 
            { 'METH' => $meth_name, 'ARGNM' => $arg_name, 'ARGVL' => $arg_value } );
    }
    unless( grep { UNIVERSAL::isa( $arg_value, $_ ) } @{$exp_obj_types} ) {
        $self->_throw_error_message( 'ROS_CLASS_METH_ARG_WRONG_OBJ_TYPE', 
            { 'METH' => $meth_name, 'ARGNM' => $arg_name, 
            'EXPOTYPE' => $exp_obj_types, 'ARGOTYPE' => ref($arg_value) } );
    }
    # If we get here, $arg_value is acceptable to the method.
}

sub _assert_arg_intf_obj_type {
    my ($self, $meth_name, $arg_name, $exp_obj_types, $arg_value) = @_;
    $exp_obj_types = [map { 'Rosetta::Interface::'.$_ } @{$exp_obj_types}];
    $self->_assert_arg_obj_type( $meth_name, $arg_name, $exp_obj_types, $arg_value );
}

sub _assert_arg_node_type {
    my ($self, $meth_name, $arg_name, $exp_node_types, $arg_value, $parent_intf) = @_;
    unless( defined( $arg_value ) ) {
        $self->_throw_error_message( 'ROS_CLASS_METH_ARG_UNDEF', 
            { 'METH' => $meth_name, 'ARGNM' => $arg_name } );
    }
    unless( ref($arg_value) and UNIVERSAL::isa( $arg_value, 'SQL::Routine::Node' ) ) {
        $self->_throw_error_message( 'ROS_CLASS_METH_ARG_NO_NODE', 
            { 'METH' => $meth_name, 'ARGNM' => $arg_name, 'ARGVL' => $arg_value } );
    }
    @{$exp_node_types} == 0 and return; # any Node type is acceptable
    my $given_node_type = $arg_value->get_node_type();
    unless( grep { $given_node_type eq $_ } @{$exp_node_types} ) {
        $self->_throw_error_message( 'ROS_CLASS_METH_ARG_WRONG_NODE_TYPE', 
            { 'METH' => $meth_name, 'ARGNM' => $arg_name, 
            'EXPNTYPE' => $exp_node_types, 'ARGNTYPE' => $given_node_type } );
    }
    $arg_value->get_container()->assert_deferrable_constraints(); # SRT throws own exceptions on problem.
    if( $parent_intf or ref($self) and UNIVERSAL::isa( $self, 'Rosetta::Interface' ) and 
            !UNIVERSAL::isa( $self, 'Rosetta::Interface::Application' ) ) {
        my $expected_container = ($parent_intf || $self)->{$IPROP_ROOT_INTF}->{$IAPROP_SRT_CONT};
        unless( $arg_value->get_container()->get_self_id() eq $expected_container->get_self_id() ) {
            $self->_throw_error_message( 'ROS_CLASS_METH_ARG_NODE_NOT_SAME_CONT', 
                { 'METH' => $meth_name, 'ARGNM' => $arg_name, 'NTYPE' => $arg_value->get_node_type(), 
                'NID' => $arg_value->get_node_id(), 'SIDCH' => $arg_value->get_surrogate_id_chain() } );
        }
    }
    # If we get here, $arg_value is acceptable to the method.
}

######################################################################

sub new_application_interface {
    my (undef, $app_inst_node) = @_;
    return Rosetta::Interface::Application->new( $app_inst_node );
}

sub new_environment_interface {
    my (undef, $parent_intf, $link_prod_node) = @_;
    return Rosetta::Interface::Environment->new( $parent_intf, $link_prod_node );
}

sub new_connection_interface {
    my (undef, $parent_bycre_intf, $parent_bycxt_intf, $cat_link_node) = @_;
    return Rosetta::Interface::Connection->new( $parent_bycre_intf, $parent_bycxt_intf, $cat_link_node );
}

sub new_cursor_interface {
    my (undef, $parent_bycre_intf, $parent_bycxt_intf, $extern_curs_node) = @_;
    return Rosetta::Interface::Cursor->new( $parent_bycre_intf, $parent_bycxt_intf, $extern_curs_node );
}

sub new_literal_interface {
    my (undef, $parent_bycre_intf) = @_;
    return Rosetta::Interface::Literal->new( $parent_bycre_intf );
}

sub new_success_interface {
    my (undef, $parent_bycre_intf) = @_;
    return Rosetta::Interface::Success->new( $parent_bycre_intf );
}

sub new_preparation_interface {
    my (undef, $parent_bycre_intf, $routine_node) = @_;
    return Rosetta::Interface::Preparation->new( $parent_bycre_intf, $routine_node );
}

sub new_error_interface {
    my (undef, $parent_bycre_intf, $error_msg) = @_;
    return Rosetta::Interface::Error->new( $parent_bycre_intf, $error_msg );
}

######################################################################
######################################################################

package Rosetta::Interface;
use base qw( Rosetta );

######################################################################

sub _assert_engine_made_errors {
    # This method re-throws an exception thrown when trying to invoke an Engine; 
    # additionally, it will throw exceptions that were simply returned from the same; 
    # it is not to be used when Interface methods throw exceptions for bad user input.
    my ($interface, $meth_name, $engine, $exception, $result) = @_;
    # First process any exception that may have been thrown.
    if( $exception ) { # defined( $exception ) won't work here as eval sets $@ to defined empty str on success
        if( ref($exception) and UNIVERSAL::isa( $exception, 'Rosetta::Interface::Error' ) ) {
            # The called code threw a Rosetta::Interface::Error object.
            die $exception;
        } elsif( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
            # The called code threw a Locale::KeyedText::Message object.
            die $interface->new_error_interface( $interface, $exception );
        } else {
            # The called code died in some other way (means coding error, not user error).
            die $interface->new_error_interface( $interface, Locale::KeyedText->new_message( 
                'ROS_CLASS_METH_ENG_MISC_EXCEPTION', { 'CLASS' => ref($interface), 
                'METH' => $meth_name, 'ENG_CLASS' => ref($engine), 'ERR' => $exception } ) );
        }
    }
    # If we get here, there was no thrown exception; so check for an un-thrown exception.
    if( defined( $result ) ) {
        if( ref($result) and UNIVERSAL::isa( $result, 'Rosetta::Interface::Error' ) ) {
            # The called code returned a Rosetta::Interface::Error object.
            die $result;
        } elsif( ref($result) and UNIVERSAL::isa( $result, 'Locale::KeyedText::Message' ) ) {
            # The called code returned a Locale::KeyedText::Message object.
            die $result->new_error_interface( $interface, $result );
        } else {} # no-op
    }
    # If we get here, then the Engine returned undef or a non-exception value.
}

######################################################################

sub _new__assert_args_intfs_same_tree {
    my ($interface, $parent_bycre_intf, $parent_bycxt_intf) = @_;
    unless( $parent_bycre_intf->{$IPROP_ROOT_INTF} eq $parent_bycxt_intf->{$IPROP_ROOT_INTF} ) {
        $interface->_throw_error_message( 'ROS_I_NEW_ARGS_DIFF_ITREES' );
    }
}

sub _new__set_common_properties {
    # Method assumes that args already validated before it was called.
    my ($interface, $parent_bycre_intf, $parent_bycxt_intf, $engine) = @_;
    if( $parent_bycre_intf ) {
        # This Interface is any type but Application.
        $interface->{$IPROP_PARENT_BYCRE_INTF} = $parent_bycre_intf;
        push( @{$parent_bycre_intf->{$IPROP_CHILD_BYCRE_INTFS}}, $interface );
        Scalar::Util::weaken( $parent_bycre_intf->{$IPROP_CHILD_BYCRE_INTFS}->[-1] ); # avoid strong circular refs
        $interface->{$IPROP_ROOT_INTF} = $parent_bycre_intf->{$IPROP_ROOT_INTF};
    } else {
        # This Interface is an Application.
        $interface->{$IPROP_PARENT_BYCRE_INTF} = undef;
        $interface->{$IPROP_ROOT_INTF} = $interface;
        Scalar::Util::weaken( $interface->{$IPROP_ROOT_INTF} ); # avoid strong circular refs
    }
    $interface->{$IPROP_CHILD_BYCRE_INTFS} = [];
    if( $parent_bycxt_intf ) {
        # This Interface is one of: Env, Conn, Curs.
        $interface->{$IPROP_PARENT_BYCXT_INTF} = $parent_bycxt_intf;
        push( @{$parent_bycxt_intf->{$IPROP_CHILD_BYCXT_INTFS}}, $interface );
        Scalar::Util::weaken( $parent_bycxt_intf->{$IPROP_CHILD_BYCXT_INTFS}->[-1] ); # avoid strong circular refs
    } else {
        # This Interface is one of: App, Lit, Succ, Prep, Err.
        $interface->{$IPROP_PARENT_BYCXT_INTF} = undef;
    }
    $interface->{$IPROP_CHILD_BYCXT_INTFS} = [];
    if( $engine ) {
        # This Interface is one of: App, Env, Conn, Curs, Lit, Prep.
        $interface->{$IPROP_ENGINE} = $engine;
    } else {
        # This Interface is one of: Succ, Err.
        $interface->{$IPROP_ENGINE} = undef;
    }
}

######################################################################

sub DESTROY {
    # This method ensures that our parent's child list doesn't contain undefs after we 
    # go away (undefs are what the weak refs in said list become when we auto-destruct).
    my ($interface) = @_;
    if( my $parent_bycre_intf = $interface->{$IPROP_PARENT_BYCRE_INTF} ) {
        my $siblings = $parent_bycre_intf->{$IPROP_CHILD_BYCRE_INTFS};
        @{$siblings} = grep { defined( $_ ) and $_ ne $interface } @{$siblings};
    }
    if( my $parent_bycxt_intf = $interface->{$IPROP_PARENT_BYCXT_INTF} ) {
        my $siblings = $parent_bycxt_intf->{$IPROP_CHILD_BYCXT_INTFS};
        @{$siblings} = grep { defined( $_ ) and $_ ne $interface } @{$siblings};
    }
    # Note: I tested each parent's child both for definedness and for not being 
    # self because I'm not sure of the timing where the weak-ref becomes undef, 
    # relative to when DESTROY is run.
}

######################################################################

sub _features {
    my ($interface, $feature_name) = @_;
    my $engine = $interface->{$IPROP_ENGINE};

    if( defined( $feature_name ) ) {
        unless( $POSSIBLE_FEATURES{$feature_name} ) {
            $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_ARG', { 'ARGVL' => $feature_name } );
        }
    }

    my $result = eval {
        # An eval block is like a routine body.
        return $engine->features( $interface, $feature_name );
    };
    $interface->_assert_engine_made_errors( 'features', $engine, $@, $result );

    if( defined( $feature_name ) ) {
        # Note that an undefined result is valid here; that means "don't know".
        if( defined( $result ) and $result ne '0' and $result ne '1' ) {
            $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_SCALAR', 
                { 'ENG_CLASS' => ref($engine), 'FNAME' => $feature_name, 'VALUE' => $result } );
        }
    } else {
        unless( defined( $result ) ) {
            $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_LIST_UNDEF', 
                { 'ENG_CLASS' => ref($engine) } );
        }
        unless( ref( $result ) eq 'HASH' ) {
            $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_LIST_NO_HASH', 
                { 'ENG_CLASS' => ref($engine), 'VALUE' => $result } );
        }
        foreach my $list_feature_name (keys %{$result}) {
            unless( $POSSIBLE_FEATURES{$list_feature_name} ) {
                $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_ITEM_NAME', 
                    { 'ENG_CLASS' => ref($engine), 'FNAME' => $list_feature_name } );
            }
            my $value = $result->{$list_feature_name};
            unless( defined( $value ) ) {
                $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_ITEM_NO_VAL', 
                    { 'ENG_CLASS' => ref($engine), 'FNAME' => $list_feature_name } );
            }
            if( $value ne '0' and $value ne '1' ) {
                $interface->_throw_error_message( 'ROS_I_FEATURES_BAD_RESULT_ITEM_BAD_VAL', 
                    { 'ENG_CLASS' => ref($engine), 'FNAME' => $list_feature_name, 'VALUE' => $value } );
            }
        }
    }

    return $result;
}

######################################################################

sub _prepare {
    my ($interface, $routine_defn) = @_;
    my $engine = $interface->{$IPROP_ENGINE};

    $interface->_assert_arg_node_type( 'prepare', 
        'ROUTINE_DEFN', ['routine'], $routine_defn );

    unless( $routine_defn->get_primary_parent_attribute()->get_node_type() eq 'application' ) {
        # Only externally visible routines in 'application space' can be directly 
        # invoked by a user application; to invoke anything in 'database space', 
        # you must have a separate app-space proxy routine invoke it.
        # TODO
#        $engine->_throw_error_message( 'ROS_G_NEST_RTN_NO_INVOK', { 'RNAME' => $routine_node } );
    }
    my $routine_type = $routine_defn->get_attribute( 'routine_type' );
    unless( $routine_type eq 'FUNCTION' or $routine_type eq 'PROCEDURE' ) {
        # You can not directly invoke a trigger or other non-func/proc.
        # (These would only exist in app-space if attached to a temporary / app-space table.)
        # TODO
#        $engine->_throw_error_message( 'ROS_G_RTN_TP_NO_INVOK', 
#            { 'RNAME' => $routine_node, 'RTYPE' => $routine_type } );
    }

    if( my $routine_cxt_node = $routine_defn->get_child_nodes( 'routine_context' )->[0] ) {
        my $cont_type = $routine_cxt_node->get_attribute( 'cont_type' );
        if( $cont_type eq 'CONN' ) {
            # The routine expects to be invoked in a Connection context.
            unless( ref($interface) and UNIVERSAL::isa( $interface, 'Rosetta::Interface::Connection' ) ) {
                # TODO
            }
        } elsif( $cont_type eq 'CURSOR' ) {
            # The routine expects to be invoked in a Cursor context.
            unless( ref($interface) and UNIVERSAL::isa( $interface, 'Rosetta::Interface::Cursor' ) ) {
                # TODO
            }
        } else {} # We should never get here.
    } else {} # The routine expects to be invoked in a void context; any Interface type is okay.

    my $result = eval {
        # An eval block is like a routine body.
        return $engine->prepare( $interface, $routine_defn );
    };
    $interface->_assert_engine_made_errors( 'prepare', $engine, $@, $result );

    unless( defined( $result ) ) {
        $interface->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_UNDEF', 
            { 'METH' => 'prepare', 'ENG_CLASS' => ref($engine) } );
    }
    unless( ref($result) ) {
        $interface->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_NO_OBJ', 
            { 'METH' => 'prepare', 'ENG_CLASS' => ref($engine), 'RESULTVL' => $result } );
    }
    unless( UNIVERSAL::isa( $result, 'Rosetta::Interface::Preparation' ) ) {
        $interface->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_OBJ_TYPE', 
            { 'METH' => 'prepare', 'ENG_CLASS' => ref($engine), 
            'EXPOTYPE' => 'Rosetta::Interface::Preparation', 'RESULTOTYPE' => ref($result) } );
    }
    unless( $interface->{$IPROP_ROOT_INTF} eq $result->{$IPROP_ROOT_INTF} ) {
        $interface->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_ITREE', 
            { 'METH' => 'prepare', 'ENG_CLASS' => ref($engine) } );
    }

    return $result;
}

######################################################################

sub get_root_interface {
    my ($interface) = @_;
    return $interface->{$IPROP_ROOT_INTF};
}

######################################################################

sub get_parent_by_creation_interface {
    my ($interface) = @_;
    return $interface->{$IPROP_PARENT_BYCRE_INTF};
}

######################################################################

sub get_child_by_creation_interfaces {
    my ($interface) = @_;
    return [@{$interface->{$IPROP_CHILD_BYCRE_INTFS}}];
}

######################################################################

sub get_parent_by_context_interface {
    my ($interface) = @_;
    return $interface->{$IPROP_PARENT_BYCXT_INTF};
}

######################################################################

sub get_child_by_context_interfaces {
    my ($interface) = @_;
    return [@{$interface->{$IPROP_CHILD_BYCXT_INTFS}}];
}

######################################################################

sub get_engine {
    my ($interface) = @_;
    return $interface->{$IPROP_ENGINE};
}

######################################################################

sub get_srt_container {
    my ($interface) = @_;
    return $interface->{$IPROP_ROOT_INTF}->{$IAPROP_SRT_CONT};
}

######################################################################

sub get_app_inst_node {
    my ($interface) = @_;
    return $interface->{$IPROP_ROOT_INTF}->{$IAPROP_APP_INST_NODE};
}

######################################################################

sub get_trace_fh {
    my ($interface) = @_;
    return $interface->{$IPROP_ROOT_INTF}->{$IAPROP_TRACE_FH};
}

sub clear_trace_fh {
    my ($interface) = @_;
    $interface->{$IPROP_ROOT_INTF}->{$IAPROP_TRACE_FH} = undef;
}

sub set_trace_fh {
    my ($interface, $new_fh) = @_;
    $interface->{$IPROP_ROOT_INTF}->{$IAPROP_TRACE_FH} = $new_fh;
}

######################################################################
######################################################################

package Rosetta::Interface::Application;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $app_inst_node) = @_;
    my $app_intf = bless( {}, ref($class) || $class );

    $app_intf->_assert_arg_node_type( 'new', 
        'APP_INST_NODE', ['application_instance'], $app_inst_node );

    my $app_eng = Rosetta::Dispatcher->new_application_engine();

    $app_intf->_new__set_common_properties( undef, undef, $app_eng );
    $app_intf->{$IAPROP_SRT_CONT} = $app_inst_node->get_container();
    $app_intf->{$IAPROP_APP_INST_NODE} = $app_inst_node;
    $app_intf->{$IAPROP_TRACE_FH} = undef;

    return $app_intf;
}

######################################################################

sub features {
    my ($app_intf, $feature_name) = @_;
    return $app_intf->_features( $feature_name );
}

######################################################################

sub prepare {
    my ($app_intf, $routine_defn) = @_;
    return $app_intf->_prepare( $routine_defn );
}

######################################################################

sub do {
    my ($app_intf, $routine_defn, $routine_args) = @_;
    return $app_intf->_prepare( $routine_defn )->execute( $routine_args );
}

######################################################################
######################################################################

package Rosetta::Interface::Environment;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_intf, $link_prod_node) = @_;
    my $env_intf = bless( {}, ref($class) || $class );

    $env_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_INTF', ['Application'], $parent_intf );
    $env_intf->_assert_arg_node_type( 'new', 
        'LINK_PROD_NODE', ['data_link_product'], $link_prod_node, $parent_intf );

    foreach my $ch_env_intf (@{$parent_intf->{$IPROP_CHILD_BYCXT_INTFS}}) {
        if( $ch_env_intf->{$INPROP_LINK_PROD_NODE}->get_self_id() eq $link_prod_node->get_self_id() ) {
            # Found an existing Environment Intf having the given data_link_product.
            return $ch_env_intf;
        }
    }
    # If we get here, there is no existing Environment Intf having the given data_link_product.

    my $engine_name = $link_prod_node->get_attribute( 'product_code' );

    # This Application Interface has no child Environment Preparation Interface of the 
    # requested kind; however, the package implementing that Engine may already be loaded.
    # A package may be loaded due to it being embedded in a non-exclusive file, or because another 
    # Environment Intf loaded it.  Check that the package is an Engine subclass regardless.
    no strict 'refs';
    my $package_is_loaded = defined %{$engine_name.'::'};
    use strict 'refs';
    unless( $package_is_loaded ) {
        # a bare "require $engine_name;" yields "can't find module in @INC" error in Perl 5.6
        eval "require $engine_name;";
        if( $@ ) {
            $env_intf->_throw_error_message( 'ROS_IN_NEW_ENGINE_NO_LOAD', 
                { 'ENG_CLASS' => $engine_name, 'ERR' => $@ } );
        }
    }
    unless( UNIVERSAL::isa( $engine_name, 'Rosetta::Engine' ) ) {
        $env_intf->_throw_error_message( 'ROS_IN_NEW_ENGINE_NO_ENGINE', { 'ENG_CLASS' => $engine_name } );
    }

    my $env_eng = $engine_name->new_environment_engine();

    $env_intf->_new__set_common_properties( $parent_intf, $parent_intf, $env_eng );
    $env_intf->{$INPROP_LINK_PROD_NODE} = $link_prod_node;
        # Note: Once a Rosetta Environment + Engine is associated with a 'data_link_product', 
        # any later changes (if any) to that SQL::Routine Node's 'product_code' will be ignored 
        # by this Rosetta Intf tree, and the Engine specified by the Node's earlier value will 
        # continue being used, until said Environment is garbage collected and a fresh one made.

    return $env_intf;
}

######################################################################

sub get_link_prod_node {
    my ($env_intf) = @_;
    return $env_intf->{$INPROP_LINK_PROD_NODE};
}

######################################################################

sub features {
    my ($env_intf, $feature_name) = @_;
    return $env_intf->_features( $feature_name );
}

######################################################################

sub prepare {
    my ($env_intf, $routine_defn) = @_;
    return $env_intf->_prepare( $routine_defn );
}

######################################################################

sub do {
    my ($env_intf, $routine_defn, $routine_args) = @_;
    return $env_intf->_prepare( $routine_defn )->execute( $routine_args );
}

######################################################################
######################################################################

package Rosetta::Interface::Connection;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_bycre_intf, $parent_bycxt_intf, $cat_link_node) = @_;
    my $conn_intf = bless( {}, ref($class) || $class );

    $conn_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCRE_INTF', ['Preparation'], $parent_bycre_intf );
    $conn_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCXT_INTF', ['Environment'], $parent_bycxt_intf );
    $conn_intf->_new__assert_args_intfs_same_tree( $parent_bycre_intf, $parent_bycxt_intf );
    $conn_intf->_assert_arg_node_type( 'new', 
        'CAT_LINK_NODE', ['catalog_link'], $cat_link_node, $parent_bycre_intf );

    my $conn_eng = $parent_bycre_intf->{$IPROP_ENGINE}->new_connection_engine();

    $conn_intf->_new__set_common_properties( $parent_bycre_intf, $parent_bycxt_intf, $conn_eng );
    $conn_intf->{$ICPROP_CAT_LINK_NODE} = $cat_link_node;

    return $conn_intf;
}

######################################################################

sub get_cat_link_node {
    my ($conn_intf) = @_;
    return $conn_intf->{$ICPROP_CAT_LINK_NODE};
}

######################################################################

sub features {
    my ($conn_intf, $feature_name) = @_;
    return $conn_intf->_features( $feature_name );
}

######################################################################

sub prepare {
    my ($conn_intf, $routine_defn) = @_;
    return $conn_intf->_prepare( $routine_defn );
}

######################################################################

sub do {
    my ($conn_intf, $routine_defn, $routine_args) = @_;
    return $conn_intf->_prepare( $routine_defn )->execute( $routine_args );
}

######################################################################
######################################################################

package Rosetta::Interface::Cursor;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_bycre_intf, $parent_bycxt_intf, $extern_curs_node) = @_;
    my $curs_intf = bless( {}, ref($class) || $class );

    $curs_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCRE_INTF', ['Preparation'], $parent_bycre_intf );
    $curs_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCXT_INTF', ['Connection'], $parent_bycxt_intf );
    $curs_intf->_new__assert_args_intfs_same_tree( $parent_bycre_intf, $parent_bycxt_intf );
    $curs_intf->_assert_arg_node_type( 'new', 
        'EXTERN_CURS_NODE', ['external_cursor'], $extern_curs_node, $parent_bycre_intf );

    my $curs_eng = $parent_bycre_intf->{$IPROP_ENGINE}->new_cursor_engine();

    $curs_intf->_new__set_common_properties( $parent_bycre_intf, $parent_bycxt_intf, $curs_eng );
    $curs_intf->{$IUPROP_EXTERN_CURS_NODE} = $extern_curs_node;

    return $curs_intf;
}

######################################################################

sub get_extern_curs_node {
    my ($curs_intf) = @_;
    return $curs_intf->{$IUPROP_EXTERN_CURS_NODE};
}

######################################################################

sub prepare {
    my ($curs_intf, $routine_defn) = @_;
    return $curs_intf->_prepare( $routine_defn );
}

######################################################################

sub do {
    my ($curs_intf, $routine_defn, $routine_args) = @_;
    return $curs_intf->_prepare( $routine_defn )->execute( $routine_args );
}

######################################################################
######################################################################

package Rosetta::Interface::Literal;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_bycre_intf) = @_;
    my $lit_intf = bless( {}, ref($class) || $class );

    $lit_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCRE_INTF', ['Preparation'], $parent_bycre_intf );

    my $lit_eng = $parent_bycre_intf->{$IPROP_ENGINE}->new_literal_engine();

    $lit_intf->_new__set_common_properties( $parent_bycre_intf, undef, $lit_eng );

    return $lit_intf;
}

######################################################################

sub payload {
    my ($lit_intf) = @_;
    my $lit_eng = $lit_intf->{$IPROP_ENGINE};
    my $p_prep_intf = $lit_intf->{$IPROP_PARENT_BYCRE_INTF};

    my $result = eval {
        # An eval block is like a routine body.
        return $lit_eng->payload( $lit_intf );
    };
    $lit_intf->_assert_engine_made_errors( 'payload', $lit_eng, $@, $result );

    my $routine_node = $p_prep_intf->{$IPPROP_RTN_NODE};
    my $ret_cont_type = $routine_node->get_attribute( 'return_cont_type' );
    if( $ret_cont_type eq 'SCALAR' ) {
        # TODO
    } elsif( $ret_cont_type eq 'ROW' ) {
        # TODO
    } elsif( $ret_cont_type eq 'SC_ARY' ) {
        # TODO
    } elsif( $ret_cont_type eq 'RW_ARY' ) {
        # TODO
    } elsif( $ret_cont_type eq 'LIST' ) {
        # TODO
    } elsif( $ret_cont_type eq 'SRT_NODE' ) {
        # TODO
    } elsif( $ret_cont_type eq 'SRT_NODE_LIST' ) {
        # TODO
    } else {} # We should never get any of ERROR, CONN, CURSOR.

    return $result;
}

######################################################################
######################################################################

package Rosetta::Interface::Success;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_bycre_intf) = @_;
    my $succ_intf = bless( {}, ref($class) || $class );

    $succ_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCRE_INTF', ['Preparation'], $parent_bycre_intf );

    $succ_intf->_new__set_common_properties( $parent_bycre_intf );

    return $succ_intf;
}

######################################################################
######################################################################

package Rosetta::Interface::Preparation;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_bycre_intf, $routine_node) = @_;
    my $prep_intf = bless( {}, ref($class) || $class );

    $prep_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCRE_INTF', ['Application','Environment','Connection','Cursor'], $parent_bycre_intf );
    $prep_intf->_assert_arg_node_type( 'new', 
        'ROUTINE_NODE', ['routine'], $routine_node, $parent_bycre_intf );

    my $prep_eng = $parent_bycre_intf->{$IPROP_ENGINE}->new_preparation_engine();

    $prep_intf->_new__set_common_properties( $parent_bycre_intf, undef, $prep_eng );
    $prep_intf->{$IPPROP_RTN_NODE} = $routine_node;

    return $prep_intf;
}

######################################################################

sub get_routine_node {
    my ($prep_intf) = @_;
    return $prep_intf->{$IPPROP_RTN_NODE};
}

######################################################################

sub execute {
    my ($prep_intf, $routine_args) = @_;
    my $prep_eng = $prep_intf->{$IPROP_ENGINE};
    my $routine_node = $prep_intf->{$IPPROP_RTN_NODE};

    if( defined( $routine_args ) ) {
        unless( ref($routine_args) eq 'HASH' ) {
            $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ARG_NO_HASH', 
                { 'METH' => 'execute', 'ARGNM' => 'ROUTINE_ARGS', 'ARGVL' => $routine_args } );
        }
    } else {
        $routine_args = {};
    }
    my $routine_arg_nodes = $routine_node->get_child_nodes( 'routine_arg' );
    unless( (keys %{$routine_args}) == @{$routine_arg_nodes} ) {
        # Wrong number of arguments were passed to this routine ... we assume no args are optional.
        # TODO
    }
    foreach my $routine_arg_node (@{$routine_arg_nodes}) {
        my $arg_name = $routine_arg_node->get_attribute( 'si_name' );
        my $arg_value = $routine_args->{$arg_name};
        my $cont_type = $routine_arg_node->get_attribute( 'cont_type' );
        if( $cont_type eq 'ERROR' ) {
            # The routine arg expects to be handed an Error object.
            unless( ref($arg_value) and UNIVERSAL::isa( $arg_value, 'Rosetta::Interface::Error' ) ) {
                # TODO
            }
        } elsif( $cont_type eq 'CONN' ) {
            # The routine arg expects to be handed a Connection handle.
            unless( ref($arg_value) and UNIVERSAL::isa( $arg_value, 'Rosetta::Interface::Connection' ) ) {
                # TODO
            }
        } elsif( $cont_type eq 'CURSOR' ) {
            # The routine arg expects to be handed a Cursor handle.
            unless( ref($arg_value) and UNIVERSAL::isa( $arg_value, 'Rosetta::Interface::Cursor' ) ) {
                # TODO
            }
        } elsif( $cont_type eq 'SCALAR' ) {
            # TODO
        } elsif( $cont_type eq 'ROW' ) {
            # TODO
        } elsif( $cont_type eq 'SC_ARY' ) {
            # TODO
        } elsif( $cont_type eq 'RW_ARY' ) {
            # TODO
        } elsif( $cont_type eq 'LIST' ) {
            # TODO
        } elsif( $cont_type eq 'SRT_NODE' ) {
            # TODO
        } elsif( $cont_type eq 'SRT_NODE_LIST' ) {
            # TODO
        } else {} # We should never get here
    }

    my $result = eval {
        # An eval block is like a routine body.
        return $prep_eng->execute( $prep_intf, $routine_args );
    };
    $prep_intf->_assert_engine_made_errors( 'execute', $prep_eng, $@, $result );

    unless( defined( $result ) ) {
        $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_UNDEF', 
            { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng) } );
    }
    unless( ref($result) ) {
        $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_NO_OBJ', 
            { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng), 'RESULTVL' => $result } );
    }
    my $routine_type = $routine_node->get_attribute( 'routine_type' );
    if( $routine_type eq 'PROCEDURE' ) {
        # All procedures conceptually return nothing, actually return SUCCESS when ok.
        unless( UNIVERSAL::isa( $result, 'Rosetta::Interface::Success' ) ) {
            $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_OBJ_TYPE', 
                { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng), 
                'EXPOTYPE' => 'Rosetta::Interface::Success', 'RESULTOTYPE' => ref($result) } );
        }
    } else { # $routine_type eq 'FUNCTION' ... prepare() made sure of that
        my $ret_cont_type = $routine_node->get_attribute( 'return_cont_type' );
        if( $ret_cont_type eq 'CONN' ) {
            # The routine is expected to return a Connection Interface.
            unless( UNIVERSAL::isa( $result, 'Rosetta::Interface::Connection' ) ) {
                $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_OBJ_TYPE', 
                    { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng), 
                    'EXPOTYPE' => 'Rosetta::Interface::Connection', 'RESULTOTYPE' => ref($result) } );
            }
        } elsif( $ret_cont_type eq 'CURSOR' ) {
            # The routine is expected to return a Cursor Interface.
            unless( UNIVERSAL::isa( $result, 'Rosetta::Interface::Cursor' ) ) {
                $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_OBJ_TYPE', 
                    { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng), 
                    'EXPOTYPE' => 'Rosetta::Interface::Cursor', 'RESULTOTYPE' => ref($result) } );
            }
        } else {
            # The routine is expected to return a Literal Interface.
            unless( UNIVERSAL::isa( $result, 'Rosetta::Interface::Literal' ) ) {
                $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_OBJ_TYPE', 
                    { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng), 
                    'EXPOTYPE' => 'Rosetta::Interface::Literal', 'RESULTOTYPE' => ref($result) } );
            }
        }
    }
    unless( $prep_intf->{$IPROP_ROOT_INTF} eq $result->{$IPROP_ROOT_INTF} ) {
        $prep_intf->_throw_error_message( 'ROS_CLASS_METH_ENG_RESULT_WRONG_ITREE', 
            { 'METH' => 'execute', 'ENG_CLASS' => ref($prep_eng) } );
    }

    return $result;
}

######################################################################
######################################################################

package Rosetta::Interface::Error;
use base qw( Rosetta::Interface );

######################################################################

sub new {
    my ($class, $parent_bycre_intf, $error_msg) = @_;
    my $err_intf = bless( {}, ref($class) || $class );

    $err_intf->_assert_arg_intf_obj_type( 'new', 
        'PARENT_BYCRE_INTF', ['Application', 'Environment', 'Connection', 
        'Cursor', 'Literal', 'Preparation'], $parent_bycre_intf );
    $err_intf->_assert_arg_obj_type( 'new', 
        'ERROR_MSG', ['Locale::KeyedText::Message'], $error_msg );

    $err_intf->_new__set_common_properties( $parent_bycre_intf );
    $err_intf->{$IEPROP_ERROR_MSG} = $error_msg;

    return $err_intf;
}

######################################################################

sub get_error_message {
    my ($err_intf) = @_;
    return $err_intf->{$IEPROP_ERROR_MSG};
}

######################################################################
######################################################################

package Rosetta::Engine;
use base qw( Rosetta );

######################################################################

sub new_environment_engine {
    Rosetta::Engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'new_environment_engine' } );
}

sub new_connection_engine {
    Rosetta::Engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'new_connection_engine' } );
}

sub new_cursor_engine {
    Rosetta::Engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'new_cursor_engine' } );
}

sub new_literal_engine {
    Rosetta::Engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'new_literal_engine' } );
}

sub new_preparation_engine {
    Rosetta::Engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'new_preparation_engine' } );
}

######################################################################

sub features {
    my ($engine, $interface, $feature_name) = @_;
    $engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'features' } );
}

sub prepare {
    my ($engine, $interface, $routine_defn) = @_;
    $engine->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'prepare' } );
}

sub payload {
    my ($lit_eng, $lit_intf) = @_;
    $lit_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'payload' } );
}

sub execute {
    my ($prep_eng, $prep_intf, $routine_args) = @_;
    $prep_eng->_throw_error_message( 'ROS_E_METH_NOT_IMPL', { 'METH' => 'execute' } );
}

######################################################################
######################################################################

package Rosetta::Dispatcher;
use base qw( Rosetta );

######################################################################

sub new_application_engine {
    return Rosetta::Dispatcher->new();
}

sub new_literal_engine {
    return Rosetta::Dispatcher->new();
}

sub new_preparation_engine {
    return Rosetta::Dispatcher->new();
}

######################################################################

sub new {
    my ($class) = @_;
    my $dispatcher = bless( {}, ref($class) || $class );
    return $dispatcher;
}

######################################################################

sub features {
    # This method assumes that it is only called on Application Interfaces.
    my ($app_disp, $app_intf, $feature_name) = @_;

    # First gather the feature results from each available Engine.
    my @results = ();
    my $container = $app_intf->get_srt_container();
    foreach my $link_prod_node (@{$container->get_child_nodes( 'data_link_product' )}) {
        my $env_intf = $app_intf->new_environment_interface( $app_intf, $link_prod_node );
        my $result = $env_intf->features( $feature_name );
        push( @results, $result );
    }

    # Now combine the results by means of intersection|and.  For each possible 
    # feature, the combined output is 1 ('yes') only if all inputs are 1, and 0 ('no') 
    # only if all are 0; if any inputs differ or are undef ('maybe') then 
    # the output is undef ('maybe') or a missing list item.  If there are zero 
    # Engines, then the result is undef ('maybe') or an empty list.

    if( defined( $feature_name ) ) {
        @results == 0 and return; # returns undef if no Engines
        my $result = shift( @results );
        defined( $result ) or return;
        foreach my $next_result (@results) {
            defined( $next_result ) or return;
            $next_result eq $result or return;
            # so far, both $result and $next_result have the same 1 or 0 value
        }
        return $result;

    } else {
        @results == 0 and return {}; # returns {} if no Engines
        my $result = shift( @results );
        (keys %{$result}) == 0 and return {};
        foreach my $next_result (@results) {
            (keys %{$next_result}) == 0 and return {};
            foreach my $list_feature_name (keys %{$result}) {
                my $next_result_value = $next_result->{$list_feature_name};
                defined( $next_result_value ) or delete( $result->{$list_feature_name} );
                $next_result_value eq $result->{$list_feature_name} or delete( $result->{$list_feature_name} );
                # so far, both $result_value and $next_result_value have the same 1 or 0 value
            }
            (keys %{$result}) == 0 and return {};
        }
        return $result;
    }
}

######################################################################

sub prepare {
    # This method assumes that it is only called on Application Interfaces.
    my ($app_disp, $app_intf, $routine_node) = @_;
    my $prep_intf = undef;
    SEARCH: {
        foreach my $routine_context_node (@{$routine_node->get_child_nodes( 'routine_context' )}) {
            if( my $cat_link_bp_node = $routine_context_node->get_attribute( 'conn_link' ) ) {
                $prep_intf = $app_disp->_prepare__call_engine( $app_intf, $routine_node, $cat_link_bp_node );
                last SEARCH;
            }
        }
        foreach my $routine_arg_node (@{$routine_node->get_child_nodes( 'routine_arg' )}) {
            if( my $cat_link_bp_node = $routine_arg_node->get_attribute( 'conn_link' ) ) {
                $prep_intf = $app_disp->_prepare__call_engine( $app_intf, $routine_node, $cat_link_bp_node );
                last SEARCH;
            }
        }
        foreach my $routine_var_node (@{$routine_node->get_child_nodes( 'routine_var' )}) {
            if( my $cat_link_bp_node = $routine_var_node->get_attribute( 'conn_link' ) ) {
                $prep_intf = $app_disp->_prepare__call_engine( $app_intf, $routine_node, $cat_link_bp_node );
                last SEARCH;
            }
        }
        foreach my $routine_stmt_node (@{$routine_node->get_child_nodes( 'routine_stmt' )}) {
            if( my $sroutine_name = $routine_stmt_node->get_attribute( 'call_sroutine' ) ) {
                if( $sroutine_name eq 'CATALOG_LIST' ) {
                    $prep_intf = $app_disp->_prepare__srtn_cat_list( $app_intf, $routine_node );
                    last SEARCH;
                }
            }
            $prep_intf = $app_disp->_prepare__recurse( $app_intf, $routine_node, $routine_stmt_node );
            $prep_intf and last SEARCH;
        }
        $app_disp->_throw_error_message( 'ROS_D_PREPARE_NO_ENGINE_DETERMINED' );
    }
    return $prep_intf;
}

sub _prepare__recurse {
    my ($app_disp, $app_intf, $routine_node, $routine_stmt_or_expr_node) = @_;
    my $prep_intf = undef;
    foreach my $routine_expr_node (@{$routine_stmt_or_expr_node->get_child_nodes()}) {
        if( my $sroutine_name = $routine_expr_node->get_attribute( 'valf_call_sroutine' ) ) {
            if( $sroutine_name eq 'CATALOG_LIST' ) {
                $prep_intf = $app_disp->_prepare__srtn_cat_list( $app_intf, $routine_node );
                last;
            }
        }
        $prep_intf = $app_disp->_prepare__recurse( $app_intf, $routine_node, $routine_expr_node );
        $prep_intf and last;
    }
    return $prep_intf;
}

sub _prepare__srtn_cat_list {
    my ($app_disp, $app_intf, $routine_node) = @_;

    my @lit_prep_intfs = ();
    my $container = $routine_node->get_container();
    foreach my $link_prod_node (@{$container->get_child_nodes( 'data_link_product' )}) {
        my $env_intf = $app_intf->new_environment_interface( $app_intf, $link_prod_node );
        my $lit_prep_intf = $env_intf->prepare( $routine_node );
        push( @lit_prep_intfs, $lit_prep_intf );
    }

    my $prep_routine = sub {
        # This routine is a closure.
        my ($rtv_lit_prep_disp, $rtv_lit_prep_intf, $rtv_args) = @_;

        my @cat_link_bp_nodes = ();

        foreach my $lit_prep_intf (@lit_prep_intfs) {
            my $lit_intf = $lit_prep_intf->execute();
            my $payload = $lit_intf->payload();
            push( @cat_link_bp_nodes, @{$payload} );
        }

        my $rtv_lit_intf = $rtv_lit_prep_intf->new_literal_interface( $rtv_lit_prep_intf );
        my $rtv_lit_disp = $rtv_lit_prep_intf->get_engine();

        $rtv_lit_disp->{$DPROP_LIT_PAYLOAD} = \@cat_link_bp_nodes;

        return $rtv_lit_intf;
    };

    my $lit_prep_intf = $app_intf->new_preparation_interface( $app_intf, $routine_node );
    my $lit_prep_disp = $lit_prep_intf->get_engine();

    $lit_prep_disp->{$DPROP_PREP_RTN} = $prep_routine;

    return $lit_prep_intf;
}

sub _prepare__call_engine {
    my ($app_disp, $app_intf, $routine_node, $cat_link_bp_node) = @_;

    # Now figure out link product by cross-referencing app inst with cat link bp.
    my $app_inst_node = $app_intf->get_app_inst_node();
    my $cat_link_inst_node = undef;
    foreach my $link (@{$app_inst_node->get_child_nodes( 'catalog_link_instance' )}) {
        if( $link->get_attribute( 'blueprint' )->get_self_id() eq $cat_link_bp_node->get_self_id() ) {
            $cat_link_inst_node = $link;
            last;
        }
    }
    my $link_prod_node = $cat_link_inst_node->get_attribute( 'product' );

    # Now make sure that the Engine we need is loaded.
    my $env_intf = $app_intf->new_environment_interface( $app_intf, $link_prod_node );
    # Now repeat the command we ourselves were given against a specific Environment Interface.
    my $prep_intf = $env_intf->prepare( $routine_node );
    return $prep_intf;
}

######################################################################

sub payload {
    my ($lit_disp, $lit_intf) = @_;
    return $lit_disp->{$DPROP_LIT_PAYLOAD};
}

######################################################################

sub execute {
    my ($prep_disp, $prep_intf, $routine_args) = @_;
    return $prep_disp->{$DPROP_PREP_RTN}->( $prep_disp, $prep_intf, $routine_args );
}

######################################################################
######################################################################

1;
__END__

=encoding utf8

=head1 NAME

Rosetta - Rigorous database portability

=head1 VERSION

This document describes Rosetta version 0.48.1.

=head1 SYNOPSIS

I<The previous SYNOPSIS was removed; a new one will be written later.>

=head1 DESCRIPTION

The Rosetta Perl 5 module defines a complete and rigorous API for database
access that provides hassle-free portability between many dozens of
database products for database-using applications of any size and
complexity, that leverage all sorts of advanced database product features. 
The Rosetta Native Interface (RNI) allows you to create specifications for
any type of database task or activity (eg: queries, DML, DDL, connection
management) that look like ordinary routines (procedures or functions) to
your programs, and execute them as such; all routine arguments are named.

Rosetta is trivially easy to install, since it is written in pure Perl and
it has few external dependencies.

One of the main goals of Rosetta is similar to that of the Java platform,
namely "write once, run anywhere".  Code written against the RNI will run
in an identical fashion with zero changes regardless of what underlying
database product is in use.  Rosetta is intended to help free users and
developers from database vendor lock-in, such as that caused by the
investment in large quantities of vendor-specific code.  It also comes with
a comprehensive validation suite that proves it is providing identical
behaviour no matter what the underlying database vendor is.

The RNI is structured in a loosely similar fashion to the DBI module's API,
and it should be possible to adapt applications written to use the DBI or
one of its many wrapper modules without too much trouble, if not directly
then by way of an emulation layer.  One aspect of this similarity is the
hierarchy of interface objects; you start with a root, which spawns objects
that represent database connections, each of which spawns objects
representing queries or statements run against a database through said
connections.  Another similarity, which is more specific to DBI itself, is
that the API definition is uncoupled from any particular implementation,
such that many specialized implementations can exist and be distributed
separately.  Also, a multiplicity of implementations can be used in
parallel by the same application through a common interface.  Where DBI
gives the name 'driver' to each implementation, Rosetta gives the name
'Engine', which may be more descriptive as they sit "beneath" the
interface; in some cases, an Engine can even be fully self-contained,
rather than mediating with an external database.  Another similarity is
that the preparation and execution (with place-holder substitution) of
database instructions are distinct activities, and you can reuse a prepared
instruction for multiple executions to get performance gains.

The Rosetta module does not talk to or implement any databases by itself;
it is up to separately distributed Engine modules to do this.  You can see
a reference implementation of one in the Rosetta::Engine::Generic module. 
Rosetta itself mainly provides a skeleton to which Engines attach, and does
basic input and output validation so that Engines and applications
respectively don't have to; otherwise, an Engine has complete freedom to
fulfill requests how it wishes.

The main difference between Rosetta and the DBI is that Rosetta takes its
input primarily as SQL::Routine (SRT) objects, where DBI takes SQL strings.
 See the documentation for SQL::Routine (distributed separately) for
details on how to define those objects.  Also, when Rosetta dumps a scanned
database schema, it does so as SRT objects, while DBI dumps as either SQL
strings or simple Perl arrays, depending on the schema object type.  Each
'routine' that Rosetta takes as input is equivalent to one or more SQL
statements, where later statements can use the results of earlier ones as
their input.  The named argument list of a 'routine' is analogous to the
bind var list of DBI; each one defines what values can be given to the
statements at "execute" time.

Unlike SQL strings, SRT objects have very little redundancy, and the parts
are linked by references rather than by name; the spelling of each SQL
identifier (such as a table or column name) is stored exactly once; if you
change the single copy, then all code that refers to the entity updates at
once.  SRT objects can also store meta-data that SQL strings can't
accomodate, and you define database actions with the objects in exactly the
same way regardless of the database product in use; you do not write
slightly different versions for each as you do with SQL strings. 
Developers don't have to restrict their conceptual processes into the
limits or dialect of a single product, or spend time worrying about how to
express the same idea against different products.

Rosetta is especially suited for data-driven applications, since the
composite scalar values in their data dictionaries can often be copied
directly to RNI structures, saving applications the tedious work of
generating SQL themselves.

Rosetta is conceptually a DBI wrapper, whose strongest addition is SQL
generation, but it also works without the DBI, and with non-SQL databases;
it is up to each Engine to use or not use DBI, though most will use it
because the DBI is a high quality and mature platform to build upon.

The choice between using DBI and using Rosetta seems to be analogous to the
choice between the C and Java programming languages, respectively, where
each database product is analogous to a hardware CPU architecture or wider
hardware platform.  The DBI is great for people who like working as close
to the metal as possible, with direct access to each database product's
native way of doing things, those who *want* to talk to their database in
its native SQL dialect, and those who want the absolute highest
performance.  Rosetta is more high level, for those who want the write-once
run-anywhere experience, less of a burden on their creativity, more
development time saving features, and are willing to sacrifice a modicum of
performance for the privilege.

There exist on CPAN many dozens of other modules or frameworks whose modus
operandi is to wrap the DBI or be used together with it for various
reasons, such as to provide automated object persistence functionality, or
a cross-database portability solution, or to provide part of a wider scoped
application tool kit, or to generate SQL, or to clone databases, or
generate reports, or provide a web interface, or to provide a "simpler" or
"easier to use" interface.  So, outside the DBI question, a choice exists
between using Rosetta and one of these other CPAN modules.  Going into
detail on that matter is outside the scope of this documentation, but a few
salient points are offered.

For one thing, Rosetta allows you to do a lot more than the alternatives in
an elegant fashion; with other modules, you would often have to inject
fragments of raw SQL into their objects (such as "select" query
conditionals) to accomplish what you want; with Rosetta, you should never
need to do any SQL injection.  For another point, Rosetta has a strong
emphasis on portability between many database products; only a handful of
other modules support more than 2-3 database products, and many only claim
to support one (usually MySQL).  Also, more than half of the other modules
look like they had only 5-20 hours of effort at most put into them, while
Rosetta and its related modules have likely had over 1000 hours of full
time effort put into them.  For another point, there is a frequent lack of
support for commonly desired database features in other modules, such as
multiple column keys.  Also, most modules have a common structural
deficiency such that they are designed to support a very specific set of
database concepts, and adding more is a lot of work; by contrast, Rosetta
is internally designed in a heavily data-driven fashion, allowing the
addition or alternation of many features with little cost in effort or
complexity.

It should be noted that Rosetta itself has no aim to be an
"object-relational mapper", since this isn't related to its primary
function of making all database products look the same; its API is still
defined solidly in relational database specific terms such as schemas,
tables, columns, keys, joins, queries, views, DML, DDL, connections,
cursors, triggers, etc.  If you need an actual "object oriented
persistence" solution, which makes your own custom application objects
transparently persistent, or a persistence layer whose API is defined in
terms like objects and attributes, then you will need an alternative to the
Rosetta core to give that to you, such as modules like Class::DBI, Tangram,
and Alzabo, or a custom solution (these can, of course, be layered on top
of Rosetta).

Perhaps a number of other CPAN modules' authors will see value in adding
back-end support for Rosetta and/or SQL::Routine to their offerings, either
as a supplement to their DBI-using native database SQL back-ends, or as a
single replacement for the lot of them.  Particularly in the latter case,
the authors will be more freed up to focus on their added value, such as
object persistence or web interfaces, rather than worrying about
portability issues.  As quid quo pro, perhaps some of the other CPAN
modules (or parts of them) can be used by a Rosetta Engine to help it do
its work.

I<To cut down on the size of the SQL::Routine module itself, most of the
POD documentation is in these other files: L<Rosetta::Details>,
L<Rosetta::Features>, L<Rosetta::Framework>.>

=head1 CLASSES IN THIS MODULE

This module is implemented by several object-oriented Perl 5 packages, each
of which is referred to as a class.  They are: B<Rosetta> (the module's
name-sake), B<Rosetta::Interface> (aka B<Interface>),
B<Rosetta::Interface::Application> (aka B<Application>),
B<Rosetta::Interface::Environment> (aka B<Environment>),
B<Rosetta::Interface::Connection> (aka B<Connection>),
B<Rosetta::Interface::Cursor> (aka B<Cursor>),
B<Rosetta::Interface::Literal> (aka B<Literal>),
B<Rosetta::Interface::Success> (aka B<Success>),
B<Rosetta::Interface::Preparation> (aka B<Preparation>),
B<Rosetta::Interface::Error> (aka B<Error>), B<Rosetta::Engine> (aka
B<Engine>), and B<Rosetta::Dispatcher> (aka B<Dispatcher>).

I<While all 12 of the above classes are implemented in one module for
convenience, you should consider all 12 names as being "in use"; do not
create any modules or packages yourself that have the same names.>

The Interface classes do most of the work and are what you mainly use.  The
name-sake class mainly exists to guide CPAN in indexing the whole module,
but it also provides a set of stateless utility methods and constants that
the other classes inherit, and it provides wrapper functions over the
Interface classes for your convenience; you never instantiate an object of
'Rosetta' itself.

The Engine class is only invoked indirectly, via the Interface classes;
moreover, you need to choose an external class which subclasses Engine (and
implements all of its methods) to use via the Interface class.

The Dispatcher class is used internally by the Application class (as its
"Engine") to implement an ease-of-use feature of Rosetta where multiple
Rosetta Engines can be used as one.  An example of this is that you can
invoke a CATALOG_LIST built-in routine without specifying an Engine to run
it against; Dispatcher will run that command against each individual Engine
behind the scenes and combine their results; you then see a single list of
databases that Rosetta can access without regard for which Engine mediates
access.  As a second example, you can invoke a CATALOG_OPEN built-in off of
the root Application Interface rather than having to do it against the
correct Environment Interface; Dispatcher will detect which Environment is
required (based on info in your SQL::Routine) and load/dispatch to the
appropriate Engine that mediates the database connection.

=head1 BRIEF FUNCTION AND METHOD LIST

Here is a compact list of this module's functions and methods along with
their arguments.  For full details on each one, please see
L<Rosetta::Details>.

CONSTRUCTOR WRAPPER FUNCTIONS:

    new_application_interface( APP_INST_NODE )
    new_environment_interface( PARENT_INTF, LINK_PROD_NODE )
    new_connection_interface( PARENT_BYCRE_INTF, PARENT_BYCXT_INTF, CAT_LINK_NODE )
    new_cursor_interface( PARENT_BYCRE_INTF, PARENT_BYCXT_INTF, EXTERN_CURS_NODE )
    new_literal_interface( PARENT_BYCRE_INTF )
    new_success_interface( PARENT_BYCRE_INTF )
    new_preparation_interface( PARENT_BYCRE_INTF, ROUTINE_NODE, PREP_ROUTINE )
    new_error_interface( PARENT_BYCRE_INTF, ERROR_MSG )

INTERFACE OBJECT METHODS:

    get_root_interface()
    get_parent_by_creation_interface()
    get_child_by_creation_interfaces()
    get_parent_by_context_interface()
    get_child_by_context_interfaces()
    get_engine()

INDIRECT APPLICATION OBJECT METHODS:

    get_srt_container()
    get_app_inst_node()
    get_trace_fh()
    clear_trace_fh()
    set_trace_fh( NEW_FH )

APPLICATION CONSTRUCTOR FUNCTIONS:

    new( APP_INST_NODE )

APPLICATION OBJECT METHODS:

    features([ FEATURE_NAME ])
    prepare( ROUTINE_DEFN )
    do( ROUTINE_DEFN[, ROUTINE_ARGS] )

ENVIRONMENT CONSTRUCTOR FUNCTIONS:

    new( PARENT_INTF, LINK_PROD_NODE )

ENVIRONMENT OBJECT METHODS:

    get_link_prod_node()
    features([ FEATURE_NAME ])
    prepare( ROUTINE_DEFN )
    do( ROUTINE_DEFN[, ROUTINE_ARGS] )

CONNECTION CONSTRUCTOR FUNCTIONS:

    new( PARENT_BYCRE_INTF, PARENT_BYCXT_INTF, CAT_LINK_NODE )

CONNECTION OBJECT METHODS:

    get_cat_link_node()
    features([ FEATURE_NAME ])
    prepare( ROUTINE_DEFN )
    do( ROUTINE_DEFN[, ROUTINE_ARGS] )

CURSOR CONSTRUCTOR FUNCTIONS:

    new( PARENT_BYCRE_INTF, PARENT_BYCXT_INTF, EXTERN_CURS_NODE )

CURSOR OBJECT METHODS:

    get_extern_curs_node()
    prepare( ROUTINE_DEFN )
    do( ROUTINE_DEFN[, ROUTINE_ARGS] )

LITERAL CONSTRUCTOR FUNCTIONS:

    new( PARENT_BYCRE_INTF )

LITERAL OBJECT METHODS:

    payload()

SUCCESS CONSTRUCTOR FUNCTIONS:

    new( PARENT_BYCRE_INTF )

SUCCESS OBJECT METHODS: (this class has no methods)

PREPARATION CONSTRUCTOR FUNCTIONS:

    new( PARENT_BYCRE_INTF, ROUTINE_NODE, PREP_ROUTINE )

PREPARATION OBJECT METHODS:

    get_routine_node()
    execute([ ROUTINE_ARGS ])

ERROR CONSTRUCTOR FUNCTIONS:

    new( PARENT_BYCRE_INTF, ERROR_MSG )

ERROR OBJECT METHODS:

    get_error_message()

ENGINE OBJECT FUNCTIONS AND METHODS: (none are public)

DISPATCHER OBJECT FUNCTIONS AND METHODS: (none are public)

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl modules L<version> and L<only>, which would
conceptually be built-in to Perl, but aren't, so they are on CPAN instead.

It also requires the Perl module L<Scalar::Util>, which would conceptually
be built-in to Perl, but is bundled with it instead.

It also requires these modules that are on CPAN:

    Locale::KeyedText 1.6.0 (for error messages)
    SQL::Routine 0.70.0

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Rosetta::L::en>, L<Rosetta::Details>, L<Rosetta::Features>,
L<Rosetta::Framework>, L<Locale::KeyedText>, L<SQL::Routine>,
L<Rosetta::Validator>, L<Rosetta::Engine::Generic>,
L<Rosetta::Emulator::DBI>, L<DBI>, L<Alzabo>, L<SPOPS>, L<Class::DBI>,
L<Tangram>, L<HDB>, L<Genezzo>, L<DBIx::RecordSet>, L<DBIx::SearchBuilder>,
L<SQL::Schema>, L<DBIx::Abstract>, L<DBIx::AnyDBD>, L<DBIx::Browse>,
L<DBIx::SQLEngine>, L<MKDoc::SQL>, L<Data::Transactional>,
L<DBIx::ModelUpdate>, L<DBIx::ProcedureCall>, and various other modules.

=head1 BUGS AND LIMITATIONS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible
ways; however, I believe that any further incompatible changes will be
small.  The current state is analogous to 'developer releases' of operating
systems; it is reasonable to being writing code that uses this module now,
but you should be prepared to maintain it later in keeping with API
changes.  All of this said, I plan to move this module into alpha
development status within the next few releases, once I start using it in a
production environment myself.

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 2002-2005, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to C<perl@DarrenDuncan.net>,
or visit L<http://www.DarrenDuncan.net/> for more information.

Rosetta is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (L<http://www.fsf.org/>); either version 2 of the
License, or (at your option) any later version.  You should have received a
copy of the GPL as part of the Rosetta distribution, in the file named
"GPL"; if not, write to the Free Software Foundation, Inc., 51 Franklin St,
Fifth Floor, Boston, MA  02110-1301, USA.

Linking Rosetta statically or dynamically with other modules is making a
combined work based on Rosetta.  Thus, the terms and conditions of the GPL
cover the whole combination.  As a special exception, the copyright holders
of Rosetta give you permission to link Rosetta with independent modules,
regardless of the license terms of these independent modules, and to copy
and distribute the resulting combined work under terms of your choice,
provided that every copy of the combined work is accompanied by a complete
copy of the source code of Rosetta (the version of Rosetta used to produce
the combined work), being distributed under the terms of the GPL plus this
exception.  An independent module is a module which is not derived from or
based on Rosetta, and which is fully useable when not linked to Rosetta in
any form.

Any versions of Rosetta that you modify and distribute must carry prominent
notices stating that you changed the files and the date of any changes, in
addition to preserving this original copyright notice and other credits.
Rosetta is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of Rosetta would
appreciate being informed any time you create a modified version of Rosetta
that you are willing to distribute, because that is a practical way of
suggesting improvements to the standard version.

=cut
