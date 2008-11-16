package OpenGL::Tools;
use strict;
use Imager;

use vars '$VERSION';
$VERSION = '0.02';
use OpenGL qw(:all);
use OpenGL::SimpleNames;

sub load_image {
    my ($file) = @_;
    warn "Loading image '$file'";

    my ($width,$height);
    my $pixels;
    my $img = Imager->new();
    $img->open( file => $file)
      or die $img->errstr;
    #warn $img->getchannels;
    #$img->to_rgb8;
    $img->write( data => \$pixels, type => 'raw' );
    return $pixels;
}

sub load_texture {
    my ($file) = @_;
    my ($id) = glGenTextures_p(1);
    warn "Generating texture #$id";

    my ($width,$height);
    my $pixels;
    if ($file =~ /\.tga$/i) {
        open my $fh, "<", $file
            or die "Couldn't read '$file': $!";
        seek $fh, 0, 32;
        $width = 512;
        $height = 512;
    } else {
        my $img = Imager->new();
        $img->open( file => $file)
          or die $img->errstr;
        my $tex;
        if ($img->getwidth != 512) {
            $tex = $img->scale( ypixels => 256 )->crop( width => 256, height => 256 );
        } else {
        #    $tex = $img->scale( ypixels => 512 )->crop( width => 512, height => 512 );
            $tex = $img;
        }
        $width = $tex->getwidth;
        $height = $tex->getheight;
        $tex = $tex->to_rgb8;
        $tex->write( data => \$pixels, type => 'raw' );
        #$pixels = $tex->getsamples( y => 0 );
    };
    glBindTexture(GL_TEXTURE_2D, $id);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    _glTexImage2D( pixels => $pixels, format => GL_RGB, internalformat => 3, width => $width, height => $height );

    return $id
};

sub load_alpha_texture {
    my ($file) = @_;
    my ($id) = glGenTextures_p(1);
    warn "Generating (alpha) texture #$id";

    my ($width,$height);
    my $pixels;
    my $img = Imager->new();
    $img->open( file => $file)
      or die $img->errstr;
    my $tex;
    if ($img->getwidth != 512) {
        #warn "Rescaling $file";
        $tex = $img->scale( ypixels => 256 )->crop( width => 256, height => 256 );
    } else {
    #    $tex = $img->scale( ypixels => 512 )->crop( width => 512, height => 512 );
        $tex = $img;
    }
    $width = $tex->getwidth;
    $height = $tex->getheight;
    #$pixels = join "", map { $tex->getsamples( y => $_, type => '8bit' ) } 0..$height;
    #$pixels = join "", map { map { chr $_ } $tex->getsamples( y => $_, type => '8bit' ) } 0..$height-1;
    $pixels = join "", map { scalar $tex->getsamples( y => $_, type => '8bit' ) } 0..$height-1;
    #$pixels = join "", "\xff\0\x7f\xBF\0\0\0\0" x ($width * $height / 2);
    
    glBindTexture(GL_TEXTURE_2D, $id);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    _glTexImage2D( pixels => $pixels, format => GL_RGBA, internalformat => 4, width => $width, height => $height );

    warn "Stored in $id";

    return $id
};

sub _glTexImage2D {
    my (%args) = @_;
    glTexImage2D_s(GL_TEXTURE_2D, 0, $args{internalformat}, $args{width}, $args{height}, 0, $args{format}, GL_UNSIGNED_BYTE, $args{pixels});
};

sub set_texture_pixels {
    my (%args) = @_;
    glBindTexture(GL_TEXTURE_2D, $args{texture});
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    _glTexImage2D(
        pixels => $args{pixels},
        format => GL_RGB,
        bits => 8,
        internalformat => $args{depth},
        width => $args{width}, height => $args{height}
    );
};

1;