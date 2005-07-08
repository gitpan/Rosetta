#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 12 );

use_ok( 'Rosetta' );
cmp_ok( $Rosetta::VERSION, '==', 0.46, "Rosetta is the correct version" );

use_ok( 'Rosetta::L::en' );
cmp_ok( $Rosetta::L::en::VERSION, '==', 0.18, "Rosetta::L::en is the correct version" );

use_ok( 'Rosetta::Validator' );
cmp_ok( $Rosetta::Validator::VERSION, '==', 0.46, "Rosetta::Validator is the correct version" );

use_ok( 'Rosetta::Validator::L::en' );
cmp_ok( $Rosetta::Validator::L::en::VERSION, '==', 0.12, "Rosetta::Validator::L::en is the correct version" );

use_ok( 'Rosetta::Utility::EasyBake' );
cmp_ok( $Rosetta::Utility::EasyBake::VERSION, '==', 0.01, "Rosetta::Utility::EasyBake is the correct version" );

use_ok( 'Rosetta::Utility::EasyBake::L::en' );
cmp_ok( $Rosetta::Utility::EasyBake::L::en::VERSION, '==', 0.01, "Rosetta::Utility::EasyBake::L::en is the correct version" );

1;
