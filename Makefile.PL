
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Dist::Zilla::Plugin::MakeMaker::Awesome',
                       'DISTNAME' => 'Dist-Zilla-Plugin-MakeMaker-Awesome',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0'
                                           },
                       'ABSTRACT' => 'A more awesome MakeMaker plugin for L<Dist::Zilla>',
                       'EXE_FILES' => [],
                       'VERSION' => '0.05',
                       'PREREQ_PM' => {
                                        'Dist::Zilla::Role::TextTemplate' => '0',
                                        'MooseX::Types::Moose' => '0',
                                        'Dist::Zilla::Role::PrereqSource' => '0',
                                        'namespace::autoclean' => '0',
                                        'Dist::Zilla::Role::BuildRunner' => '0',
                                        'Dist::Zilla::File::InMemory' => '0',
                                        'Dist::Zilla::Role::TestRunner' => '0',
                                        'Moose::Autobox' => '0',
                                        'Dist::Zilla::Role::InstallTool' => '0',
                                        'Dist::Zilla::Plugin::MakeMaker' => '0',
                                        'List::MoreUtils' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



