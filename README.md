This repository contains the MATLAB code required to reproduce the results in the paper: 

## [Least Squares Normalized Cross Correlation](https://arxiv.org/abs/1810.04320)

To run, call:

    startup();
    run_all(RESULTS_DIR);

Requirements:

 - A C++ compiler set up (`mex -setup C++`). The script automatically compiles necessary C++ code.
 - An internet connection. The script automatically downloads the required data.
 - Ghostscipt should be installed. The script automatically generates PDFs of the graphs in the paper.
 - MATLAB should be callable from the system command line, without the full path (e.g. by calling matlab or matlab.exe). This allows tasks to be parallelized across all available cores.

Latest runtime: A complete run through all experiments using an 8-core Apple M1 Pro CPU and 
MATLAB R2025b took 12 hours.

### Copyright notice

Copyright Snap Inc. 2020

This sample code is made available by Snap Inc. for informational
purposes only.  It is provided as-is, without warranty of any kind,
express or implied, including any warranties of merchantability, fitness
for a particular purpose, or non-infringement.  In no event will Snap
Inc. be liable for any damages arising from the sample code or your use
thereof.
