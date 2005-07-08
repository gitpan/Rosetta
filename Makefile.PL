#!perl
use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Rosetta',
	'VERSION_FROM' => 'lib/Rosetta.pm', # finds $VERSION
	'PREREQ_PM' => {
		'Scalar::Util' => '1.11', # for weak refs
		'Test::More' => '0.47', # but only for the test suite
		'Locale::KeyedText' => '1.05',
		'SQL::Routine' => '0.65',
	},
);

1;
