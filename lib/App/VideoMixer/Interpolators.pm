package App::VideoMixer::Interpolators;
$VERSION = '0.02';

package App::VideoMixer::SawToothInterpolator;
use strict;
use Time::HiRes;
use parent 'Class::Accessor';
__PACKAGE__->mk_accessors(qw( interval scale offset starttime ));

sub new {
  my ($package,$interval,$scale,$offset,$starttime) = @_;
  $starttime ||= Time::HiRes::time;
  $scale ||= 1;
  $offset ||= 0;
  my $self = {
    interval  => $interval,
    starttime => $starttime,
    scale     => $scale,
    offset    => $offset,
  };
  bless $self,$package;
  $self;
};

sub value {
  my ($self,$now) = @_;
  $now ||= Time::HiRes::time;
  my $pos = ($now - $self->starttime) / $self->interval;
  $self->offset + ($pos - int $pos) * $self->scale;
};

package App::VideoMixer::PingPongInterpolator;
use strict;
use parent 'Class::Accessor';
__PACKAGE__->mk_accessors(qw( sawtooth interval scale offset starttime ));

sub new {
  my ($class,$interval,$scale,$offset,$starttime) = @_;
  my $self = {
    sawtooth => App::VideoMixer::SawToothInterpolator->new($interval,1,0,$starttime),
    offset => ($offset || 0),
    scale  => ($scale || 1),    
  };
  bless $self,$class;
  $self;
};

sub value {
  my ($self,$now) = @_;
  
  my $pos = $self->sawtooth->value($now);
  $pos = ($pos - int $pos) * 2;
  $pos = 2 - $pos
    if ($pos > 1);
  $self->offset + $pos*$self->scale;
};

1;