#!perl
use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Rosetta',
	'VERSION_FROM' => 'lib/Rosetta.pm', # finds $VERSION
	'PREREQ_PM' => {
		'Test::More' => '0.47', # but only for the test suite
		'Locale::KeyedText' => '1.03',
		'SQL::Routine' => '0.59',
	},
);

1;
