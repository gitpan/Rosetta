#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

use Test::More;
use version;

plan( 'tests' => 12 );

use_ok( 'Rosetta' );
is( $Rosetta::VERSION, qv('0.720.0'),
    'Rosetta is the correct version' );

use_ok( 'Rosetta::L::en' );
is( $Rosetta::L::en::VERSION, qv('0.210.0'),
    'Rosetta::L::en is the correct version' );

use_ok( 'Rosetta::Model' );
is( $Rosetta::Model::VERSION, qv('0.720.0'),
    'Rosetta::Model is the correct version' );

use_ok( 'Rosetta::Model::L::en' );
is( $Rosetta::Model::L::en::VERSION, qv('0.400.0'),
    'Rosetta::Model::L::en is the correct version' );

use_ok( 'Rosetta::Validator' );
is( $Rosetta::Validator::VERSION, qv('0.720.0'),
    'Rosetta::Validator is the correct version' );

use_ok( 'Rosetta::Validator::L::en' );
is( $Rosetta::Validator::L::en::VERSION, qv('0.160.0'),
    'Rosetta::Validator::L::en is the correct version' );

1; # Magic true value required at end of a reuseable file's code.
