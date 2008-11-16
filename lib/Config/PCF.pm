package Config::PCF;
use strict;
use vars qw(%decoder);
use Carp qw(croak);

use vars '$VERSION';
$VERSION = '0.02';

=head1 NAME

Config::PCF - Perl Config Format

=head1 SYNOPSIS

  use Config::PCF;
  use Data::Dumper;

  my $config = Config::PCF->parse_scalar(<<CONFIG);
  %% #information
  This is a perlish config file.

  %% &date
  # This gets interpolated into an anonymous subroutine
      use POSIX qw(strftime);
      return strftime('%Y%m%d', localtime);

  %% $template
  [%# a plain scalar #%]
  Created on [% date %]

  %% %defaults
  foo: bar
  baz: glonk

  CONFIG

  print Dumper $config;

  __END__
  # Output:

=cut

=head2 C<< parse_file FILENAME >>

Reads in a file.

Returns a hash reference to the sections.

=cut

sub parse_file {
    my ($class,$fn) = @_;
    open my $fh, "<", $fn
        or croak "Couldn't read '$fn': $!";
    return $class->parse_scalar( do {local $/; \<$fh>});
};

sub code_fragment {
    my ($frag,$ns) = @_;
    my $s = sprintf <<'EOL',$ns,$frag;
package %s;
sub { %s }
EOL
    eval $s or die "$s\n---\n$@";
};

%decoder = (
    '@' => sub { [map { s/\s+$//g; $_ } split /\n/, $_[0]] },
    '&' => sub { goto &code_fragment; },
    '!' => sub { code_fragment($_[0],$_[1])->($_[2]) },
    '$' => sub { my $res = $_[0]; chomp $res; $res },
    '%' => sub { +{ map { s/\s+$//g; $_ } map { split /:/, $_, 2 } grep { /:/ } split /\n/, $_[0] }},
    '#' => sub { },
);

=head2 C<< Config::PCF->parse_scalar SCALAR >>

Parses the configuration information from a scalar.

Returns a hash reference to the sections.

=cut

sub parse_scalar {
    my $class = shift;
    my $level = 0;
    my $ns = $class;
    while ($ns eq $class or $ns eq __PACKAGE__) {
        ($ns) = (caller($level++));
    };
    my @items = grep /\S/, split /^%% /m, ${$_[0]};
    my %res = map { /^\s*(#?)([\#\%\&\$\@\!])(\w+)\s+(.*)$/sm or croak ">>$_<<";
                    my ($c,$k,$n,$r) = ($1,$2,$3,$4);
                    if (! $c) {
                        my @el = ($n => $decoder{$k}->($r,$ns,$n));
                        @el == 2
                            ? @el
                            : ();
                    } else { () };
                  } @items;
    return \%res;
};

=head1 CONFIGURATION SYNTAX

The configuration syntax is simple:

Every section is indicated by two leading percent signs:

  %% $template
  ...
  %% @urls
  ...
  %% #@old_urls
  ...

The name of every section is prefixed by a sigil. The sigils
have the following meanings:

=over 4

=item * C<$> - scalar

Turns the section into a plain scalar

  %% $template
  Your search gave the following results:

  [% FOR r IN results %]
  * [% r.description %] - [% r.url %]
  [% END %]

  Thanks and come again.

becomes

  {
      template = 'Your search gave the following results:

  [% FOR r IN results %]
  * [% r.description %] - [% r.url %]
  [% END %]

  Thanks and come again.',
  }

=item * C<@> - list

All lines will be chomped and turned into an array reference. Thus

  %% @search_engines
  http://google.com/q=%s
  http://search.yahoo.com/search?p=%s

becomes

  { search_engines => [
      'http://google.com/q=%s',
      'http://search.yahoo.com/search?p=%s',
      ]
  }

=item * C<%> - hash

A simple, flat list of colon-separated items
will be turned into a hash reference:

  %% %homepages
  Corion: http://corion.net
  Perl: http://perl.org

becomes

  { homepages => {
      Corion => 'http://corion.net',
      Perl   => 'http://perl.org',
      }
  }

=item * C<&> - anonymous subroutine

The given Perl code gets interpolated
into an anonymous subroutine.

  %% &timestamp
    use POSIX;
    return strftime '%Y%m%d', localtime

becomes

  { timestamp => sub {
      use POSIX;
      return strftime '%Y%m%d', localtime
    }
  }

=item * C<!> - immediate execution

Like the anonymous subroutine, the code
gets interpolated into a code block. That
code block gets executed immediately
getting the section name as parameter.

Whatever the code block returns will
be put in the config slot.

  %% !debug
  print "I am here.";

  return [
      'http://google.com',
  ];

=item * C<#> - comment

A comment section will not show up
in the configuration hash. If you
want a comment section that shows
up, just use a scalar section.

  %% #information
  This is some comment.

=back

=head1 FURTHER ENHANCEMENTS

Here are some syntax enhancements
that might be useful some day
but which I haven't felt the
need to implement yet:

=over 4

=item * C<< <> >> - include file

This would include a file as a whole,
pulling in the sections of that file,
possibly overwriting sections in
the current file.

The following would first load all
default configurations, then
overwrite parts of them with custom
configurations:

  %% <default/*.pcf>
  %% <custom/*.pcf>

=item * C<< < >> - read section from file

This would read the value of a specific
section from a file (or, maybe even weirder,
in L<IO::All>-style, from anywhere, opening
up big security holes).

  %% $template <root/index.tt

This would read the value for the C<template>
entry in the configuration from the file
C<root/index.tt>.

Whether that idea is better than doing
this in your program remains up to
debate.

By L<IO::All>-style I mean allowing
processes or URLs to be specified as well:

  %% $slashdot <http://rss.slashdot.org/Slashdot/slashdot

But the utility of that is even more limited as you'll likely
be writing your own reader/parser and thus could just
use the list of URLs and fetch them yourself, preferrably
with some caching anyway.

=item * C<< << >> - append to section from file

This will append to the section from a file.

  %% @urls
  http://google.com
  http://search.yahoo.com
  %% @urls <<pending-urls.lst
  %% @urls <<new-urls.lst

=back

=cut

1;