#!perl

use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	=> 'Rosetta',
	VERSION_FROM => 'lib/Rosetta.pm', # finds $VERSION
	PREREQ_PM => {
		'Locale::KeyedText' => '1.01',
		'SQL::Routine' => '0.52',
	},
);

1;
