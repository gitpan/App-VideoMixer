package OpenGL::SimpleNames;
use strict;
use vars qw($VERSION %names);

$VERSION = '0.02';

%names = (
    f => [qw(glTranslate glMaterial glRotate glLightModel glPixelStore glTexParameter glLight glScale)],
    _p => [qw(glGenTextures)],
    _c => [qw(glTexImage2D)],
);

sub import {
    my $target = caller();
    no strict 'refs';
    for my $suffix (sort keys %names) {
        for my $name (@{ $names{ $suffix }}) {
            my $glFunc = $name.$suffix;
            *{"$target\::$name"} = \&{"$target\::$glFunc"};
        };
    };
};

1;