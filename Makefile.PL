use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'Rosetta',
	VERSION => 0.21, # for the distribution itself, not of individual modules
	PREREQ_PM => {
		'Locale::KeyedText' => 0.02,
	},
);
