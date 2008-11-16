use strict;
use Test::More;

my @packages = (qw(
    App::VideoMixer
    Config::PCF
    OpenGL::SimpleNames
    OpenGL::Tools
));

plan tests => 0+@packages;

for my $p (@packages) {
    use_ok $p;
};
