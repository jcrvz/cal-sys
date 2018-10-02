#!/bin/sh

echo 'Launcher was launched!'
echo '---------------------------------------------'
/usr/bin/python ~/rolac_v3.py &
echo '---> Measurement script is running as ' $!
/usr/bin/octave-cli ~/quickplot_v5.m &
echo '---> Plot script is running as ' $! 
echo '---------------------------------------------'
