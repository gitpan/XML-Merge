#!/usr/bin/perl
  use Module::Build;
      Module::Build->new(
  # 'module_name'                   => 'XML::Merge',
    'dist_name'                     => 'XML-Merge',
  # 'dist_version_from'             => 'Merge.pm',
    'dist_version'                  => '1.2.565EgGd',
    'dist_abstract'                 => 'flexibly merge XML documents',
    'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
  # 'create_readme'                 => '1',
  # 'create_makefile_pl'            => '1',
    'license'                       => 'gpl',
    'script_files'                  => {
    },
    'pm_files'                      => {
      'Merge.pm'                      => 'lib/XML/Merge.pm',
    },
    'requires'                      => {
      'XML::Tidy'                     => '0',
    },
  )->create_build_script();