#!/bin/bash

cd syn/

timestamp=$(date +"%Y%m%d-%H%M%S")

dc_shell -f ../scripts/synth_earth_top.tcl | tee dc-${timestamp}.log
