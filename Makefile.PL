use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Audio',
    'EXE_FILES' => ['morse'],
    'clean' => {FILES => "*% *.bak Base/*% out*.au"},
    'linkext' => { LINKTYPE => ''},
#   'OBJECT'   => '$(O_FILES)',
    'dist'     => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
    'VERSION_FROM'  => "Data/Data.pm"
);


