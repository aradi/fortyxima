#!/bin/bash
DRIVER=fxudriver.F90
rm -f $DRIVER
../tools/fxunit/fxunit_gendriver *.F90 -n tests -o $DRIVER
