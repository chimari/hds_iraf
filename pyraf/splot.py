#!/usr/bin/env python
import sys
import os
from pyraf import iraf


if len(sys.argv) != 2:
  print(" [usage] python3 splot.py spectrum_file")
  sys.exit()

  
inimage    = sys.argv[1]

iraf.gaoes()

#inid = sys.argv[1]
iraf.set(stdimage="imt4096")
iraf.splot(inimage, 1)

    
