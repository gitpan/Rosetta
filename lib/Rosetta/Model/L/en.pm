#!perl
use 5.008001; use utf8; use strict; use warnings;

package Rosetta::Model::L::en;
use version; our $VERSION = qv('0.39.0');

######################################################################

my $CC = 'Rosetta::Model::Container';
my $CN = 'Rosetta::Model::Node';
my $CG = 'Rosetta::Model::Group';

my %text_strings = (
    'ROS_M_C_METH_VIOL_WRITE_BLOCKS' =>
        $CC . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a write block is imposed on it by at least one Container interface, ]
        . q[so it can not be edited or deleted],

    'ROS_M_C_METH_ARG_UNDEF' =>
        $CC . q[.{METH}(): ]
        . q[undefined (or missing) {ARGNM} argument],
    'ROS_M_C_METH_ARG_NO_ARY' =>
        $CC . q[.{METH}(): ]
        . q[invalid {ARGNM} argument; it is not an array ref, but rather is "{ARGVL}"],

    'ROS_M_C_METH_ARG_ARY_ELEM_UNDEF' =>
        $CC . q[.{METH}(): ]
        . q[invalid {ARGNM} array argument; undefined element],
    'ROS_M_C_METH_ARG_ARY_ELEM_NO_ARY' =>
        $CC . q[.{METH}(): ]
        . q[invalid {ARGNM} array argument; element not an array ref, but rather is "{ELEMVL}"],

    'ROS_M_C_GET_CH_NODES_BAD_TYPE' =>
        $CC . q[.get_child_nodes(): ]
        . q[invalid NODE_TYPE argument; there is no Node Type named "{ARGNTYPE}"],

    'ROS_M_C_BUILD_CH_ND_NO_PSND' =>
        $CC . q[.build_child_node(): ]
        . q[invalid NODE_TYPE argument; a "{ARGNTYPE}" Node does not ]
        . q[have a pseudo-Node parent and can not be made a direct child of a Container],

    'ROS_M_C_BUILD_CH_ND_TR_NO_PSND' =>
        $CC . q[.build_child_node_tree(): ]
        . q[invalid NODE_TYPE argument; a "{ARGNTYPE}" Node does not ]
        . q[have a pseudo-Node parent and can not be made a direct child of a Container],

    'ROS_M_N_METH_VIOL_WRITE_BLOCKS' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a write block is imposed on it by at least one Container interface, ]
        . q[so it can not be edited or deleted],
    'ROS_M_N_METH_VIOL_PC_ADD_BLOCKS' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a primary child addition block is imposed on it by at least one Container interface, ]
        . q[so it can not gain primary child Nodes],
    'ROS_M_N_METH_VIOL_LC_ADD_BLOCKS' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a referencing/link child addition block is imposed on it by at least one Container interface, ]
        . q[so it can not gain referencing/link child Nodes],

    'ROS_M_N_METH_ARG_UNDEF' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[undefined (or missing) {ARGNM} argument],
    'ROS_M_N_METH_ARG_NO_ARY' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid {ARGNM} argument; it is not an array ref, but rather is "{ARGVL}"],
    'ROS_M_N_METH_ARG_NO_HASH' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid {ARGNM} argument; it is not a hash ref, but rather is "{ARGVL}"],
    'ROS_M_N_METH_ARG_NO_NODE' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid {ARGNM} argument; it is not a Node object, but rather is "{ARGVL}"],

    'ROS_M_N_METH_ARG_ARY_ELEM_UNDEF' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid {ARGNM} array argument; undefined element],
    'ROS_M_N_METH_ARG_ARY_ELEM_NO_ARY' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid {ARGNM} array argument; element not an array ref, but rather is "{ELEMVL}"],

    'ROS_M_N_NEW_NODE_NO_ARG_CONT' =>
        $CN . q[.new_node(): ]
        . q[missing CONTAINER argument],
    'ROS_M_N_NEW_NODE_BAD_CONT' =>
        $CN . q[.new_node(): ]
        . q[invalid CONTAINER argument; it is not a Container object, but rather is "{ARGNCONT}"],
    'ROS_M_N_NEW_NODE_NO_ARG_TYPE' =>
        $CN . q[.new_node(): ]
        . q[missing NODE_TYPE argument],
    'ROS_M_N_NEW_NODE_BAD_TYPE' =>
        $CN . q[.new_node(): ]
        . q[invalid NODE_TYPE argument; there is no Node Type named "{ARGNTYPE}"],
    'ROS_M_N_NEW_NODE_NO_ARG_ID' =>
        $CN . q[.new_node(): ]
        . q[concerning the new "{ARGNTYPE}" Node under construction; ]
        . q[missing NODE_ID argument and the given Container interface is not configured to auto-set missing Node Ids],
    'ROS_M_N_NEW_NODE_BAD_ID' =>
        $CN . q[.new_node(): ]
        . q[concerning the new "{ARGNTYPE}" Node under construction; ]
        . q[invalid NODE_ID argument; a Node Id may only be a positive integer; ]
        . q[you tried to set it to "{ARGNID}"],
    'ROS_M_N_NEW_NODE_DUPL_ID' =>
        $CN . q[.new_node(): ]
        . q[concerning the new "{ARGNTYPE}" Node under construction; ]
        . q[invalid NODE_ID argument; the Node Id value of "{ARGNID}" you tried to set ]
        . q[is already in use by another Node in the same Container; it must be distinct],

    'ROS_M_N_DEL_NODE_HAS_CHILD' =>
        $CN . q[.delete_node(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[this Node can not be deleted yet because it has child Nodes of its own; ]
        . q[specifically {PRIM_COUNT} primary-child Nodes plus {LINK_COUNT} link-child Nodes],

    'ROS_M_N_DEL_NODE_TREE_HAS_EXT_CHILD' =>
        $CN . q[.delete_node_tree(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[the Node tree rooted here can not be deleted yet because one or more of ]
        . q[its members are referenced by other Nodes that are outside of the tree; ]
        . q[the "{CNTYPE}" Node with Id "{CNID}" and Surrogate Id Chain "{CSIDCH}" is a link-child of ]
        . q[the "{PNTYPE}" tree member Node with Id "{PNID}" and Surrogate Id Chain "{PSIDCH}".],

    'ROS_M_N_SET_NODE_ID_BAD_ARG' =>
        $CN . q[.set_node_id(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid NEW_ID argument; a Node Id may only be a positive integer; ]
        . q[you tried to set it to "{ARG}"],
    'ROS_M_N_SET_NODE_ID_DUPL_ID' =>
        $CN . q[.set_node_id(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid NEW_ID argument; the Node Id value of "{ARG}" you tried to set ]
        . q[is already in use by another Node in the same Container; it must be distinct],

    'ROS_M_N_METH_NO_PP_AT' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[there is no primary parent attribute in this Node],

    'ROS_M_N_SET_PP_AT_CIRC_REF' =>
        $CN . q[.set_primary_parent_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; that Node is a direct ]
        . q[or indirect child of this current Node, so they can not be linked; ]
        . q[if they were linked, that would result in a circular reference chain],

    'ROS_M_N_SET_PP_AT_WRONG_NODE_TYPE' =>
        $CN . q[.set_primary_parent_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; the given Node is an "{ARGNTYPE}" ]
        . q[Node but this Node-ref attribute may only reference a "{EXPNTYPE}" Node],
    'ROS_M_N_SET_PP_AT_DIFF_CONT' =>
        $CN . q[.set_primary_parent_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; that Node is not in ]
        . q[the same Container as this current Node, so they can not be linked],
    'ROS_M_N_SET_PP_AT_NONEX_NID' =>
        $CN . q[.set_primary_parent_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; "{ARG}" looks like a Node Id but ]
        . q[it does not match the Id of any "{EXPNTYPE}" Node in this Node's Container],
    'ROS_M_N_SET_PP_AT_NO_ALLOW_SID_FOR_PP' =>
        $CN . q[.set_primary_parent_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; "{ARG}" looks like a Surrogate Id but ]
        . q[you may not use Surrogate Ids to match Nodes when setting the primary parent attribute; ]
        . q[ATTR_VALUE must be either a Node ref or a positive integer Node Id],

    'ROS_M_N_CLEAR_SI_AT_MAND_NID' =>
        $CN . q[.clear_surrogate_id_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[you can not clear the "id" attribute because the Node Id is constantly always mandatory],

    'ROS_M_N_METH_ARG_NO_AT_NM' =>
        $CN . q[.{METH}(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid {ARGNM} argument; there is no attribute named "{ARGVL}" in this Node],

    'ROS_M_N_CLEAR_AT_MAND_NID' =>
        $CN . q[.clear_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[you can not clear the "id" attribute because the Node Id is constantly always mandatory],

    'ROS_M_N_SET_AT_NO_ARG_VAL' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[missing ATTR_VALUE argument when setting "{ATNM}"],

    'ROS_M_N_SET_AT_INVAL_LIT_V_IS_REF' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; this Node's literal attribute named "{ATNM}" may only be ]
        . q[a scalar value; you tried to set it to a "{ARG_REF_TYPE}" reference],
    'ROS_M_N_SET_AT_INVAL_LIT_V_BOOL' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; this Node's literal attribute named "{ATNM}" may only be ]
        . q[a boolean value, as expressed by "0" or "1"; you tried to set it to "{ARG}"],
    'ROS_M_N_SET_AT_INVAL_LIT_V_UINT' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; this Node's literal attribute named "{ATNM}" may only be ]
        . q[a non-negative integer; you tried to set it to "{ARG}"],
    'ROS_M_N_SET_AT_INVAL_LIT_V_SINT' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; this Node's literal attribute named "{ATNM}" may only be ]
        . q[an integer; you tried to set it to "{ARG}"],

    'ROS_M_N_SET_AT_INVAL_ENUM_V' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument; this Node's enumerated attribute named "{ATNM}" may only be ]
        . q[a "{ENUMTYPE}" value; you tried to set it to "{ARG}"],

    'ROS_M_N_SET_AT_NREF_WRONG_NODE_TYPE' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument when setting "{ATNM}"; the given Node is an "{ARGNTYPE}" ]
        . q[Node but this Node-ref attribute may only reference a "{EXPNTYPE}" Node],
    'ROS_M_N_SET_AT_NREF_DIFF_CONT' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument when setting "{ATNM}"; that Node is not in ]
        . q[the same Container as this current Node, so they can not be linked],
    'ROS_M_N_SET_AT_NREF_NONEX_NID' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Node Id but ]
        . q[it does not match the Id of any "{EXPNTYPE}" Node in this Node's Container],
    'ROS_M_N_SET_AT_NREF_NO_ALLOW_SID' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but ]
        . q[this Node's host Container interface does not allow the use of Surrogate Ids to match Nodes when linking; ]
        . q[ATTR_VALUE must be either a Node ref or a positive integer Node Id],
    'ROS_M_N_SET_AT_NREF_NONEX_SID' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but ]
        . q[it does not match the Surrogate Id of any "{EXPNTYPE}" Node in this Node's Container],
    'ROS_M_N_SET_AT_NREF_AMBIG_SID' =>
        $CN . q[.set_attribute(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but ]
        . q[it is too ambiguous to match the Surrogate Id of any single "{EXPNTYPE}" Node in this Node's Container; ]
        . q[all of these Nodes are equally qualified to match, but only one is allowed to: "{CANDIDATES}"],

    'ROS_M_N_SET_ATS_NO_ARG_ELEM_VAL' =>
        $CN . q[.set_attributes(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[missing ATTRS argument element value when setting key "{ATNM}"],
    'ROS_M_N_SET_ATS_INVAL_ELEM_NM' =>
        $CN . q[.set_attributes(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid ATTRS argument element key; there is no attribute named "{ATNM}" in this Node],

    'ROS_M_N_MOVE_PRE_SIB_S_DIFF_CONT' =>
        $CN . q[.move_before_sibling(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid SIBLING argument; that Node is not in ]
        . q[the same Container as this current Node, so they can not be siblings],
    'ROS_M_N_MOVE_PRE_SIB_P_DIFF_CONT' =>
        $CN . q[.move_before_sibling(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid PARENT argument; that Node is not in ]
        . q[the same Container as this current Node, so they can not be related],
    'ROS_M_N_MOVE_PRE_SIB_NO_P_ARG_OR_PP_OR_PS' =>
        $CN . q[.move_before_sibling(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[no PARENT argument was given, and this current Node ]
        . q[has no primary parent Node or parent pseudo-Node for it to default to],
    'ROS_M_N_MOVE_PRE_SIB_P_NOT_P' =>
        $CN . q[.move_before_sibling(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid PARENT argument; this current Node is not a child of that Node],
    'ROS_M_N_MOVE_PRE_SIB_S_NOT_S' =>
        $CN . q[.move_before_sibling(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid SIBLING argument; this current Node does not share PARENT ]
        . q[(or its primary parent) with that Node],

    'ROS_M_N_GET_CH_NODES_BAD_TYPE' =>
        $CN . q[.get_child_nodes(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid NODE_TYPE argument; there is no Node Type named "{NTYPE}"],

    'ROS_M_N_GET_REF_NODES_BAD_TYPE' =>
        $CN . q[.get_referencing_nodes(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid NODE_TYPE argument; there is no Node Type named "{NTYPE}"],

    'ROS_M_N_FIND_ND_BY_SID_NO_ARG_VAL' =>
        $CN . q[.find_node_by_surrogate_id(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[missing TARGET_ATTR_VALUE argument for the Node-ref attribute named "{ATNM}"; ]
        . q[either the argument itself is undefined, or it is a Perl array ref which contains an undefined element],
    'ROS_M_N_FIND_ND_BY_SID_NO_REM_ADDR' =>
        $CN . q[.find_node_by_surrogate_id(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[invalid TARGET_ATTR_VALUE argument for the Node-ref attribute named "{ATNM}"; ]
        . q["{ATVL}" contains multiple elements but the allowable target Node types can only be addressed using a single element],

    'ROS_M_N_ASDC_NID_VAL_NO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[its Node ID must always be given a value],
    'ROS_M_N_ASDC_PP_VAL_NO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[its primary parent Node attribute ("pp") must always be given a value],
    'ROS_M_N_ASDC_SI_VAL_NO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[this Node's surrogate id attribute named "{ATNM}" must always be given a value],
    'ROS_M_N_ASDC_MA_VALS_NO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; the "{ATNMS}" attributes must always be given values],

    'ROS_M_N_ASDC_MUTEX_TOO_MANY_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[{NUMVALS} of its attributes ({ATNMS}) in the mutual-exclusivity group "{MUTEX}" are set; ]
        . q[you must change all but one of them to be undefined/null],
    'ROS_M_N_ASDC_MUTEX_ZERO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[none of its attributes ({ATNMS}) in the mutual-exclusivity group "{MUTEX}" are set; ]
        . q[you must give a value to exactly one of them],

    'ROS_M_N_ASDC_LATDP_DEP_ON_IS_NULL' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[the depended-on attribute "{DEP_ON}" is undef/null so all of its dependents must be too; ]
        . q[you must clear these {NUMVALS} attributes: {ATNMS}],
    'ROS_M_N_ASDC_LATDP_DEP_ON_HAS_WRONG_VAL' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[the depended-on attribute "{DEP_ON}" has a value of "{DEP_ON_VAL}", which is different ]
        . q[than the value(s) that certain dependents require for being set; ]
        . q[you must clear these {NUMVALS} attributes: {ATNMS}],
    'ROS_M_N_ASDC_LATDP_TOO_MANY_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[the depended-on attribute "{DEP_ON}" has a value of "{DEP_ON_VAL}", which means that ]
        . q[only one of these {NUMVALS} currently set dependent attributes may be set: {ATNMS}],
    'ROS_M_N_ASDC_LATDP_ZERO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[the depended-on attribute "{DEP_ON}" has a value of "{DEP_ON_VAL}", which means that ]
        . q[exactly one of these dependent attributes must be set: {ATNMS}],

    'ROS_M_N_ASDC_NREF_AT_NONEX_SID' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; the Node-ref attribute "{ATNM}" is currently ]
        . q[linked to the "{PNTYPE}" Node with Id "{PNID}" and Surrogate Id Chain "{PSIDCH}"; ]
        . q[that parent Node is not within the visible scope of the current child ]
        . q[(when searching with the target surrogate id "{PSID}") so the child may not link to it],

    'ROS_M_N_ASDC_REL_ENUM_BAD_P_NTYPE' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; the enumerated attribute "{CATNM}" may only be ]
        . q[set when the parent Node's type is one of "{PALLOWED}"; the type is currently "{PNTYPE}"],
    'ROS_M_N_ASDC_REL_ENUM_NO_P' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; the enumerated attribute "{CATNM}" may not be ]
        . q[set because the parent Node's related enumerated attribute "{PATNM}" is not set],
    'ROS_M_N_ASDC_REL_ENUM_P_NEVER_P' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; the enumerated ("{CENUMTYPE}") attribute "{CATNM}" ]
        . q[(having the value "{CATVL}") may not be set because the parent Node's related ]
        . q[enumerated ("{PENUMTYPE}") attribute "{PATNM}" has the value "{PATVL}", ]
        . q[which does not allow any children of the child attribute's enumerated type],
    'ROS_M_N_ASDC_REL_ENUM_P_C_NOT_REL' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; the enumerated ("{CENUMTYPE}") attribute "{CATNM}" ]
        . q[has an invalid value of "{CATVL}" when used with the parent Node's related ]
        . q[enumerated ("{PENUMTYPE}") attribute "{PATNM}" value of "{PATVL}"; ]
        . q[that parent only allows these child values of the child's enumerated type: {CALLOWED}],

    'ROS_M_N_ASDC_SI_NON_DISTINCT' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; at least two of its child Nodes have ]
        . q[an identical surrogate id value ("{VALUE}"); you must change ]
        . q[either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"],
    'ROS_M_N_ASDC_SI_NON_DISTINCT_PSN' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{PSNTYPE}" pseudo-Node; ]
        . q[a deferrable constraint was violated; at least two of its child Nodes have ]
        . q[an identical surrogate id value ("{VALUE}"); you must change ]
        . q[either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"],

    'ROS_M_N_ASDC_CH_N_TOO_FEW_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; this Node has too few ({COUNT}) ]
        . q[primary-child "{CNTYPE}" Nodes; you must have at least {EXPNUM} of them],
    'ROS_M_N_ASDC_CH_N_TOO_FEW_SET_PSN' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{PSNTYPE}" pseudo-Node; ]
        . q[a deferrable constraint was violated; this pseudo-Node has too few ({COUNT}) ]
        . q[primary-child "{CNTYPE}" Nodes; you must have at least {EXPNUM} of them],
    'ROS_M_N_ASDC_CH_N_TOO_MANY_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; this Node has too many ({COUNT}) ]
        . q[primary-child "{CNTYPE}" Nodes; you must have no more than {EXPNUM} of them],
    'ROS_M_N_ASDC_CH_N_TOO_MANY_SET_PSN' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{PSNTYPE}" pseudo-Node; ]
        . q[a deferrable constraint was violated; this pseudo-Node has too many ({COUNT}) ]
        . q[primary-child "{CNTYPE}" Nodes; you must have no more than {EXPNUM} of them],

    'ROS_M_N_ASDC_MUDI_NON_DISTINCT' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[at least two of its child Nodes have identical attribute set values ("{VALUES}") ]
        . q[with respect to the mutual-distinct child group "{MUDI}"; you must change ]
        . q[either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"],
    'ROS_M_N_ASDC_MUDI_NON_DISTINCT_PSN' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{PSNTYPE}" pseudo-Node; ]
        . q[a deferrable constraint was violated; ]
        . q[at least two of its child Nodes have identical attribute set values ("{VALUES}") ]
        . q[with respect to the mutual-distinct child group "{MUDI}"; you must change ]
        . q[either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"],

    'ROS_M_N_ASDC_MA_REL_ENUM_TOO_MANY_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[when its parent Node's related enumerated attribute "{PATNM}" is set, ]
        . q[exactly one of its related enumerated attributes ({CATNMS}) must be set; ]
        . q[{NUMVALS} are currently set, so you must unset all but one of those],
    'ROS_M_N_ASDC_MA_REL_ENUM_ZERO_SET' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[when its parent Node's related enumerated attribute "{PATNM}" is set, ]
        . q[exactly one of its related enumerated attributes ({CATNMS}) must be set; ]
        . q[none are currently set, so you must give a value to exactly one of them],
    'ROS_M_N_ASDC_MA_REL_ENUM_MISSING_VALUES' =>
        $CN . q[.assert_deferrable_constraints(): ]
        . q[concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; ]
        . q[a deferrable constraint was violated; ]
        . q[when its enumerated ("{PENUMTYPE}") attribute "{PATNM}" has a value value of "{PATVL}", ]
        . q[this Node must have a child Node whose appropriate related enumerated attribute is set ]
        . q[for each of these child enumerated values, which are all missing: {CATVLS}],

    'ROS_M_G_NEW_GROUP_NO_ARG_CONT' =>
        $CG . q[.new_group(): ]
        . q[missing CONTAINER argument],
    'ROS_M_G_NEW_GROUP_BAD_CONT' =>
        $CG . q[.new_group(): ]
        . q[invalid CONTAINER argument; it is not a Container object, but rather is "{ARGNCONT}"],
);

######################################################################

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    return $text_strings{$msg_key};
}

######################################################################

1;
__END__

=encoding utf8

=head1 NAME

Rosetta::Model::L::en - Localization of Rosetta::Model for English

=head1 VERSION

This document describes Rosetta::Model::L::en version 0.39.0.

=head1 SYNOPSIS

    use Locale::KeyedText;
    use Rosetta::Model;

    # do work ...

    my $translator = Locale::KeyedText->new_translator( ['Rosetta::Model::L::'], ['en'] );

    # do work ...

    eval {
        # do work with Rosetta::Model, which may throw an exception ...
    };
    if (my $error_message_object = $@) {
        # examine object here if you want and programmatically recover...

        # or otherwise do the next few lines...
        my $error_user_text = $translator->translate_message( $error_message_object );
        # display $error_user_text to user by some appropriate means
    }

    # continue working, which may involve using Rosetta::Model some more ...

=head1 DESCRIPTION

The Rosetta::Model::L::en Perl 5 module contains localization data for
Rosetta::Model.  It is designed to be interpreted by Locale::KeyedText.

This class is optional and you can still use Rosetta::Model effectively
without it, especially if you plan to either show users different error
messages than this class defines, or not show them anything because you are
"handling it".

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

    my $user_text_template = Rosetta::Model::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the
associated user text template string, if there is one, or undef if not.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl module L<version>, which would conceptually be
built-in to Perl, but isn't, so it is on CPAN instead.

This module has no enforced dependencies on L<Locale::KeyedText>, which is
on CPAN, or on L<Rosetta::Model>, which is in the current distribution, but
it is designed to be used in conjunction with them.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<Rosetta::Model>.

=head1 BUGS AND LIMITATIONS

The structure of this module is trivially simple and has no known bugs.

However, the locale data that this module contains may be subject to large
changes in the future; you can determine the likeliness of this by
examining the development status and/or BUGS AND LIMITATIONS documentation
of the other module that this one is localizing; there tends to be a high
correlation in the rate of change between that module and this one.

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the Rosetta database portability library.

Rosetta is Copyright (c) 2002-2005, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to perl@DarrenDuncan.net, or
visit http://www.DarrenDuncan.net/ for more information.

Rosetta is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (http://www.fsf.org/); either version 2 of the License,
or (at your option) any later version.  You should have received a copy of
the GPL as part of the Rosetta distribution, in the file named "GPL"; if
not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth
Floor, Boston, MA  02110-1301, USA.

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
