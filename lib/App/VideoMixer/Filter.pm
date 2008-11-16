package App::VideoMixer::Filter;
use strict;
use OpenGL(':all');
use OpenGL::Shader;
use Config::PCF;
use base 'Class::Accessor';

use vars '$VERSION';
$VERSION = '0.02';

__PACKAGE__->mk_accessors(qw(shader fbo texture_target texture_id renderbuffer_id

    width height

    config

));

sub load_shader {
    my $filename = shift;
    my $c = Config::PCF->parse_file($filename);
    #warn sprintf "Compiling %s (%s)", $filename, $c->{language};
    my $s = OpenGL::Shader->new(uc $c->{language} || 'GLSL');
    my $err = $s->Load($c->{fragment},$c->{vertex});
    if ($err
        and $err !~ /shader was successfully compiled to run/ # ATI
    ) {
        die <<ERROR
!!! Error loading >$filename<

Fragment:
$c->{fragment}

Vertex:
$c->{vertex}

$err
ERROR
    };
    return $s,$c
};

use vars qw($framebuffer_ids);
$framebuffer_ids = 1;

sub new {
    my ($package, %args) = @_;
    my $shader;
    my $config = {};
    if (! exists $args{shader}) {
        ($shader,$config) = load_shader( delete $args{filename});
    } else {
        $shader = delete $args{shader};
    };

    my $width = delete $args{width};
    my $height = delete $args{height};
    my ($fbo,$texture_id,$render_buffer) = $package->allocate_fbo_texture($width,$height);

    # Make fbo the render target
    $package->check_fbo_status($fbo);

    my $self = $package->SUPER::new({
        shader => $shader,
        fbo => $fbo,
        texture_id => $texture_id,
        width => $width,
        height => $height,
        renderbuffer_id => $render_buffer,
        config => $config,
        %args
    });

    if ($config->{setup}) {
        $config->{setup}->($self);
    };

    $self
};

sub enable {
    my $self = shift;

    glPushAttrib(GL_VIEWPORT_BIT);
    glViewport(0,0,$self->width, $self->height);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, $self->fbo);

    my $res = $self->shader->Enable();

    if ($self->config->{enable}) {
        $self->config->{enable}->($self);
    };
};

sub disable {
    my $self = shift;
    $self->shader->Disable();

    if ($self->config->{disable}) {
        $self->config->{disable}->($self);
    };

    glPopAttrib();

    # Restore old render target
    # (maybe this should not be done and left to the application, but that'd be unperlish)
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
};

sub apply {
    my ($self,$render) = @_;
    $self->enable();
    $render->();
    $self->disable();
};

# FBO Status handler
sub check_fbo_status {
  my ($self) = @_;
  my $stat = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
  if (!$stat || $stat == GL_FRAMEBUFFER_COMPLETE_EXT) {return;};
  die( sprintf "FBO status: %04X\n", $stat);
}

sub set_value {
    my ($self,$name,$value) = @_;
    my $err = $self->shader->SetVector($name,$value);
    warn "$err ($name)" if $err;
    $err
};

sub texture_unit {
    my ($self,$name,$unit) = @_;
    my $sh = $self->shader;
    my $location = $sh->Map($name);
    die "Could not get location for '$name'" unless defined $location;
    #warn $name;
    OpenGL::glUniform1iARB($location,$unit);
};

sub DESTROY {
    my ($self) = shift;
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    glDeleteRenderbuffersEXT_p($self->renderbuffer_id);
    glDeleteFramebuffersEXT_p($self->fbo);
    glDeleteTextures_p($self->texture_id);
};

sub allocate_fbo_texture{
    my ($class,$width,$height) = @_;
    (my $texture_id) = glGenTextures_p(1);
    (my $fbo) = glGenFramebuffersEXT_p(1);
    (my $render_buffer) = glGenRenderbuffersEXT_p(1);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, $fbo);
    glBindTexture(GL_TEXTURE_2D, $texture_id);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, $render_buffer);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D_c(GL_TEXTURE_2D,0,GL_RGBA8,$width,$height,0,GL_RGBA,GL_UNSIGNED_BYTE,0);

    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, $texture_id, 0);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, $width,$height);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, $render_buffer);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    return ($fbo,$texture_id, $render_buffer);
};

1;