use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/MakeMaker/Awesome.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-perl-normalization.t',
    't/03-dump-config.t',
    't/04-overrides.t',
    't/05-simple-configs.t',
    't/07-authors.t',
    't/zzz-check-breaks.t'
);

notabs_ok($_) foreach @files;
done_testing;
