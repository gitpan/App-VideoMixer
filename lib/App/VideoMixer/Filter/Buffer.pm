package App::VideoMixer::Filter::Buffer;
use strict;
use OpenGL qw(:all);
use OpenGL::SimpleNames;
use OpenGL::Tools;
use parent 'App::VideoMixer::Filter';

use vars '$VERSION';
$VERSION = '0.02';

__PACKAGE__->mk_accessors(qw(input_texture queue len));

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(filename => 'filters/identity.glsl', @_);
    (my $output_texture) = glGenTextures_p(1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D_c(GL_TEXTURE_2D,0,GL_RGBA8,$self->width,$self->height,0,GL_RGBA,GL_UNSIGNED_BYTE,0);

    $self->input_texture( $self->texture_id );
    $self->texture_id( $output_texture );

    if (! $self->queue) {
        $self->queue([]);
    };

    $self
};

sub disable {
    my ($self) = @_;
    my $q = $self->queue;

    # save current frame from input fbo
    #glBindTexture(GL_TEXTURE_2D, $input_texture); #$self->input_texture);
    my $curr_input; glReadPixels_s(0,0,$self->width,$self->height,GL_RGBA,GL_UNSIGNED_BYTE,$curr_input);
    push @$q, $curr_input;

    # upload next frame into result texture
    my $frame = $q->[0];

    glBindTexture(GL_TEXTURE_2D, $self->texture_id);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    OpenGL::Tools::_glTexImage2D( pixels => $frame, format => GL_RGBA, bits => 8, internalformat => 4, width => $self->width, height => $self->height );

    shift @$q
        while (@$q > $self->len);
};

package App::VideoMixer::Filter::JitterBuffer;
use strict;
use OpenGL qw(:all);
use OpenGL::SimpleNames;
use OpenGL::Tools;

use parent -norequire => 'App::VideoMixer::Filter::Buffer';

sub disable {
    my ($self) = shift;
    my $q = $self->queue;

    # save current frame from input fbo
    #glBindTexture(GL_TEXTURE_2D, $self->input_texture);
    my $curr_input; glReadPixels_s(0,0,$self->width,$self->height,GL_RGB,GL_UNSIGNED_BYTE,$curr_input);
    push @$q, $curr_input;

    # upload next frame into result texture
    my $frame = $q->[rand @$q];

    glBindTexture(GL_TEXTURE_2D, $self->texture_id);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    OpenGL::Tools::_glTexImage2D( pixels => $frame, format => GL_RGB, bits => 8, internalformat => 4, width => $self->width, height => $self->height );

    shift @$q
        while (@$q > $self->len);
};

1;
