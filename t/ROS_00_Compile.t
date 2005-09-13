#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;
use version;

plan( 'tests' => 8 );

use_ok( 'Rosetta' );
is( $Rosetta::VERSION, qv('0.48.1'), "Rosetta is the correct version" );

use_ok( 'Rosetta::L::en' );
is( $Rosetta::L::en::VERSION, qv('0.19.1'), "Rosetta::L::en is the correct version" );

use_ok( 'Rosetta::Validator' );
is( $Rosetta::Validator::VERSION, qv('0.48.1'), "Rosetta::Validator is the correct version" );

use_ok( 'Rosetta::Validator::L::en' );
is( $Rosetta::Validator::L::en::VERSION, qv('0.14.1'), "Rosetta::Validator::L::en is the correct version" );

1;
