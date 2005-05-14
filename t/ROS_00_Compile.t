#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 8 );

use_ok( 'Rosetta' );
cmp_ok( $Rosetta::VERSION, '==', 0.45, "Rosetta is the correct version" );

use_ok( 'Rosetta::L::en' );
cmp_ok( $Rosetta::L::en::VERSION, '==', 0.17, "Rosetta::L::en is the correct version" );

use_ok( 'Rosetta::Validator' );
cmp_ok( $Rosetta::Validator::VERSION, '==', 0.45, "Rosetta::Validator is the correct version" );

use_ok( 'Rosetta::Validator::L::en' );
cmp_ok( $Rosetta::Validator::L::en::VERSION, '==', 0.11, "Rosetta::Validator::L::en is the correct version" );

1;
