package App::VideoMixer;
use strict;
use parent 'Class::Accessor';

=head1 NAME

App::VideoMixer - a simple video mixer using OpenGL

=head1 SYNOPSIS

	#!/usr/bin/perl -w
	use strict;
	use App::VideoMixer;

	my $app = App::VideoMixer->new();

	my $base = 'videos/;
	my $movie = $base . 'camel.avi';

	$app->add_source( $movie );
	$app->set_output( filename => 'camel2.mpg', width => 640, height => 480);
	$app->run();

=head1 DESCRIPTION

This module implements a small application that allows you to display
video and to manipulate the video using GLSL filters.

=cut

use vars qw'$VERSION';
$VERSION = '0.02';

use OpenGL qw(:all);
use OpenGL::SimpleNames;
use Time::HiRes 'time';

use OpenGL::Tools;

use App::VideoMixer::Interpolators;
use App::VideoMixer::Filter;
use App::VideoMixer::Filter::Buffer;
use App::VideoMixer::Source::FFmpeg;

__PACKAGE__->mk_accessors(qw(
    window 
    filters filterlist filter_active
    ffmpeg sources
    write_output
    output_writer
    font
    keymap   
));

sub gl(&) {
    glPushMatrix;
    $_[0]->();
    glPopMatrix;
};

sub gl_compile (&) {
    my ($scene) = glGenLists(1);
    glLoadIdentity;

    glNewList($scene,GL_COMPILE);
    $_[0]->();
    glEndList();
    $scene
};

=head1 METHODS

=head2 C<< ->new >>

Creates a new video mixer instance, complete with window
and keybindings. To start playing a video, see the C<< ->run() >>
method.

=cut

sub new {
    my ($class,%args) = @_;
    my $self = {
        window  => { width => 800, height => 600 },
        filters => {},
        filterlist => [],
        filter_active => {},
        ffmpeg    => $args{ffmpeg},
        sources       => [],
        output_writer => undef,
        write_output  => undef,
        keymap        => {},
        
        font => undef,
        
        %args,
    };
    
    bless $self, $class;
};

sub disp {
  my ($self) = @_;
  
  glCullFace(GL_FRONT);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();

  $self->render_scene();

  glFlush;
  glutSwapBuffers();
};

sub add_source {
    my ($self,$movie) = @_;
    my $video_source = App::VideoMixer::Source::FFmpeg->new( filename => $movie );
    push @{ $self->sources }, $video_source;    
};

sub set_output {
    my ($self,%args) = @_;
    $self->output_writer( App::VideoMixer::Target::FFmpeg->new( %args ));
};

sub texture_quad {
    glBegin(GL_QUADS);
            glTexCoord2f(0,0); glVertex3f( splice @_, 0, 3 );
            glTexCoord2f(0,1); glVertex3f( splice @_, 0, 3 );
            glTexCoord2f(1,1); glVertex3f( splice @_, 0, 3 );
            glTexCoord2f(1,0); glVertex3f( splice @_, 0, 3 );
    glEnd;
}

sub render_scene {
    my ($self) = @_;
    my $source_texture = $self->sources->[0]->tick();

    glEnable( GL_COLOR_MATERIAL );
    glColor4f(1.0,1.0,1.0,1.0);

    glMatrixMode (GL_MODELVIEW); glPushMatrix (); glLoadIdentity (); glMatrixMode (GL_PROJECTION); glPushMatrix (); glLoadIdentity ();

    for my $filter (@{ $self->filterlist }) {
        next unless $self->filter_active->{ $filter };
        # first, render the frame into the filter's buffer:
        glActiveTextureARB(GL_TEXTURE0_ARB);
        glEnable(GL_TEXTURE_2D);
        glBindTexture( GL_TEXTURE_2D, $source_texture);
        $self->filters->{ $filter }->texture_unit(Source => 0);

        $self->filters->{ $filter }->enable($source_texture);

        my $ofs = time;
        $ofs = $ofs - int $ofs;

        texture_quad(
                      -1,  1, -1,
                      -1, -1, -1,
                       1, -1, -1,
                       1,  1, -1,
        );

        $self->filters->{ $filter }->disable;
        $source_texture = $self->filters->{ $filter }->texture_id;
    };

    glMatrixMode(GL_MODELVIEW);
    glViewport(0, 0, $self->window->{width}, $self->window->{height});

    #warn "Drawing buffer $source_texture";
    glActiveTextureARB(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, $source_texture);
    texture_quad(
                  -1,  1, -1,
                  -1, -1, -1,
                   1, -1, -1,
                   1,  1, -1,
    );

    glDisable( GL_TEXTURE_2D );

    glTranslate(-2,0,-1);
    glColor4f(1.0,1.0,0.5,1.0);
    #$self->font->draw_string(' Perl');

    glPopMatrix (); glMatrixMode (GL_MODELVIEW); glPopMatrix ();

    if ($self->write_output) {
        $self->output_writer->tick($source_texture);
    };
};

sub key {
  my $self = shift;
  my $key = pack "c", shift;

  if (exists $self->keymap->{$key}) {
    $self->keymap->{$key}->($self,@_);
    glutPostRedisplay;
  } else {
    print "Unknown key: $key\n";
  };
};

=head2 C<< ->tick >>

Called whenever the next video frame can be rendered

=cut

sub tick {
    my ($self) = @_;
	glutPostRedisplay;
	my $now = time();
	if ($now > $self->{last}) {
		$self->{last} = $now;
		$self->{frames} = 0;
	};
	$self->{frames}++;
};

sub resize_window {
    my ($self,$w,$h) = @_;
	(@{ $self->window}{qw(width height)}) = ($w,$h);
	$self->window->{height}++
	    unless $self->window->{height};

	my $ratio = $self->window->{width} / $self->window->{height};

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity;
	gluPerspective(45,$ratio,0.1,200);

	glMatrixMode(GL_MODELVIEW);
	glViewport(0, 0, $self->window->{width}, $self->window->{height});
};

sub init_gl {
    my ($self) = @_;

	glutInit();
	glutInitDisplayMode(GLUT_DEPTH | GLUT_DOUBLE | GLUT_RGBA);

	glutInitWindowSize($self->window->{width}, $self->window->{height});

	$self->window->{main} = glutCreateWindow($0);
	
    if ($^O =~ /MSWin32/) {
	    require OpenGL::Font;
		my ($hwnd) = grep { OpenGL::Font::FindWindow($_,$0) }
					 qw(GLUT FREEGLUT)
			or die "Couldn't find window handle for '$0'";
		$self->{font} = OpenGL::Font->new('Arial Black',undef,$hwnd);
	};

	warn "System info: GL_VERSION " . glGetString(GL_VERSION);
};

sub init_filters {
    my ($self,@list) = @_;
    
    if (! @list) {
        @list = qw(
            identity greentint sobel  scanlines halftone metaimage warhol posterize
        );
    };

	my $i = 1;
	for (qw(App::VideoMixer::Filter::Buffer App::VideoMixer::Filter::JitterBuffer)) {
		$self->filters->{ $_ } = $_->new( len => 10, width => 640, height => 480 );
		push @{$self->filterlist}, $_;
		print $i++, " $_\n";
	};

	for (@list) {
		$self->filters->{ $_ } = App::VideoMixer::Filter->new( filename => "filters/$_.glsl", width => 640, height => 640 );
		push @{ $self->filterlist }, $_;
		print $i++, " $_\n";
	};

	for (1..@{ $self->filterlist }) {
		my $i = $_;
		$self->keymap->{ $i } = sub { $_[0]->filter_active->{ $_[0]->filterlist->[$i]} ^= 1 };
	};
};

sub bind_glut {
    my ($self) = @_;

    my $keymap = $self->keymap;
    
    $keymap->{ chr(27) } = sub { exit };
    $keymap->{ chr(32) } = sub { $_[0]->{write_output} ^= 1; print "Writing output: " . $_[0]->write_output };
    
	glutDisplayFunc(sub {  $self->disp });
	glutKeyboardFunc(sub { $self->key(@_) });
	glutReshapeFunc(sub {  $self->resize_window(@_) });
	glutIdleFunc(sub { $self->tick });
};

=head2 C<< ->run >>

Starts the GLUT playback loop. This will
loop until you press C<ESC>.

=cut

sub run {
    my ($self) = @_;

    $self->init_gl;
    $self->bind_glut;

    # ->>init_gl
	# Set up shading model
	glShadeModel(GL_SMOOTH);

	# Set up clear color
	glClearColor(0.0,0.0,0.0,1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	# enable blending for the cross-fade
	glEnable(GL_BLEND);

    $self->init_filters;
    
    $self->{last} = time;
    
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glutMainLoop();
};

'Version für $foo Magazin.de';

__END__

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 LICENSE

This module is released under the same terms as Perl itself.