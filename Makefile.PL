
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A more awesome MakeMaker plugin for L<Dist::Zilla>',
  'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-MakeMaker-Awesome',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::MakeMaker::Awesome',
  'PREREQ_PM' => {
    'Dist::Zilla::File::InMemory' => '0',
    'Dist::Zilla::Plugin::MakeMaker' => '3.101450',
    'Dist::Zilla::Role::BuildRunner' => '0',
    'Dist::Zilla::Role::InstallTool' => '0',
    'Dist::Zilla::Role::PrereqSource' => '0',
    'Dist::Zilla::Role::TestRunner' => '0',
    'Dist::Zilla::Role::TextTemplate' => '0',
    'List::MoreUtils' => '0',
    'Moose' => '0',
    'Moose::Autobox' => '0',
    'MooseX::Types::Moose' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.07',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM}; 
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod}; 
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



