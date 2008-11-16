#!/usr/bin/perl -w
use strict;
use lib 'lib';
use App::VideoMixer;

my $app = App::VideoMixer->new();

my $base = '\\\\aliens\\corion\\backup\\Photos\\';
my $movie = $base . '20080405 - Frankfurt,U-bahn,Römer\\CIMG1387.AVI';

$app->add_source( $movie );
$app->set_output( filename => 'test.mpg', width => 640, height => 480);
$app->run();