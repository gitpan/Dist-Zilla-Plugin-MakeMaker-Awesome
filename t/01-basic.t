use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 'does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ 'MakeMaker::Awesome' => { eumm_version => '6.00' } ],
                [ Prereqs => { 'Foo::Bar' => '1.20',      perl => '5.006' } ],
                [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
                [ Prereqs => TestRequires  => { 'Test::Deet'   => '7',
                                                perl           => '5.008' } ],
            ),
            path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
            path(qw(source t basic.t)) => 'warn "here is a test";',
            path(qw(source t more.t)) => 'warn "here is another test";',
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $makemaker = $tzil->plugin_named('MakeMaker::Awesome');

my %want = (
    DISTNAME => 'DZT-Sample',
    NAME     => 'DZT::Sample',
    ABSTRACT => 'Sample DZ Dist',
    VERSION  => '0.001',
    AUTHOR   => 'E. Xavier Ample <example@example.org>',
    LICENSE  => 'perl',
    MIN_PERL_VERSION => '5.008',

    PREREQ_PM          => {
        'Foo::Bar' => '1.20'
    },
    BUILD_REQUIRES     => {
        'Builder::Bob' => '9.901',
    },
    TEST_REQUIRES      => {
        'Test::Deet'   => '7',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.00'
    },
    EXE_FILES => [],
    test => { TESTS => 't/*.t' },
  );

cmp_deeply(
    { $makemaker->WriteMakefile_args },
    \%want,
    'correct makemaker args generated',
);

my $content = $tzil->slurp_file('build/Makefile.PL');

unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

my $VERSION = Dist::Zilla::Plugin::MakeMaker::Awesome->VERSION || '<self>';

like(
    $content,
    qr/\A# This Makefile\.PL for DZT-Sample was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome $VERSION\.
# Don't edit it but the dist\.ini and plugins used to construct it\.

use strict;
use warnings;

use 5\.008;
use ExtUtils::MakeMaker 6\.00;

my \%WriteMakefileArgs = \(/,
    'Makefile.PL header looks correct',
);

like(
    $content,
    qr/(?{ quotemeta($tzil->plugin_named('MakeMaker::Awesome')->_dump_as(\%want, '*WriteMakefileArgs')) })/,
    'arguments are dumped to Makefile.PL',
);

subtest 'run the generated Makefile.PL' => sub
{
    my $wd = pushd path($tzil->tempdir)->child('build');
    is(
        exception { $makemaker->build },
        undef,
        'Makefile.PL can be run successfully',
    );
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
