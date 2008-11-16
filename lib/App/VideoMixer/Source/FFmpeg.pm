package App::VideoMixer::External::FFmpeg;
use strict;

use vars qw($VERSION);
$VERSION = '0.02';

use parent 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(width height depth pid stream texture_id file pixel_format ffmpeg));

sub spawn {
    my ($self,$cmd) = @_;
    my $pid = open my $stream, $cmd
        or die "Couldn't spawn '$cmd': $!/$?";
    binmode $stream;
    return ($pid,$stream)
};

sub DESTROY {
    if (my $pid = $_[0]->pid) {
        kill 9, $pid
    };
};

package App::VideoMixer::Source::FFmpeg;
use strict;
use OpenGL qw(:all);
use OpenGL::SimpleNames;
use OpenGL::Tools;
use parent -norequire => 'App::VideoMixer::External::FFmpeg';
use IPC::Open3 qw(open3);

use vars qw($VERSION);
$VERSION = '0.02';

sub stream_info {
    my ($self,$filename) = @_;
    my ($child_in, $stream, $info);
    my $cmd = sprintf qq{%s -t 0 -i "%s" -},
        $self->ffmpeg,
        $filename;
    my $pid = open3 $child_in, $stream, $stream, $cmd
        or die "Couldn't spawn '$cmd': $!/$?";

    while (my $line = <$stream>) {
        #print ">>$line";
        if ($line =~ /Video: .*/) {
            chomp $line;
            #print ">$line<\n";
            my ($width,$height) = $line =~ /(\d+)x(\d+)/;
            return ($width,$height);
        };
    };
};

sub new {
    my ($class,%args) = @_;
    my $file = delete $args{filename};
    die "No file: '$file'"
        unless -f $file;

    my $depth = 3;

    my $self = $class->SUPER::new({
        depth => $depth,
        stream => undef,
        pid => undef,
        loop => 1,
        file => $file,
        pixel_format => 'rgb24',
        ffmpeg => 'bin\\ffmpeg.exe',
        %args,
    });
    my ($width,$height) = $self->stream_info($file);
    $self->width($width);
    $self->height($height);
    my $pixel_format = $self->pixel_format;
    $self->rewind(sprintf qq{%s -i "%s" -f rawvideo -pix_fmt %s - |}, $self->ffmpeg, $file, $pixel_format);
    $self
};

sub rewind {
    my ($self) = @_;
    my $file = $self->file;
    my $pixel_format = $self->pixel_format;
    my ($pid,$stream) = $self->spawn(sprintf qq{%s -i "%s" -f rawvideo -pix_fmt %s - |},
        $self->ffmpeg, $file, $pixel_format
    );
    $self->pid($pid);
    $self->stream($stream);
    1;
};

sub tick {
    my ($self) = @_;

    my $texture_id = $self->texture_id;
    if (! $texture_id) {
        ($texture_id) = glGenTextures_p(1);
        $self->texture_id($texture_id);
    };

    my $frame;
    my $retries = 3;
    while ($retries-- and ! read $self->stream, $frame, $self->width * $self->height * $self->depth) {
        $self->rewind();
    };
    if (! $frame) {
        die "Read failure: $!";
    };
    OpenGL::Tools::set_texture_pixels(
        texture => $texture_id,
        pixels => $frame,
        width => $self->width,
        height => $self->height,
        depth => $self->depth
    );

    $texture_id
};

package App::VideoMixer::Target::FFmpeg;
use strict;
use OpenGL qw(:all);
use OpenGL::SimpleNames;
use OpenGL::Tools;
use parent -norequire => 'App::VideoMixer::External::FFmpeg';

use vars qw($VERSION);
$VERSION = '0.02';

sub new {
    my ($class,%args) = @_;
    my $file = delete $args{filename};
    my $width = delete $args{width} || 352;
    my $height = delete $args{height} || 288;
    my $in_width = delete $args{in_width} || $width;
    my $in_height = delete $args{in_height} || $height;
    my $pixel_format = delete $args{pixel_format} || 'rgb42';
    $args{ffmpeg} ||= "bin\\ffmpeg";

    my $depth = 3;

    my ($pid,$stream) = $class->spawn(sprintf qq{| %s -y -f rawvideo -pix_fmt %s -s ${in_width}x${in_height} -i "-" -f mpeg2video -s ${width}x${height} "$file"},
        $args{ffmpeg}, $pixel_format
    );
    my $self = $class->SUPER::new({
        width => $width,
        height => $height,
        depth => $depth,
        stream => $stream,
        pid => $pid,
        pixel_format => $pixel_format,
        %args,
    });

    $self
};

sub tick {
    my ($self,$texture_id) = @_;

    # Should we scale in the GPU instead of CPU/ffmpeg?
    # Then, a texture-copy would be in order here...

    # save current frame from input fbo
    glBindTexture(GL_TEXTURE_2D, $texture_id);
    #glReadPixels_s(0,0,$self->width,$self->height,GL_RGB,GL_UNSIGNED_BYTE,my $frame);
    my $frame;
    for my $i (reverse (0..$self->height-1)) {
        glReadPixels_s(0,$i,$self->width,1,GL_RGB,GL_UNSIGNED_BYTE,my $line);
        $frame .= $line;
    };
    syswrite $self->stream, $frame, $self->width * $self->height * $self->depth
        or die "Write failure";

    # and claim the current texture id were ours
    $texture_id
};

1;
