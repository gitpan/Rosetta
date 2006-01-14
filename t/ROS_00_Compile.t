#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;
use version;

plan( 'tests' => 35 );

use_ok( 'Rosetta' );
is( $Rosetta::VERSION, qv('0.71.0'), 'Rosetta is the correct version' );

use_ok( 'Rosetta::L::en' );
is( $Rosetta::L::en::VERSION, qv('0.20.0'), 'Rosetta::L::en is the correct version' );

use_ok( 'Rosetta::Model' );
is( $Rosetta::Model::VERSION, qv('0.71.0'), 'Rosetta::Model is the correct version' );

use_ok( 'Rosetta::Model::L::en' );
is( $Rosetta::Model::L::en::VERSION, qv('0.39.0'), 'Rosetta::Model::L::en is the correct version' );

use_ok( 'Rosetta::Validator' );
is( $Rosetta::Validator::VERSION, qv('0.71.0'), 'Rosetta::Validator is the correct version' );

use_ok( 'Rosetta::Validator::L::en' );
is( $Rosetta::Validator::L::en::VERSION, qv('0.15.0'), 'Rosetta::Validator::L::en is the correct version' );

use lib 't/lib';

use_ok( 't_ROS_Util' );
can_ok( 't_ROS_Util', 'message' );
can_ok( 't_ROS_Util', 'error_to_string' );

use_ok( 't_ROS_Verbose' );
can_ok( 't_ROS_Verbose', 'populate_model' );
can_ok( 't_ROS_Verbose', 'expected_model_nid_xml_output' );
can_ok( 't_ROS_Verbose', 'expected_model_sid_long_xml_output' );
can_ok( 't_ROS_Verbose', 'expected_model_sid_short_xml_output' );

use_ok( 't_ROS_Terse' );
can_ok( 't_ROS_Terse', 'populate_model' );
can_ok( 't_ROS_Terse', 'expected_model_nid_xml_output' );
can_ok( 't_ROS_Terse', 'expected_model_sid_long_xml_output' );
can_ok( 't_ROS_Terse', 'expected_model_sid_short_xml_output' );

use_ok( 't_ROS_Abstract' );
can_ok( 't_ROS_Abstract', 'populate_model' );
can_ok( 't_ROS_Abstract', 'expected_model_nid_xml_output' );
can_ok( 't_ROS_Abstract', 'expected_model_sid_long_xml_output' );
can_ok( 't_ROS_Abstract', 'expected_model_sid_short_xml_output' );

use_ok( 't_ROS_Synopsis' );
can_ok( 't_ROS_Synopsis', 'populate_model' );
can_ok( 't_ROS_Synopsis', 'expected_model_nid_xml_output' );
can_ok( 't_ROS_Synopsis', 'expected_model_sid_long_xml_output' );
can_ok( 't_ROS_Synopsis', 'expected_model_sid_short_xml_output' );

1;
