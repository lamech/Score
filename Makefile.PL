use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Score',
    'VERSION'      => '1.0',
    'PREREQ_PM'         => {
        Text::Table => '0',
        Text::Aligner => '0'
    },
    AUTHOR     => 'Dan Friedman <dan@boywithmachine.net>',
);
