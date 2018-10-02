#!/bin/sh

echo 'Launcher was launched!'
echo '---------------------------------------------'
/usr/bin/python ~/rolac.py &
echo '---> Measurement script is running as ' $!
/usr/bin/octave-cli ~/quickplot.m &
echo '---> Plot script is running as ' $! 
echo '---------------------------------------------'
