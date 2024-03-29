use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # # the contents of the Makefile that is written.
  WriteMakefile(
    'NAME'         => 'XML::Merge',
    'VERSION'      => '1.2.565EgGd',
    'ABSTRACT'     => 'flexibly merge XML documents',
    'AUTHOR'       => 'Pip Stuart <Pip@CPAN.Org>',
    'EXE_FILES'    => [ 
                      ],
    'PREREQ_PM'    => {
      'XML::Tidy'                      => 0,
    }, # Module::Name => 1.1,
    'dist'         => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'tgz' },
  );