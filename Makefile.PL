use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'Rosetta',
	VERSION_FROM => 'lib/Rosetta.pm', # finds $VERSION
	PREREQ_PM => {
		'Locale::KeyedText' => 0.06,
		'SQL::SyntaxModel' => 0.38,
	},
);
