package OpenGL::Font;
use strict;
use Carp qw(croak);
use OpenGL;
use Win32::API;
use List::MoreUtils qw(uniq);
use parent 'Class::Accessor';

use vars '$VERSION';
$VERSION = '0.02';

# Build up our Win32 routines
for my $routine (
    [ CreateFont => ['gdi32', 'CreateFontA', 'NNNNNNNNNNNNNP', 'N']],
    [ SelectObject => ['gdi32', 'SelectObject', 'NN', 'N']],
    [ GetDC => ['user32', 'GetDC', ['N'], 'N']],
    [ FindWindow => ['user32', 'FindWindowA', 'PP', 'N']],
    [ wglUseFontOutlines => ['opengl32', 'wglUseFontOutlinesA', 'NNNNFFNP','N']],
) {
    my ($name,$args) = @$routine;
    my $api = Win32::API->new(@$args)
        or die "Win32::API Couldn't bind '$name' to @$args";
    no strict 'refs';
    *{ __PACKAGE__ . "::$name" } = sub {
        #warn $name;
        $api->Call(@_);
    };
};

__PACKAGE__->mk_accessors(qw(name chars handle base));

=head2 C<< new NAME [, CHARS] >>

Loads the font C<NAME> and creates the display lists
for the given characters. If none are given,
a display list for C< 32..127 > is created.

The list of characters can be passed either
as a character string or an array reference of integers.

=cut

sub new {
    my ($class,$name,$chars,$hwnd) = @_;
    croak "More than four parameters passed in. Did you pass the character list as an array?"
        if (@_ > 4);

    $chars ||= [ 0..127 ];

    if (! ref $chars) {
        $chars = [ sort { $a <=> $b } uniq map {ord} split //, $chars ];
    };

    # Should create a hash mapping the ord to the appropriate
    # number here

    my $base = OpenGL::glGenLists( scalar @$chars );
    my $self = {
        name  => $name,
        chars => $chars,
        handle => undef,
        base  => $base,
        fontinfo => undef,
    };
    bless $self => $class;

    $self->handle( $self->build_font($name,$chars,$hwnd) );

    $self;
};

sub build_font {
    my ($self,$name,$chars,$hwnd) = @_;
    
    my $hDC = GetDC($hwnd)
        or die "Couldn't get device context: $^E";

    my $handle = CreateFont(-12, 0,0,0,700,0,0,0,0,4,0,4,0,$name)
        or die "Couldn't create font '$name': $^E";
    SelectObject( $hDC, $handle )
        or die $^E;
    my $buffer = "\0" x (64 * @$chars);
    my $charcount = @$chars;
    wglUseFontOutlines($hDC,0,$charcount,$self->base,0.0,0.2,1,$buffer)
        or die $^E;

    $self->{fontinfo} = $buffer;

    $handle;
};

sub DESTROY {
    glDeleteLists($_[0]->base,scalar @{$_[0]->chars});
};

=head2 C<< $font->draw_string STRING >>

Draws the string from the display lists.
Set textures etc. before calling this.

=cut

sub draw_string {
    my ($self,$str) = @_;
    glPushAttrib(GL_LIST_BIT);
    glListBase($self->base);
    # Convert $str to a packed list of byte-offsets
    # into our lists
    #my @items = map {ord} split //,$str;
    #glCallLists(scalar @items, GL_UNSIGNED_BYTE, $str);
    glCallLists(length $str, GL_UNSIGNED_BYTE, $str);
    #glPopAttrib(GL_LIST_BIT);
    glPopAttrib();
};


1;