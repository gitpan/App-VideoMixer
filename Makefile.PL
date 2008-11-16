#!/usr/bin/perl -w
use strict;
use inc::Module::Install;

# Define metadata
name           'App-VideoMixer';
all_from       'lib/App/VideoMixer.pm';
license 'Perl';
  
# Specific dependencies
requires       'parent'          => '0.221';
requires       'Class::Accessor' => '0';
requires       'OpenGL'         =>  '0.56';
requires	   'OpenGL::Shader' =>  '1.01';

# ppm Imager to install under Strawberry Perl
requires       'Imager'         => '0.60';

if (! -f "bin\\ffmpeg.exe") {
    requires_external_bin('ffmpeg');
};

no_index       'directory'   => 'bin';
no_index       'directory'   => 'filters';
  
WriteAll;




