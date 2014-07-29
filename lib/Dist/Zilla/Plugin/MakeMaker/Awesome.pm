package Dist::Zilla::Plugin::MakeMaker::Awesome;
BEGIN {
  $Dist::Zilla::Plugin::MakeMaker::Awesome::AUTHORITY = 'cpan:AVAR';
}
# git description: v0.21-4-g1c3dd98
$Dist::Zilla::Plugin::MakeMaker::Awesome::VERSION = '0.22';
# ABSTRACT: A more awesome MakeMaker plugin for L<Dist::Zilla>
# KEYWORDS: plugin installer MakeMaker Makefile.PL toolchain customize override

use Moose;
use MooseX::Types::Moose qw< Str ArrayRef HashRef >;
use MooseX::Types::Stringlike 'Stringlike';
use Moose::Autobox;
use namespace::autoclean;
use CPAN::Meta::Requirements 2.121; # requirements_for_module

extends 'Dist::Zilla::Plugin::MakeMaker' => { -version => 5.001 };

sub mvp_multivalue_args { qw(WriteMakefile_arg_strs test_files exe_files) }

sub mvp_aliases {
    +{
        WriteMakefile_arg => 'WriteMakefile_arg_strs',
        test_file => 'test_files',
        exe_file => 'exe_files',
    }
}

has MakeFile_PL_template => (
    is            => 'ro',
    isa           => Stringlike,
    coerce        => 1,
    lazy          => 1,
    builder       => '_build_MakeFile_PL_template',
    documentation => "The Text::Template used to construct the ExtUtils::MakeMaker Makefile.PL",
);

sub _build_MakeFile_PL_template {
    my ($self) = @_;

    my $template = <<'TEMPLATE';
# This Makefile.PL for {{ $dist->name }} was generated by
# {{ ref $plugin }} {{ $plugin->VERSION || '<self>' }}
# and Dist::Zilla::Plugin::MakeMaker::Awesome {{ Dist::Zilla::Plugin::MakeMaker::Awesome->VERSION }}.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

{{ $perl_prereq ? qq[use $perl_prereq;] : ''; }}

use ExtUtils::MakeMaker{{ defined $eumm_version ? ' ' . $eumm_version : '' }};

{{ $share_dir_block[0] }}

my {{ $WriteMakefileArgs }}
{{
    @$extra_args ? "%WriteMakefileArgs = (\n"
        . join('', map { "    " . $_ . ",\n" } '%WriteMakefileArgs', @$extra_args)
        . ");\n"
    : '';
}}
my {{ $fallback_prereqs }}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{{ $share_dir_block[1] }}

TEMPLATE

  return $template;
}

has WriteMakefile_arg_strs => (
    is => 'ro', isa => ArrayRef[Str],
    traits => ['Array'],
    lazy => 1,
    default => sub { [] },
    documentation => "Additional arguments passed to ExtUtils::MakeMaker's WriteMakefile()",
);

has WriteMakefile_args => (
    isa           => HashRef,
    traits        => ['Hash'],
    handles       => {
        WriteMakefile_args => 'elements',
        delete_WriteMakefile_arg => 'delete',
    },
    lazy          => 1,
    builder       => '_build_WriteMakefile_args',
    documentation => "The arguments passed to ExtUtils::MakeMaker's WriteMakefile()",
);

sub _build_WriteMakefile_args {
    my ($self) = @_;

    (my $name = $self->zilla->name) =~ s/-/::/g;
    my $test_files = $self->test_files;

    my $prereqs = $self->zilla->prereqs;
    my $perl_prereq = $prereqs->requirements_for(qw(runtime requires))
    ->as_string_hash->{perl};

    $perl_prereq = version->parse($perl_prereq)->numify if $perl_prereq;

    my $prereqs_dump = sub {
        $prereqs->requirements_for(@_)
        ->clone
        ->clear_requirement('perl')
        ->as_string_hash;
    };

    my $build_prereq = $prereqs_dump->(qw(build requires));
    my $test_prereq = $prereqs_dump->(qw(test requires));

    my %WriteMakefile = (
        DISTNAME  => $self->zilla->name,
        NAME      => $name,
        AUTHOR    => $self->zilla->authors->join(q{, }),
        ABSTRACT  => $self->zilla->abstract,
        VERSION   => $self->zilla->version,
        LICENSE   => $self->zilla->license->meta_yml_name,
        EXE_FILES => $self->exe_files,

        CONFIGURE_REQUIRES => $prereqs_dump->(qw(configure requires)),
        keys %$build_prereq ? ( BUILD_REQUIRES => $build_prereq ) : (),
        keys %$test_prereq ? ( TEST_REQUIRES => $test_prereq ) : (),
        PREREQ_PM          => $prereqs_dump->(qw(runtime   requires)),

        test => { TESTS => join q{ }, sort @$test_files },

        $perl_prereq ? ( MIN_PERL_VERSION => $perl_prereq ) : (),
    );

    return \%WriteMakefile;
}


has WriteMakefile_dump => (
    is            => 'ro',
    isa           => Stringlike,
    coerce        => 1,
    lazy          => 1,
    builder       => '_build_WriteMakefile_dump',
    documentation => "A Data::Dumper Str for using WriteMakefile_args used by MakeFile_PL_template"
);

sub _build_WriteMakefile_dump {
    my ($self) = @_;
    # Get arguments for WriteMakefile
    my %write_makefile_args = $self->WriteMakefile_args;

    return $self->_dump_as(\%write_makefile_args, '*WriteMakefileArgs');
}

has test_files => (
    is            => 'ro',
    isa           => ArrayRef[Str],
    lazy          => 1,
    builder       => '_build_test_files',
    documentation => "The glob paths given to the C<< test => { TESTS => ... } >> parameter for ExtUtils::MakeMaker's WriteMakefile() (in munged form)",
);

sub _build_test_files {
    my ($self) = @_;

    my %test_files;
    for my $file ($self->zilla->files->flatten) {
        next unless $file->name =~ m{\At/.+\.t\z};
        (my $pattern = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

        $test_files{$pattern} = 1;
    }

    return [ keys %test_files ];
}

has exe_files => (
    is            => 'ro',
    isa           => ArrayRef[Str],
    lazy          => 1,
    builder       => '_build_exe_files',
    documentation => "The test directories given to ExtUtils::MakeMaker's EXE_FILES (in munged form)",
);

sub _build_exe_files {
    my ($self) = @_;

    my @exe_files =
        $self->zilla->find_files(':ExecFiles')->map(sub { $_->name })->flatten;

    return \@exe_files;
}

has share_dir_block => (
    is            => 'ro',
    isa           => ArrayRef[Str],
    auto_deref    => 1,
    lazy          => 1,
    builder       => '_build_share_dir_block',
    documentation => "The share dir block used in `MakeFile_PL_template'",
);

sub _build_share_dir_block {
    my ($self) = @_;

    my @share_dir_block = (q{}, q{});

    my $share_dir_map = $self->zilla->_share_dir_map;
    if ( keys %$share_dir_map ) {
        # split in two to foil CPANTS prereq_matches_use
        my $preamble = qq{use File::Shar}.qq{eDir::Install;\n};
        if ( my $dist_share_dir = $share_dir_map->{dist} ) {
            $dist_share_dir = quotemeta $dist_share_dir;
            $preamble .= qq{install_share dist => "$dist_share_dir";\n};
        }

        if ( my $mod_map = $share_dir_map->{module} ) {
            for my $mod ( keys %$mod_map ) {
                my $mod_share_dir = quotemeta $mod_map->{$mod};
                $preamble .= qq{install_share module => "$mod", "$mod_share_dir";\n};
            }
        }
        @share_dir_block = (
            $preamble,
            qq{\{\npackage\nMY;\nuse File::ShareDir::Install qw(postamble);\n\}\n},

        );
    }

    return \@share_dir_block;
}

sub register_prereqs {
    my ($self) = @_;

    $self->zilla->register_prereqs(
        { phase => 'configure' },
        'ExtUtils::MakeMaker' => $self->eumm_version || 0,
    );

    return unless keys %{ $self->zilla->_share_dir_map };

    $self->zilla->register_prereqs(
        { phase => 'configure' },
        'File::ShareDir::Install' => 0.03,
    );

    return {};
}

sub setup_installer {
    my $self = shift;

    ## Sanity checks
    $self->log_fatal("can't install files with whitespace in their names")
        if grep { /\s/ } @{$self->exe_files};

    my $perl_prereq = $self->delete_WriteMakefile_arg('MIN_PERL_VERSION');

    my $content = $self->fill_in_string(
        $self->MakeFile_PL_template,
        {
            dist              => \($self->zilla),
            plugin            => \$self,
            eumm_version      => \($self->eumm_version),
            perl_prereq       => \$perl_prereq,
            share_dir_block   => [ $self->share_dir_block ],
            fallback_prereqs  => \($self->fallback_prereq_pm),
            WriteMakefileArgs => \($self->WriteMakefile_dump),
            extra_args        => \($self->WriteMakefile_arg_strs),
        },
    );

    my $file = Dist::Zilla::File::InMemory->new({
        name    => 'Makefile.PL',
        content => $content,
    });

    $self->add_file($file);
    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::Awesome - A more awesome MakeMaker plugin for L<Dist::Zilla>

=head1 VERSION

version 0.22

=head1 SYNOPSIS

In your F<dist.ini>:

    [MakeMaker::Awesome]
    WriteMakefile_arg = CCFLAGS => `pkg-config --cflags libpng`
    WriteMakefile_arg = LIBS => [ `pkg-config --libs libpng` ]

or:

    ;; Replace [MakeMaker]
    ;[MakeMaker]
    [=inc::MyMakeMaker]

=head1 DESCRIPTION

L<Dist::Zilla>'s L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> plugin is
limited, if you want to stray from the marked path and do something
that would normally be done in a C<package MY> section or otherwise
run custom code in your F<Makefile.PL> you're out of luck.

This plugin is 100% compatible with L<Dist::Zilla::Plugin::MakeMaker> -- we
add additional customization hooks by subclassing it.

=head1 CONFIGURATION OPTIONS

Many features can be accessed directly via F<dist.ini>, by setting options.
For options where you expect a multi-line string to be inserted into
F<Makefile.PL>, use the config option more than once, setting each line
separately.

=head2 WriteMakefile_arg

A string, which evaluates to an even-numbered list, which will be included in the call to
C<WriteMakefile>.  Any code is legal that can be inserted into a list of other
key-value pairs, for example:

    [MakeMaker::Awesome]
    WriteMakefile_arg = ( $^O eq 'solaris' ? ( CCFLAGS => '-Wall' ) : ())

Can be used more than once.

=for stopwords DynamicPrereqs

Note: you (intentionally) cannot use this mechanism for specifying dynamic
prerequisites, as previous occurrences of a top-level key will be overwritten
(additionally, you cannot set the fallback prereqs from here). You should take
a look at L<[DynamicPrereqs]|Dist::Zilla::Plugin::DynamicPrereqs> for this.

=head2 test_file

A glob path given to the C<< test => { TESTS => ... } >> parameter for
L<ExtUtils::MakeMaker/WriteMakefile>. Can be used more than once.
Defaults to F<.t> files under F<t/>.  B<NOT> a directory name, despite the name.

=head2 exe_file

The file given to the C<EXE_FILES> parameter for
L<ExtUtils::MakeMaker/WriteMakefile>. Can be used more than once.
Defaults to using data from C<:ExecDir> plugins.

=head1 SUBCLASSING

You can further customize the content of F<Makefile.PL> by subclassing this plugin,
L<Dist::Zilla::Plugin::MakeMaker::Awesome>.

As an example, adding a C<package MY> section to your
F<Makefile.PL>:

In your F<dist.ini>:

    [=inc::MyDistMakeMaker / MyDistMakeMaker]

Then in your F<inc/MyDistMakeMaker.pm>, real example from L<Hailo>
(which has C<[=inc::HailoMakeMaker / HailoMakeMaker]> in its
F<dist.ini>):

    package inc::HailoMakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_MakeFile_PL_template => sub {
        my ($self) = @_;
        my $template = super();

        $template .= <<'TEMPLATE';
    package MY;

    sub test {
        my $inherited = shift->SUPER::test(@_);

        # Run tests with Moose and Mouse
        $inherited =~ s/^test_dynamic :: pure_all\n\t(.*?)\n/test_dynamic :: pure_all\n\tANY_MOOSE=Mouse $1\n\tANY_MOOSE=Moose $1\n/m;

        return $inherited;
    }
    TEMPLATE

        return $template;
    };

    __PACKAGE__->meta->make_immutable;

=for stopwords distro

Or maybe you're writing an XS distro and want to pass custom arguments
to C<WriteMakefile()>, here's an example of adding a C<LIBS> argument
in L<re::engine::PCRE> (note that you can also achieve this without
subclassing, by passing the L</WriteMakefile_arg> option):

    package inc::PCREMakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_WriteMakefile_args => sub { +{
        # Add LIBS => to WriteMakefile() args
        %{ super() },
        LIBS => [ '-lpcre' ],
    } };

    __PACKAGE__->meta->make_immutable;

And another example from L<re::engine::Plan9>, which determines the arguments
dynamically at build time:

    package inc::Plan9MakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_WriteMakefile_args => sub {
        my ($self) = @_;

        our @DIR = qw(libutf libfmt libregexp);
        our @OBJ = map { s/\.c$/.o/; $_ }
                   grep { ! /test/ }
                   glob "lib*/*.c";

        return +{
            %{ super() },
            DIR           => [ @DIR ],
            INC           => join(' ', map { "-I$_" } @DIR),

            # This used to be '-shared lib*/*.o' but that doesn't work on Win32
            LDDLFLAGS     => "-shared @OBJ",
        };
    };

    __PACKAGE__->meta->make_immutable;

If you have custom code in your L<ExtUtils::MakeMaker>-based
F<Makefile.PL> that L<Dist::Zilla> can't replace via its default
facilities you'll be able to replace it by using this module.

Even if your F<Makefile.PL> isn't L<ExtUtils::MakeMaker>-based you
should be able to override it. You'll just have to provide a new
L</"_build_MakeFile_PL_template">.

=for stopwords overridable

=head2 OVERRIDABLE METHODS

These are the methods you can currently C<override> or method-modify in your
custom F<inc/> module. The work that this module does is entirely done in
small modular methods that can be overridden in your subclass. Here are
some of the highlights:

=for Pod::Coverage mvp_multivalue_args mvp_aliases

=head3 _build_MakeFile_PL_template

Returns a L<Text::Template> string used to construct the F<Makefile.PL>.

If you need to insert some additional code to the beginning or end of
F<Makefile.PL> (without modifying the existing content, you should use an
C<around> method modifier, something like this:

    around _build_MakeFile_PL_template => sub {
        my $orig = shift;
        my $self = shift;

        my $NEW_CONTENT = ...;

        # insert new content near the beginning of the file, preserving the
        # preamble header
        my $string = $self->$orig(@_);
        $string =~ m/use warnings;\n\n/g;
        return substr($string, 0, pos($string)) . $NEW_CONTENT . substr($string, pos($string));
    };

=head3 _build_WriteMakefile_args

A C<HashRef> of arguments that will be passed to
L<ExtUtils::MakeMaker>'s C<WriteMakefile> function.

=head3 _build_WriteMakefile_dump

Takes the return value of L</"_build_WriteMakefile_args"> and
constructs a L<Str> that will be included in the F<Makefile.PL> by
L</"_build_MakeFile_PL_template">.

=head3 _build_test_files

The glob paths given to the C<< test => { TESTS => ... } >> parameter for
L<ExtUtils::MakeMaker/WriteMakefile>.  Defaults to F<.t> files under F<t/>.
B<NOT> directories, despite the name.

=head3 _build_exe_files

The files given to the C<EXE_FILES> parameter for
L<ExtUtils::MakeMaker/WriteMakefile>.
Defaults to using data from C<:ExecDir> plugins.

=head3 register_prereqs

=head3 setup_installer

=for stopwords dirs

The test/bin/share dirs and exe_files. These will all be passed to
F</"_build_WriteMakefile_args"> later.

=head3 _build_share_dir_block

=for stopwords sharedir

An C<ArrayRef[Str]> with two elements to be used by
L</"_build_MakeFile_PL_template">. The first will declare your
L<sharedir|File::ShareDir::Install> and the second will add a magic
C<package MY> section to install it. Deep magic.

=head2 OTHER

The main entry point is C<setup_installer> via the
L<Dist::Zilla::Role::InstallTool> role. There are also other magic
Dist::Zilla roles, check the source for more info.

=head1 DIAGNOSTICS

=over

=item attempt to add F<Makefile.PL> multiple times

This error from L<Dist::Zilla> means that you've used both
C<[MakeMaker]> and C<[MakeMaker::Awesome]>. You've either included
C<MakeMaker> directly in F<dist.ini>, or you have plugin bundle that
includes it. See L<@Filter|Dist::Zilla::PluginBundle::Filter> for how
to filter it out.

=back

=head1 BUGS

=for stopwords INI

This plugin would suck less if L<Dist::Zilla> didn't use a INI-based
config system so you could add a stuff like this in your main
configuration file like you can with L<Module::Install>.

The F<.ini> file format can only support key-value pairs whereas any
complex use of L<ExtUtils::MakeMaker> requires running custom Perl
code and passing complex data structures to C<WriteMakefile>.

=head1 AUTHOR

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ævar Arnfjörð Bjarmason.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=over 4

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Robin Smidsrød <robin@smidsrod.no>

=item *

Vladimir Timofeev <vovkasm@gmail.com>

=back

=cut
